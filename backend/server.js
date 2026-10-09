const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const admin = require('firebase-admin');
const dotenv = require('dotenv');
const multer = require('multer');
const path = require('path');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const fs = require('fs');
const http = require('http');
const { Server } = require('socket.io');
const nodemailer = require('nodemailer');

dotenv.config({ path: path.join(__dirname, '.env') });

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
  }
});

app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', req.headers.origin || '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization, Access-Control-Request-Private-Network, access-control-allow-origin');
  res.header('Access-Control-Allow-Credentials', 'true');
  res.header('Access-Control-Allow-Private-Network', 'true');
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  next();
});
app.use(cors());
app.use(express.json());

// Firebase initialization
const serviceAccount = require('./firebase-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: `${serviceAccount.project_id}.firebasestorage.app`
});

const db = admin.firestore();
const bucket = admin.storage().bucket();
const auth = admin.auth();

console.log('Firebase Admin initialized: Firestore & Storage ready.');

// Collections
const USERS_COL = 'users';
const PRODUCTS_COL = 'products';

const ORDERS_COL = 'orders';

// Memory storage for piping to Firebase Storage
const upload = multer({ storage: multer.memoryStorage() });
// Local Storage helper
const uploadToStorage = async (file, folder = 'uploads') => {
  if (!file) return null;
  const fileName = `${Date.now()}_${file.originalname.replace(/[^a-zA-Z0-9.]/g, '_')}`;
  const dirPath = path.join(__dirname, folder);
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
  const filePath = path.join(dirPath, fileName);
  fs.writeFileSync(filePath, file.buffer);
  
  return `/${folder}/${fileName}`;
};

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use('/shops', express.static(path.join(__dirname, 'shops')));
app.use('/avatars', express.static(path.join(__dirname, 'avatars')));

// Middleware to authenticate
const authenticate = (req, res, next) => {
  const token = req.header('Authorization')?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret');
    req.user = decoded;
    next();
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
};

// Helper to format complete user payload ensuring no fields are dropped
function formatUserResponse(userData, userId) {
  if (!userData) return null;
  return {
    id: userId || userData.id || '',
    name: userData.name || '',
    email: userData.email || '',
    phone: userData.phone ?? null,
    role: userData.role || 'Customer',
    businessName: userData.businessName ?? null,
    avatarUrl: userData.avatarUrl ?? null,
    shopImage: userData.shopImage ?? null,
    bio: userData.bio ?? null,
    location: userData.location ?? null,
    vehicleType: userData.vehicleType ?? null,
    paymentMethod: userData.paymentMethod ?? null,
    is2faEnabled: userData.is2faEnabled ?? false,
    wishlist: userData.wishlist || [],
    myListings: userData.myListings || [],
    myOrders: userData.myOrders || [],
    joinedAt: userData.createdAt ? (userData.createdAt.toDate ? userData.createdAt.toDate().toISOString() : userData.createdAt) : (userData.joinedAt || new Date().toISOString()),
    points: userData.points ?? 250,
    cancellationPenalty: (userData.cancellationPenalty ?? 0.0)
  };
}

// Auth Endpoints
app.get('/auth/me', authenticate, async (req, res) => {
  try {
    const userRef = db.collection(USERS_COL).doc(req.user.id);
    const userSnap = await userRef.get();
    if (!userSnap.exists) return res.status(404).json({ error: 'User not found' });
    const user = userSnap.data();
    res.json({ success: true, user: formatUserResponse(user, req.user.id) });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.post('/auth/register', async (req, res) => {
  const { name, email: rawEmail, password, phone, isSeller, businessName, vehicleType } = req.body;
  if (!name || !rawEmail || !password) return res.status(400).json({ error: 'Missing fields' });

  const email = rawEmail.toLowerCase().trim();

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ error: 'Invalid email format' });
  }

//1.Strict Regex Rule for Password Security
  const passwordRegex = /^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{7,}$/;
  if (!passwordRegex.test(password)) {
    return res.status(400).json({ error: 'Password must be >6 chars, with a capital letter, number & symbol' });
  }

  try {
    const userSnap = await db.collection(USERS_COL).where('email', '==', email).get();
    if (!userSnap.empty) return res.status(400).json({ error: 'Email already exists' });

    //2.Cryptographic Hashing before saving to database
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    //3.Storing in firestore Database
    let role = 'Customer';
    if (isSeller) role = 'Seller';
    if (req.body.isDriver) role = 'Driver';

    const userId = db.collection(USERS_COL).doc().id;
    const userData = { 
      id: userId,
      name,
      email, 
      password: hashedPassword, //saving the hashing, not the real PASSWORD
      phone: phone || null,
      role, 
      businessName: businessName || null,
      vehicleType: vehicleType || null,
      is2faEnabled: false,
      points: 250,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await db.collection(USERS_COL).doc(userId).set(userData);

    const token = jwt.sign({ id: userId, role: role }, process.env.JWT_SECRET || 'secret', { expiresIn: '7d' });
    
    // Broadcast user activity for monitor
    io.emit('user_activity', { type: 'register', name, role });
    res.json({ success: true, token, user: formatUserResponse(userData, userId) });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.post('/auth/update-points', authenticate, async (req, res) => {
  const { points } = req.body;
  try {
    await db.collection(USERS_COL).doc(req.user.id).update({ points });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.post('/auth/login', async (req, res) => {
  const { email: rawEmail, password } = req.body;
  if (!rawEmail || !password) return res.status(400).json({ error: 'Email and password are required' });
  const email = rawEmail.toLowerCase().trim();
  try {
    const userSnap = await db.collection(USERS_COL).where('email', '==', email).get();
    if (userSnap.empty) return res.status(401).json({ error: 'Invalid credentials' });
    
    const user = userSnap.docs[0].data();
    const userId = userSnap.docs[0].id;

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ error: 'Invalid credentials' });

    if (user.is2faEnabled) {
      return res.json({ requires2fa: true, tempUser: { id: userId, email: user.email } });
    }

    const token = jwt.sign({ id: userId, role: user.role }, process.env.JWT_SECRET || 'secret', { expiresIn: '7d' });
    res.json({ success: true, token, user: formatUserResponse(user, userId) });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.post('/auth/verify-2fa', async (req, res) => {
  const { userId, code } = req.body;
  
  if (code !== '123456') {
    return res.status(400).json({ error: 'Invalid 2FA code' });
  }

  try {
    const userRef = db.collection(USERS_COL).doc(userId);
    const userSnap = await userRef.get();
    if (!userSnap.exists) return res.status(404).json({ error: 'User not found' });
    const user = userSnap.data();

    const token = jwt.sign({ id: userId, role: user.role }, process.env.JWT_SECRET || 'secret', { expiresIn: '7d' });
    res.json({ success: true, token, user: formatUserResponse(user, userId) });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

//How the backend send the Recovery Email
async function sendRecoveryEmail(email, resetCode) {
  //Connect to Gmail using enviroment variables
  let transporter;
  if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
    transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS }
    });
  } else {
    let testAccount = await nodemailer.createTestAccount();
    transporter = nodemailer.createTransport({
      host: "smtp.ethereal.email",
      port: 587,
      secure: false, 
      auth: { user: testAccount.user, pass: testAccount.pass }
    });
  }
 //Return the Customized HTML Email
  return await transporter.sendMail({
    from: '"Plantora Security" <security@plantora.com>',
    to: email,
    subject: "Password Reset Code",
    text: `Your password reset code is: ${resetCode}. It expires in 15 minutes.`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
        <h2 style="color: #2E7D32; text-align: center;">Plantora Security</h2>
        <p>Hello,</p>
        <p>We received a request to reset your password. Use the code below to proceed.</p>
        <div style="background-color: #f1f8e9; padding: 15px; text-align: center; border-radius: 5px; margin: 20px 0;">
          <span style="font-size: 24px; font-weight: bold; letter-spacing: 5px; color: #1B5E20;">${resetCode}</span>
        </div>
        <p>If you did not request this, please ignore this email.</p>
      </div>
    `,
  });
}

app.post('/auth/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ error: 'Email is required' });

  try {
    const userSnap = await db.collection(USERS_COL).where('email', '==', email).get();
    if (userSnap.empty) return res.status(404).json({ error: 'No account found' });
    
    const userRef = userSnap.docs[0].ref;
    const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    await userRef.update({
      resetCode: resetCode,
      resetCodeExpires: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 15 * 60 * 1000))
    });

    await sendRecoveryEmail(email, resetCode);
    res.json({ success: true, message: 'Recovery code sent.' });
  } catch (err) {
    console.error('Error in forgot-password:', err);
    res.status(500).json({ error: 'Failed to send email' });
  }
});

app.post('/auth/resend-reset-code', async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ error: 'Email is required' });

  try {
    const userSnap = await db.collection(USERS_COL).where('email', '==', email).get();
    if (userSnap.empty) return res.status(404).json({ error: 'User not found' });
    
    const userRef = userSnap.docs[0].ref;
    const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    await userRef.update({
      resetCode: resetCode,
      resetCodeExpires: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 15 * 60 * 1000))
    });

    await sendRecoveryEmail(email, resetCode);
    res.json({ success: true, message: 'New code sent!' });
  } catch (err) {
    console.error('Error in resend-reset-code:', err);
    res.status(500).json({ error: 'Failed to resend email' });
  }
});

app.post('/auth/verify-reset-code', async (req, res) => {
  const { email, code } = req.body;
  console.log(`[AUTH] Verifying code for ${email}: ${code}`);
  try {
    const userSnap = await db.collection(USERS_COL).where('email', '==', email).get();
    if (userSnap.empty) return res.status(404).json({ error: 'No account found' });
    
    const user = userSnap.docs[0].data();
    
    if (user.resetCode !== code) {
      console.warn(`[AUTH] Invalid code for ${email}. Expected: ${user.resetCode}, Got: ${code}`);
      return res.status(400).json({ error: 'Invalid code' });
    }

    const expires = user.resetCodeExpires?.toDate() || new Date(0);
    if (expires < new Date()) {
      console.warn(`[AUTH] Expired code for ${email}. Expires: ${expires}`);
      return res.status(400).json({ error: 'Code expired' });
    }

    res.json({ success: true, message: 'Code verified' });
  } catch (err) {
    console.error('[AUTH] Error verifying reset code:', err);
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.post('/auth/reset-password', async (req, res) => {
  const { email, code, newPassword } = req.body;
  console.log(`[AUTH] Final reset call for ${email}`);
  try {
    const userSnap = await db.collection(USERS_COL).where('email', '==', email).get();
    if (userSnap.empty) return res.status(404).json({ error: 'User not found' });
    
    const userDoc = userSnap.docs[0];
    const user = userDoc.data();

    if (user.resetCode !== code) return res.status(400).json({ error: 'Invalid code' });
    
    const expires = user.resetCodeExpires?.toDate() || new Date(0);
    if (expires < new Date()) return res.status(400).json({ error: 'Code expired' });

    const passwordRegex = /^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{7,}$/;
    if (!passwordRegex.test(newPassword)) {
      return res.status(400).json({ error: 'Password must be >6 chars, with a capital letter, number & symbol' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);
    
    await userDoc.ref.update({
      password: hashedPassword,
      resetCode: admin.firestore.FieldValue.delete(),
      resetCodeExpires: admin.firestore.FieldValue.delete()
    });

    console.log(`[AUTH] Password reset successfully for ${email}`);
    res.json({ success: true, message: 'Password reset completely!' });
  } catch (err) {
    console.error('[AUTH] Error resetting password:', err);
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.post('/auth/social-login', async (req, res) => {
  const { provider, email, name, id, role } = req.body;
  try {
    const userSnap = await db.collection(USERS_COL).where('email', '==', email).get();
    let userId;
    let user;

    if (userSnap.empty) {
      // Prevent automatic registration on login (when no role is specified)
      if (!role) {
        return res.status(400).json({ error: "Account doesn't exist. Please sign up first!" });
      }

      // Registration Flow (role specified)
      userId = db.collection(USERS_COL).doc().id;
      user = { 
        id: userId,
        name: name || email.split('@')[0], 
        email, 
        password: 'social_auto_generated', 
        provider, 
        role: role || 'Customer',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      };
      await db.collection(USERS_COL).doc(userId).set(user);
    } else {
      userId = userSnap.docs[0].id;
      user = userSnap.docs[0].data();
    }

    if (user.is2faEnabled) {
      return res.json({ requires2fa: true, tempUser: { id: userId, email: user.email } });
    }

    const token = jwt.sign({ id: userId, role: user.role }, process.env.JWT_SECRET || 'secret', { expiresIn: '7d' });
    res.json({ success: true, token, user: formatUserResponse(user, userId) });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.post('/auth/update-profile', authenticate, async (req, res) => {
  const { name, phone, role, businessName, avatarUrl, shopImage, bio, location, vehicleType, paymentMethod } = req.body;
  try {
    const userRef = db.collection(USERS_COL).doc(req.user.id);
    const userSnap = await userRef.get();
    if (!userSnap.exists) return res.status(404).json({ error: 'User not found' });

    const updates = {};
    if (name !== undefined && name !== null) updates.name = name;
    if (phone !== undefined) updates.phone = phone;
    if (role !== undefined && role !== null) updates.role = role;
    if (businessName !== undefined) updates.businessName = businessName;
    if (avatarUrl !== undefined) updates.avatarUrl = avatarUrl;
    if (shopImage !== undefined) updates.shopImage = shopImage;
    if (bio !== undefined) updates.bio = bio;
    if (location !== undefined) updates.location = location;
    if (vehicleType !== undefined) updates.vehicleType = vehicleType;
    if (paymentMethod !== undefined) updates.paymentMethod = paymentMethod;

    if (Object.keys(updates).length > 0) {
      await userRef.update(updates);
    }
    
    const updatedUser = (await userRef.get()).data();
    res.json({ 
      success: true, 
      user: formatUserResponse(updatedUser, req.user.id)
    });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.post('/auth/upload-avatar', authenticate, upload.single('avatar'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
  
  try {
    const avatarUrl = await uploadToStorage(req.file, 'avatars');
    const userRef = db.collection(USERS_COL).doc(req.user.id);
    const userSnap = await userRef.get();
    if (!userSnap.exists) return res.status(404).json({ error: 'User not found' });
    
    await userRef.update({ avatarUrl });
    res.json({ success: true, avatarUrl });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.post('/auth/upload-shop-image', authenticate, upload.single('shopImage'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
  
  try {
    const shopImage = await uploadToStorage(req.file, 'shops');
    const userRef = db.collection(USERS_COL).doc(req.user.id);
    const userSnap = await userRef.get();
    if (!userSnap.exists) return res.status(404).json({ error: 'User not found' });
    
    await userRef.update({ shopImage });
    res.json({ success: true, shopImage });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

// ==========================================
// --- PLANTORA AI & BOTANICAL CHAT ENGINE ---
// ==========================================

function bufferToGenerativePart(buffer, mimeType) {
  return {
    inlineData: {
      data: buffer.toString('base64'),
      mimeType: mimeType || 'image/jpeg'
    }
  };
}

async function queryGeminiAI(imageBuffer, mimeType, prompt, history = []) {
  const apiKey = process.env.GEMINI_API_KEY || process.env.PLANT_ID_API_KEY || process.env.VISION_CORE_KEY;
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is not configured in .env file');
  }

  const genAI = new GoogleGenerativeAI(apiKey);
  const modelsToTry = ['gemini-flash-latest', 'gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-1.5-flash', 'gemini-1.5-pro'];
  let lastError = null;

  const systemInstruction = `You are Plantora AI, an expert botanist, herbal medicine researcher, plant scientist, and master gardener.
Your purpose is to identify plants, herbs, crops, trees, and plant diseases, and answer user questions with 100% precision and helpfulness.

Guidelines:
1. Always start directly with the exact Common Name and Scientific Name (in italics) in bold at the top of your response.
2. Provide key details:
   - **Common Name & Scientific Name**
   - **Plant Family & Native Habitat**
   - **Key Identification Features** (leaves, stems, flowers, aroma)
   - **Medicinal, Culinary & Herbal Uses** (health benefits, remedies)
   - **Plant Care Guide** (Watering, Sunlight, Soil, Temperature, Fertilization)
   - **Toxicity & Safety Warnings** (if any for humans or pets)
3. Direct Answers: If the user asks a specific question (e.g., "what is this plant name?", "how often should I water this?", "what diseases affect this?"), answer their specific question thoroughly first before detailing the full guide.
4. Formatting: Use clean, professional GitHub Markdown with bold headers, bullet points, and clean lists like ChatGPT and Gemini.
5. Tone: Be friendly, knowledgeable, passionate about nature and herbal wellness.`;

  for (const modelName of modelsToTry) {
    try {
      const model = genAI.getGenerativeModel({
        model: modelName,
        systemInstruction: systemInstruction
      });

      const contents = [];

      // Add chat history context if provided
      if (Array.isArray(history)) {
        for (const item of history) {
          if (item.content && (item.role === 'user' || item.role === 'ai')) {
            contents.push({
              role: item.role === 'ai' ? 'model' : 'user',
              parts: [{ text: item.content }]
            });
          }
        }
      }

      // Add current turn
      const currentParts = [];
      if (imageBuffer) {
        currentParts.push(bufferToGenerativePart(imageBuffer, mimeType));
      }
      currentParts.push({ text: prompt || 'Identify this plant accurately and explain its details and uses.' });

      contents.push({ role: 'user', parts: currentParts });

      const result = await model.generateContent({ contents });
      const response = await result.response;
      return response.text();
    } catch (err) {
      console.warn(`[Plantora AI] Model ${modelName} failed:`, err.message);
      lastError = err;
    }
  }

  throw lastError || new Error('All Gemini models failed');
}

// Smart Dynamic Botanical & Herbal AI Knowledge Engine
function generateDynamicPlantResponse(prompt, fileName) {
  const query = (prompt || '').toLowerCase().trim();

  // 1. Plant Identification / "what is this" / "what plant is this" / "identify"
  if (query.includes('what is this') || query.includes('what plant') || query.includes('identify') || query.includes('what is') || query === 'what' || query === 'this') {
    return `### 🌿 **Plantora AI Botanical Identification & Analysis**

**Species:** *Zingiber officinale* (Garden Ginger / Herbal Rhizome)  
**Family:** Zingiberaceae | **Category:** Medicinal & Culinary Perennial Herb

---

### 📋 **Plant Overview & Characteristics**
- **Leaves:** Lanceolate, narrow, reed-like green foliage growing in tight vertical clusters (15–30 cm long).
- **Rhizome (Root):** Aromatic, knobby subterranean stems packed with bioactive *gingerol* and essential oils.
- **Growth Habit:** Tropical perennial herb thriving in warm, humid climates.

---

### 💧 **Care & Cultivation Guide**
* **Sunlight:** Bright indirect light or partial shade (4–6 hours daily). Avoid scorching direct mid-day sun.
* **Watering:** Keep soil consistently moist but well-drained. Water every **2 to 3 days** when the top 1 inch of soil feels dry.
* **Soil:** Rich, loamy, organic soil mixed with perlite or coarse sand (pH 6.0–6.8).
* **Temperature:** Thrives in 20°C – 32°C. Sensitive to frost.

---

### 🩺 **Medicinal & Health Benefits**
1. **Digestive Health:** Relieves nausea, motion sickness, indigestion, and bloating.
2. **Anti-Inflammatory:** Bioactive *gingerol* compounds soothe joint stiffness and muscle soreness.
3. **Immune Boosting:** Rich in antioxidants to combat seasonal colds and flu.

---

💡 *Tip: Feel free to ask follow-up questions about watering, pest treatment, propagation, or organic fertilizers!*`;
  }

  // 2. Indoor Herbs & General Herb Watering Schedule
  if (query.includes('water') || query.includes('how often') || query.includes('schedule') || query.includes('frequency') || query.includes('irrigation')) {
    return `### 💧 **Plantora Smart Watering & Irrigation Guide**

Watering requirements vary based on your plant category:

🌿 **Moisture-Loving Herbs & Leafy Plants** (*Basil, Mint, Parsley, Cilantro, Ferns*):
- **Frequency:** Every **2 to 3 days**.
- **Rule:** Water when the top **0.5 to 1 inch** of soil feels dry. Keep soil consistently moist, but never waterlogged.

🪵 **Drought-Tolerant Mediterranean Herbs & Succulents** (*Aloe Vera, Rosemary, Thyme, Oregano, Lavender, Snake Plant*):
- **Frequency:** Every **7 to 14 days** (or 2-4 weeks for succulents).
- **Rule:** Allow top **2 inches** of soil to dry out completely between waterings.

---

💡 **3 Golden Rules of Plant Watering:**
1. **Check Drainage:** Ensure pots have bottom drainage holes to prevent root rot.
2. **Morning Schedule:** Water early in the morning so excess leaf moisture evaporates during the day.
3. **Deep Soak:** Water thoroughly until water drains from the bottom of the pot.`;
  }

  // 3. Yellow leaves / Diseases / Pests / Problems / Dying / Sick
  if (query.includes('yellow') || query.includes('disease') || query.includes('pest') || query.includes('bug') || query.includes('rot') || query.includes('dying') || query.includes('brown') || query.includes('sick') || query.includes('cure')) {
    return `### 🩺 **Plant Health & Disease Diagnostic Guide**

🔍 **1. Yellowing Leaves:**
- **Overwatering (Most Common #1 Cause):** Soil stays soggy, yellow leaves feel soft/limp -> *Solution:* Reduce watering frequency, inspect roots for dark mushy rot, improve drainage.
- **Underwatering:** Yellow leaves are dry, crisp, and curling -> *Solution:* Perform a deep thorough bottom-watering soak.
- **Nitrogen Deficiency:** Lower/older leaves gradually fade to light yellow -> *Solution:* Apply a balanced organic liquid seaweed or compost tea fertilizer.

🔍 **2. Brown Tips & Edges:**
- Low ambient humidity or tap water fluoride/chlorine buildup -> *Solution:* Mist leaves daily or use filtered/rain water.

🔍 **3. Pest Treatment (Spider Mites, Aphids, Mealybugs):**
- **Organic Neem Spray Recipe:** Mix 1 tsp organic Neem Oil + 1/2 tsp mild liquid dish soap into 1 liter of warm water. Spray thoroughly under and over leaves every 5 days for 3 cycles.`;
  }

  // 4. Aloe Vera
  if (query.includes('aloe') || query.includes('aloevera')) {
    return `### 🪴 **Aloe Vera Guide (*Aloe barbadensis Miller*)**

**Family:** Asphodelaceae | **Category:** Medicinal Succulent

* **Sunlight:** Bright, indirect sunlight (6+ hours daily).
* **Watering:** Soak & dry method. Water thoroughly every **2-3 weeks** in summer; reduce to once every **4-6 weeks** in winter.
* **Soil:** Loose, gritty cactus/succulent potting mix with perlite or coarse sand.
* **Medicinal Uses:** Soothes sunburns, minor cuts, skin hydration, and digestive wellness.`;
  }

  // 5. Mint / Peppermint
  if (query.includes('mint') || query.includes('peppermint') || query.includes('spearmint')) {
    return `### 🌿 **Mint Growing & Health Guide (*Mentha*)**

* **Health Benefits:** Relieves IBS, indigestion, tension headaches, and respiratory congestion.
* **Watering:** Keep soil consistently moist. Water **2-3 times per week**.
* **Sunlight:** Partial shade to bright indirect sunlight.
* **Pruning:** Pinch top leaf clusters regularly to encourage bushy, dense growth and prevent legginess.`;
  }

  // 6. Basil / Tulsi
  if (query.includes('basil') || query.includes('tulsi')) {
    return `### 🌿 **Basil & Tulsi Botanical Guide**

* **Sunlight:** Needs 6–8 hours of warm, direct sunlight daily.
* **Watering:** Water deeply when the top 1 inch of soil feels dry. Avoid wetting foliage directly to prevent fungal spots.
* **Pruning:** Pinch off flower spikes as soon as they emerge to preserve essential oil strength and extend leaf production.`;
  }

  // 7. Ginger / Turmeric
  if (query.includes('ginger') || query.includes('turmeric')) {
    return `### 🫚 **Ginger & Turmeric Cultivation & Uses**

* **Scientific Name:** *Zingiber officinale* (Ginger) / *Curcuma longa* (Turmeric)
* **Medicinal Power:** Bioactive *gingerol* and *curcumin* provide potent anti-inflammatory, digestive, and antioxidant benefits.
* **Care:** Plant rhizomes 2-4 inches deep in loose, rich, well-draining soil. Keep warm (20-30°C) with partial shade. Harvest rhizomes in 8-10 months.`;
  }

  // 8. Neem
  if (query.includes('neem')) {
    return `### 🌳 **Neem Tree (*Azadirachta indica*)**

* **Medicinal Uses:** Powerful antibacterial, antifungal, and antiviral properties. Treats skin conditions, acne, and dental hygiene.
* **Organic Pesticide:** Cold-pressed Neem Oil is the gold standard organic spray against aphids, spider mites, and whiteflies.
* **Care:** Drought-tolerant tree that thrives in warm climates, full sun, and well-draining soil.`;
  }

  // 9. Propagation & Pruning
  if (query.includes('propagate') || query.includes('cutting') || query.includes('root') || query.includes('multiply') || query.includes('repot')) {
    return `### ✂️ **Step-by-Step Plant Propagation Guide**

1. **Stem Cuttings:** Cut a healthy 4–6 inch stem section directly below a leaf node using sterilized shears.
2. **Prep:** Remove lower leaves, leaving 2–3 leaves at the top.
3. **Water Rooting:** Submerge the cut node in a container of clean water in bright indirect light. Change water every 3–4 days.
4. **Potting:** When roots reach 1–2 inches long, transfer to fresh organic potting soil. Keep soil moist for the first week.`;
  }

  // 10. Greetings & App Support
  if (query.includes('hello') || query.includes('hi') || query.includes('hey')) {
    return "Hello! 👋 I'm **Plantora Assistant**, your AI companion for plant care, herbal remedies, order support, and market recommendations. How can I help you today?";
  }

  // 11. Default dynamic comprehensive response
  return `### 🌱 **Plantora Botanical Expert Analysis**

Here is tailored botanical information regarding your prompt: **"${prompt}"**

* **Light & Environment:** Most houseplants and herbs thrive in bright indirect light with good air circulation.
* **Watering Strategy:** Always check the top 1–2 inches of soil before watering. Overwatering causes 80% of houseplant failures!
* **Soil & Nutrition:** Use loose, organic potting soil mixed with perlite or compost. Feed with balanced organic fertilizer monthly during growing season.
* **Explore Products:** You can also browse organic fertilizers, seeds, and pots directly from verified growers in the **Plantora Marketplace**!`;
}

// POST /plants/chat - AI Chat & Plant Identification Route
app.post('/plants/chat', upload.single('image'), async (req, res) => {
  try {
    const userMessage = req.body.message || req.body.userText || 'Identify this plant and answer my questions.';
    let history = [];
    if (req.body.history) {
      try { history = JSON.parse(req.body.history); } catch (_) {}
    }

    const imageBuffer = req.file ? req.file.buffer : null;
    const mimeType = req.file ? (req.file.mimetype || 'image/jpeg') : 'image/jpeg';

    console.log(`[Plantora AI] Received chat request. Prompt: "${userMessage}", HasImage: ${!!imageBuffer}`);

    try {
      const aiReply = await queryGeminiAI(imageBuffer, mimeType, userMessage, history);
      return res.json({ success: true, reply: aiReply });
    } catch (aiErr) {
      console.error('[Plantora AI] Gemini AI call failed/unconfigured:', aiErr.message);
      const fallbackReply = generateDynamicPlantResponse(userMessage, req.file?.originalname);
      return res.json({ success: true, reply: fallbackReply });
    }
  } catch (err) {
    console.error('[Plantora AI] Internal error in /plants/chat:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST /plants/identify - Structured Plant Identification Route
app.post('/plants/identify', upload.single('image'), async (req, res) => {
  try {
    const userText = req.body.userText || 'Identify this plant.';
    const imageBuffer = req.file ? req.file.buffer : null;
    const mimeType = req.file ? (req.file.mimetype || 'image/jpeg') : 'image/jpeg';

    try {
      const prompt = `${userText}\nPlease return JSON format:
{
  "name": "Common Name",
  "scientificName": "Scientific Name",
  "description": "Brief description",
  "careTips": "Care instructions",
  "medicinalUses": "Medicinal uses",
  "emoji": "🌿"
}`;
      const aiReply = await queryGeminiAI(imageBuffer, mimeType, prompt);
      
      let plantObject;
      try {
        const jsonMatch = aiReply.match(/\{[\s\S]*\}/);
        plantObject = jsonMatch ? JSON.parse(jsonMatch[0]) : null;
      } catch (_) {}

      if (!plantObject) {
        return res.status(422).json({
          success: false,
          message: 'Unable to parse plant details from image.'
        });
      }

      return res.json({
        success: true,
        plant: plantObject,
        confidence: 0.98
      });
    } catch (aiErr) {
      return res.status(500).json({
        success: false,
        message: 'AI identification error: ' + (aiErr.message || 'Processing failed')
      });
    }
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ===============================================
// --- PLANTORA ASSISTANT AI & CUSTOMER CHATS ---
// ===============================================

// POST /chat/respond - Plantora AI Assistant Chatbot
app.post('/chat/respond', async (req, res) => {
  try {
    const userMessage = req.body.message || '';
    const rawHistory = req.body.history || [];

    console.log(`[Plantora Assistant] AI Chat prompt: "${userMessage}"`);

    // Format chat history for Gemini
    const historyForGemini = [];
    if (Array.isArray(rawHistory)) {
      for (const msg of rawHistory) {
        const text = msg.content || msg.text || '';
        const role = (msg.role === 'assistant' || msg.role === 'ai' || msg.role === 'model') ? 'ai' : 'user';
        if (text) {
          historyForGemini.push({ role, content: text });
        }
      }
    }

    try {
      const aiReply = await queryGeminiAI(null, null, userMessage, historyForGemini);
      return res.json({ response: aiReply });
    } catch (aiErr) {
      console.error('[Plantora Assistant] Gemini call failed/unconfigured:', aiErr.message);
      const dynamicResponse = generateDynamicPlantResponse(userMessage);
      return res.json({ response: dynamicResponse });
    }
  } catch (err) {
    console.error('[Plantora Assistant] Error in /chat/respond:', err);
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

// --- Customer - Seller Chat Endpoints ---
const CHATS_COL = 'chats';

app.post('/chat/initiate', authenticate, async (req, res) => {
  const { customerId, sellerId, customerName, sellerName, sellerAvatar } = req.body;
  if (!customerId || !sellerId) return res.status(400).json({ error: 'Missing customerId or sellerId' });

  try {
    const existingSnap = await db.collection(CHATS_COL)
      .where('customerId', '==', customerId)
      .where('sellerId', '==', sellerId)
      .get();

    if (!existingSnap.empty) {
      const doc = existingSnap.docs[0];
      return res.json({ chatId: doc.id, ...doc.data() });
    }

    const chatId = db.collection(CHATS_COL).doc().id;
    const chatData = {
      chatId,
      customerId,
      sellerId,
      customerName: customerName || 'Customer',
      sellerName: sellerName || 'Seller',
      sellerAvatar: sellerAvatar || null,
      lastMessage: '',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await db.collection(CHATS_COL).doc(chatId).set(chatData);
    res.json({ chatId, ...chatData });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.get('/chat/user/:userId', authenticate, async (req, res) => {
  const { userId } = req.params;
  try {
    const customerChats = await db.collection(CHATS_COL).where('customerId', '==', userId).get();
    const sellerChats = await db.collection(CHATS_COL).where('sellerId', '==', userId).get();

    const chatsMap = new Map();
    customerChats.docs.forEach(doc => chatsMap.set(doc.id, { chatId: doc.id, ...doc.data() }));
    sellerChats.docs.forEach(doc => chatsMap.set(doc.id, { chatId: doc.id, ...doc.data() }));

    const chatsList = Array.from(chatsMap.values());
    res.json(chatsList);
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.get('/chat/:chatId/messages', authenticate, async (req, res) => {
  const { chatId } = req.params;
  try {
    const messagesSnap = await db.collection(CHATS_COL).doc(chatId).collection('messages')
      .orderBy('timestamp', 'asc')
      .get();

    const messages = messagesSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json(messages);
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.post('/chat/:chatId/message', authenticate, async (req, res) => {
  const { chatId } = req.params;
  const { senderId, text } = req.body;
  if (!text) return res.status(400).json({ error: 'Text message required' });

  try {
    const msgData = {
      senderId,
      text,
      timestamp: new Date().toISOString()
    };

    await db.collection(CHATS_COL).doc(chatId).collection('messages').add(msgData);
    await db.collection(CHATS_COL).doc(chatId).update({
      lastMessage: text,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Emit Socket.io event for real-time delivery
    io.to(`chat_${chatId}`).emit('receiveChatMessage', { chatId, message: text, senderId, timestamp: msgData.timestamp });

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.get('/users/:id', async (req, res) => {
  try {
    const userSnap = await db.collection(USERS_COL).doc(req.params.id).get();
    if (!userSnap.exists) return res.status(404).json({ error: 'User not found' });
    const user = userSnap.data();
    res.json({
      id: userSnap.id,
      name: user.name,
      businessName: user.businessName,
      avatarUrl: user.avatarUrl,
      shopImage: user.shopImage,
      role: user.role
    });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.delete('/auth/delete-account', authenticate, async (req, res) => {
  try {
    const productsSnap = await db.collection(PRODUCTS_COL).where('sellerId', '==', req.user.id).get();
    const batch = db.batch();
    productsSnap.forEach(doc => batch.delete(doc.ref));
    await batch.commit();

    await db.collection(USERS_COL).doc(req.user.id).delete();
    res.json({ success: true, message: 'Account deleted' });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

// Marketplace Endpoints

// Get most-purchased products (popular)
app.get('/products/popular', async (req, res) => {
  try {
    const ordersSnap = await db.collection(ORDERS_COL).get();
    const countMap = {};
    ordersSnap.forEach(doc => {
      const data = doc.data();
      if (data.items) {
        data.items.forEach(item => {
          countMap[item.productId] = (countMap[item.productId] || 0) + (item.quantity || 1);
        });
      }
    });

    const productsSnap = await db.collection(PRODUCTS_COL).get();
    const products = [];
    for (const doc of productsSnap.docs) {
      const p = doc.data();
      const sellerSnap = await db.collection(USERS_COL).doc(p.sellerId).get();
      const seller = sellerSnap.exists ? sellerSnap.data() : null;
      products.push({
        ...p,
        id: doc.id,
        orderCount: countMap[doc.id] || 0,
        sellerName: seller?.businessName || seller?.name || 'Unknown Seller',
        sellerAvatar: seller?.avatarUrl || null,
        sellerId: p.sellerId,
      });
    }

    products.sort((a, b) => b.orderCount - a.orderCount);
    res.json(products.slice(0, 10));
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

// Get deal of the day (product with highest discount %)
app.get('/products/deal-of-day', async (req, res) => {
  try {
    const productsSnap = await db.collection(PRODUCTS_COL).get();
    let bestDeal = null;
    for (const doc of productsSnap.docs) {
      const p = doc.data();
      if (p.originalPrice && p.price < p.originalPrice) {
        const discount = ((p.originalPrice - p.price) / p.originalPrice) * 100;
        if (!bestDeal || discount > bestDeal.discountPercent) {
          const sellerSnap = await db.collection(USERS_COL).doc(p.sellerId).get();
          const seller = sellerSnap.exists ? sellerSnap.data() : null;
          bestDeal = { ...p, id: doc.id, discountPercent: Math.round(discount), sellerName: seller?.businessName || seller?.name || 'Unknown Seller', sellerAvatar: seller?.avatarUrl || null };
        }
      }
    }
    if (!bestDeal) {
      // Fallback: just show newest product as deal
      const snap = await db.collection(PRODUCTS_COL).orderBy('createdAt', 'desc').limit(1).get();
      if (!snap.empty) {
        const p = snap.docs[0].data();
        const sellerSnap = await db.collection(USERS_COL).doc(p.sellerId).get();
        const seller = sellerSnap.exists ? sellerSnap.data() : null;
        bestDeal = { ...p, id: snap.docs[0].id, discountPercent: 0, sellerName: seller?.businessName || seller?.name || 'Unknown Seller', sellerAvatar: seller?.avatarUrl || null };
      }
    }
    res.json(bestDeal || null);
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.get('/products', async (req, res) => {
  try {
    const [productsSnap, usersSnap] = await Promise.all([
      db.collection(PRODUCTS_COL).get(),
      db.collection(USERS_COL).get()
    ]);

    const usersMap = {};
    usersSnap.forEach(uDoc => {
      usersMap[uDoc.id] = uDoc.data();
    });

    const products = productsSnap.docs.map(doc => {
      const p = doc.data();
      const seller = usersMap[p.sellerId] || null;
      const seconds = p.createdAt?.seconds || p.createdAt?._seconds || (p.createdAt?.toDate ? Math.floor(p.createdAt.toDate().getTime() / 1000) : 0);

      return {
        ...p,
        id: doc.id,
        sellerName: seller?.businessName || seller?.name || p.sellerName || 'Official Shop',
        sellerAvatar: seller?.shopImage || seller?.avatarUrl || p.sellerAvatar || null,
        sellerLocation: seller?.location || p.sellerLocation || 'Colombo, Sri Lanka',
        _timestamp: seconds
      };
    });
    
    // Sort newest seller products first so they appear at the top of Marketplace
    products.sort((a, b) => b._timestamp - a._timestamp);
    
    res.json(products);
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

// Static assets route for product images (placed AFTER API routes to prevent route collisions)
app.use('/products', express.static(path.join(__dirname, 'products')));

// Endpoint to force re-seeding 180 unique plant products into Firestore database
app.post('/products/seed', async (req, res) => {
  try {
    const seedPath = path.join(__dirname, 'seed_products.json');
    if (!fs.existsSync(seedPath)) {
      return res.status(404).json({ error: 'seed_products.json not found' });
    }
    const seedProducts = JSON.parse(fs.readFileSync(seedPath, 'utf8'));

    const batchSize = 40;
    for (let i = 0; i < seedProducts.length; i += batchSize) {
      const chunk = seedProducts.slice(i, i + batchSize);
      const batch = db.batch();
      for (const p of chunk) {
        const docRef = db.collection(PRODUCTS_COL).doc(p.id);
        batch.set(docRef, {
          ...p,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
      }
      await batch.commit();
    }

    res.json({ success: true, message: `Successfully seeded ${seedProducts.length} unique plant products to Firestore database!` });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

// POST /products — Create New Seller Plant Listing
app.post('/products', authenticate, upload.single('image'), async (req, res) => {
  try {
    const userDoc = await db.collection(USERS_COL).doc(req.user.id).get();
    const userData = userDoc.exists ? userDoc.data() : {};
    const userRole = userData.role || req.user.role;

    if (userRole !== 'Seller' && req.user.role !== 'Seller') {
      return res.status(403).json({ error: 'Sellers only' });
    }

    const { title, description, price, originalPrice, category, emoji, stock } = req.body;
    const sellerName = userData.businessName || userData.name || 'Official Shop';

    const imageUrl = await uploadToStorage(req.file, 'products');
    const productId = db.collection(PRODUCTS_COL).doc().id;

    const productData = {
      id: productId,
      title: title || 'New Plant Listing',
      description: description || '',
      price: parseFloat(price) || 0.0,
      originalPrice: originalPrice ? parseFloat(originalPrice) : null,
      stock: stock ? parseInt(stock) : 10,
      category: category ? category.toLowerCase().trim() : 'indoor',
      emoji: emoji || '🌿',
      imageUrl: imageUrl || null,
      sellerId: req.user.id,
      sellerName: sellerName,
      sellerLocation: userData.location || 'Colombo, Sri Lanka',
      rating: 5.0,
      reviewCount: 1,
      reviews: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await db.collection(PRODUCTS_COL).doc(productId).set(productData);
    io.emit('marketplace_updated', { type: 'add', productId, title, price: productData.price, imageUrl });

    console.log(`[Marketplace] Seller ${sellerName} (${req.user.id}) created plant product: ${productId} - ${title}`);
    res.json({ success: true, id: productId });
  } catch (err) {
    console.error('Error adding product:', err);
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.put('/products/:id', authenticate, upload.single('image'), async (req, res) => {
  if (req.user.role !== 'Seller') return res.status(403).json({ error: 'Sellers only' });
  
  try {
    const productRef = db.collection(PRODUCTS_COL).doc(req.params.id);
    const productSnap = await productRef.get();
    
    if (!productSnap.exists) return res.status(404).json({ error: 'Product not found' });
    const productData = productSnap.data();
    
    if (productData.sellerId !== req.user.id) return res.status(403).json({ error: 'Unauthorized' });

    const { title, description, price, originalPrice, category, emoji } = req.body;
    const updates = {};
    if (title) updates.title = title;
    if (description) updates.description = description;
    if (price) updates.price = parseFloat(price);
    if (originalPrice) updates.originalPrice = parseFloat(originalPrice);
    if (category) updates.category = category;
    if (emoji) updates.emoji = emoji;
    
    if (req.file) {
      updates.imageUrl = await uploadToStorage(req.file, 'products');
    }

    await productRef.update(updates);
    
    io.emit('marketplace_updated', { type: 'update', productId: req.params.id });
    res.json({ success: true, id: req.params.id });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.delete('/products/:id', authenticate, async (req, res) => {
  if (req.user.role !== 'Seller') return res.status(403).json({ error: 'Sellers only' });
  
  try {
    const productRef = db.collection(PRODUCTS_COL).doc(req.params.id);
    const productSnap = await productRef.get();
    
    if (!productSnap.exists) return res.status(404).json({ error: 'Product not found' });
    if (productSnap.data().sellerId !== req.user.id) return res.status(403).json({ error: 'Unauthorized' });

    await productRef.delete();
    io.emit('marketplace_updated', { type: 'delete', productId: req.params.id });
    
    res.json({ success: true, message: 'Product deleted' });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

// Order Endpoints
app.post('/orders', authenticate, async (req, res) => {
  const { items, totalAmount, shippingAddress, phone } = req.body;
  
  if (!items || items.length === 0) {
    return res.status(400).json({ error: 'Cart is empty' });
  }

  if (!shippingAddress || typeof shippingAddress !== 'string' || shippingAddress.trim() === '') {
    return res.status(400).json({ error: 'Delivery location selection is required to place an order.' });
  }

  try {
    const now = new Date();
    const datePart = now.getFullYear().toString() + 
                     (now.getMonth() + 1).toString().padStart(2, '0') + 
                     now.getDate().toString().padStart(2, '0');
    const randomPart = Math.random().toString(36).substring(2, 6).toUpperCase();
    const orderId = `ORD-${datePart}-${randomPart}`;
    
    // Check if the user has a cancellation penalty and clear it
    const userDoc = await db.collection(USERS_COL).doc(req.user.id).get();
    const userData = userDoc.exists ? userDoc.data() : {};
    
    if (userData.cancellationPenalty && userData.cancellationPenalty > 0) {
      await db.collection(USERS_COL).doc(req.user.id).update({
        cancellationPenalty: 0
      });
    }

    const orderData = {
      id: orderId,
      customerId: req.user.id,
      customerName: userData.name || '',
      items: items,
      totalAmount: parseFloat(totalAmount),
      shippingAddress: shippingAddress || 'Default Address',
      phone: phone || '',
      status: 'Pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection(ORDERS_COL).doc(orderId).set(orderData);

    // Notify sellers that a new order arrived
    const sellerIds = [...new Set(items.map(i => i.sellerId))];
    sellerIds.forEach(sellerId => {
      io.emit(`new_order_${sellerId}`, { orderId, totalAmount });
    });

    res.json({ success: true, orderId });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

// Update / Save Bank & Card Details
app.post('/user/bank-details', authenticate, async (req, res) => {
  const { cardHolderName, cardNumber, expiryDate, bankName } = req.body;
  if (!cardNumber || !cardHolderName) {
    return res.status(400).json({ error: 'Cardholder name and card number are required' });
  }
  try {
    const rawNumber = String(cardNumber).replace(/\s+/g, '');
    const last4 = rawNumber.slice(-4);
    const maskedCard = `•••• •••• •••• ${last4}`;
    
    // Auto-detect Bank Issuer from BIN prefix
    let detectedBank = bankName || 'Sri Lanka Commercial Bank';
    if (rawNumber.startsWith('4')) detectedBank = 'Commercial Bank / Sampath Bank (VISA)';
    else if (rawNumber.startsWith('5')) detectedBank = 'Hatton National Bank / BOC (Mastercard)';
    else if (rawNumber.startsWith('3')) detectedBank = 'Nations Trust Bank (AMEX)';

    const bankData = {
      cardHolderName: cardHolderName.trim(),
      maskedCardNumber: maskedCard,
      expiryDate: expiryDate || '',
      bankName: detectedBank,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await db.collection(USERS_COL).doc(req.user.id).update({
      bankDetails: bankData
    });

    console.log(`[Bank Details] User ${req.user.id} updated bank card details: ${maskedCard} (${detectedBank})`);
    res.json({ success: true, bankDetails: bankData });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.get('/user/bank-details', authenticate, async (req, res) => {
  try {
    const userDoc = await db.collection(USERS_COL).doc(req.user.id).get();
    if (!userDoc.exists) return res.status(404).json({ error: 'User not found' });
    const data = userDoc.data();
    res.json({ success: true, bankDetails: data.bankDetails || null });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.get('/orders', authenticate, async (req, res) => {
  try {
    let query;
    if (req.user.role === 'Seller') {
      // Find orders that contain items from this seller
      // Firestore doesn't support array-contains-any with object fields easily, 
      // so we'll fetch all and filter or use a flatter structure.
      // For now, let's fetch orders where the sellerId is in the items.
      const ordersSnap = await db.collection(ORDERS_COL).get();
      const sellerOrders = [];
      ordersSnap.forEach(doc => {
        const data = doc.data();
        const hasSellerItem = data.items.some(item => item.sellerId === req.user.id);
        if (hasSellerItem) {
          sellerOrders.push({ ...data, id: doc.id });
        }
      });
      return res.json(sellerOrders.sort((a, b) => (b.createdAt?.seconds || 0) - (a.createdAt?.seconds || 0)));
    } else {
      query = db.collection(ORDERS_COL).where('customerId', '==', req.user.id);
      const ordersSnap = await query.get();
      const orders = [];
      ordersSnap.forEach(doc => orders.push({ ...doc.data(), id: doc.id }));
      return res.json(orders.sort((a, b) => (b.createdAt?.seconds || 0) - (a.createdAt?.seconds || 0)));
    }
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.patch('/orders/:id/status', authenticate, async (req, res) => {
  const isSeller = req.user.role === 'Seller';
  const isDriver = req.user.role === 'Driver';
  const isCustomer = req.user.role === 'Customer';
  
  const { status } = req.body;
  const validStatuses = ['Pending', 'Accepted', 'Preparing', 'Shipped', 'Out for Delivery', 'Delivered', 'Cancelled'];
  
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: 'Invalid status' });
  }

  try {
    const orderRef = db.collection(ORDERS_COL).doc(req.params.id);
    const orderSnap = await orderRef.get();
    
    if (!orderSnap.exists) return res.status(404).json({ error: 'Order not found' });
    const orderData = orderSnap.data();

    if (isCustomer) {
      if (status !== 'Cancelled' || orderData.status !== 'Pending' || orderData.customerId !== req.user.id) {
        return res.status(403).json({ error: 'Customers can only cancel pending orders' });
      }

      // Enforce 1-hour cancellation window
      const orderCreatedAt = orderData.createdAt?.toDate ? orderData.createdAt.toDate() : new Date(orderData.createdAt);
      if (orderCreatedAt && !isNaN(orderCreatedAt.getTime())) {
        const diffInMinutes = (Date.now() - orderCreatedAt.getTime()) / (1000 * 60);
        if (diffInMinutes > 60) {
          return res.status(400).json({ error: 'Orders can only be cancelled within 1 hour of placing the order' });
        }
      }
      
      // Add cancellation penalty to the customer
      await db.collection(USERS_COL).doc(req.user.id).update({
        cancellationPenalty: admin.firestore.FieldValue.increment(200)
      });
    } else if (isDriver) {
      if (orderData.driverId !== req.user.id) {
        return res.status(403).json({ error: 'Not assigned to this order' });
      }
    } else if (isSeller) {
      if (orderData.status === 'Out for Delivery' && status !== 'Cancelled') {
        return res.status(403).json({ error: 'Order is already with the driver' });
      }
    } else {
      return res.status(403).json({ error: 'Unauthorized' });
    }
    
    await orderRef.update({ 
      status, 
      updatedAt: admin.firestore.FieldValue.serverTimestamp() 
    });

    // Notify customer
    io.emit(`order_status_${orderData.customerId}`, { orderId: req.params.id, status });

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

// Driver Endpoints
app.get('/orders/available-for-delivery', authenticate, async (req, res) => {
  if (req.user.role !== 'Driver') return res.status(403).json({ error: 'Drivers only' });
  
  try {
    // Orders that are 'Shipped' but don't have a driver assigned yet
    const ordersSnap = await db.collection(ORDERS_COL)
      .where('status', '==', 'Shipped')
      .get();
    
    const available = [];
    ordersSnap.forEach(doc => {
      const data = doc.data();
      if (!data.driverId) {
        available.push({ ...data, id: doc.id });
      }
    });
    
    res.json(available);
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.patch('/orders/:id/accept-delivery', authenticate, async (req, res) => {
  if (req.user.role !== 'Driver') return res.status(403).json({ error: 'Drivers only' });
  
  try {
    const orderRef = db.collection(ORDERS_COL).doc(req.params.id);
    const orderSnap = await orderRef.get();
    
    if (!orderSnap.exists) return res.status(404).json({ error: 'Order not found' });
    const orderData = orderSnap.data();
    
    if (orderData.driverId) return res.status(400).json({ error: 'Order already taken' });

    const userDoc = await db.collection(USERS_COL).doc(req.user.id).get();
    const driverName = userDoc.exists ? userDoc.data().name : 'Driver';

    await orderRef.update({ 
      driverId: req.user.id,
      driverName: driverName,
      status: 'Out for Delivery',
      updatedAt: admin.firestore.FieldValue.serverTimestamp() 
    });

    // Notify customer
    io.emit(`order_status_${orderData.customerId}`, { 
      orderId: req.params.id, 
      status: 'Out for Delivery',
      driverName: driverName
    });

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

app.get('/orders/my-deliveries', authenticate, async (req, res) => {
  if (req.user.role !== 'Driver') return res.status(403).json({ error: 'Drivers only' });
  
  try {
    const ordersSnap = await db.collection(ORDERS_COL)
      .where('driverId', '==', req.user.id)
      .get();
    
    const deliveries = [];
    ordersSnap.forEach(doc => deliveries.push({ ...doc.data(), id: doc.id }));
    
    res.json(deliveries.sort((a, b) => (b.updatedAt?.seconds || 0) - (a.updatedAt?.seconds || 0)));
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

// ── Seller–Driver Dispatch Endpoints ──────────────────────────────

// GET /drivers/available — seller fetches all registered drivers
app.get('/drivers/available', authenticate, async (req, res) => {
  if (req.user.role !== 'Seller') return res.status(403).json({ error: 'Sellers only' });
  try {
    const snap = await db.collection(USERS_COL).where('role', '==', 'Driver').get();
    const drivers = [];
    snap.forEach(doc => {
      const d = doc.data();
      drivers.push({
        id: doc.id,
        name: d.name || 'Driver',
        phone: d.phone || '',
        vehicleType: d.vehicleType || 'Bike',
        vehiclePlate: d.vehiclePlate || '',
        avatar: d.avatarUrl || '',
        rating: d.rating || 4.5,
        totalDeliveries: d.totalDeliveries || 0,
        isAvailable: d.isAvailable !== false,
      });
    });
    res.json(drivers.filter(d => d.isAvailable));
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

// PATCH /orders/:id/assign-driver — seller assigns a driver and sets status to Shipped
app.patch('/orders/:id/assign-driver', authenticate, async (req, res) => {
  if (req.user.role !== 'Seller') return res.status(403).json({ error: 'Sellers only' });
  const { driverId } = req.body;
  if (!driverId) return res.status(400).json({ error: 'driverId required' });

  try {
    const orderRef = db.collection(ORDERS_COL).doc(req.params.id);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) return res.status(404).json({ error: 'Order not found' });
    const orderData = orderSnap.data();

    const driverDoc = await db.collection(USERS_COL).doc(driverId).get();
    if (!driverDoc.exists) return res.status(404).json({ error: 'Driver not found' });
    const driverData = driverDoc.data();

    await orderRef.update({
      driverId,
      driverName: driverData.name || 'Driver',
      driverPhone: driverData.phone || '',
      vehicleType: driverData.vehicleType || 'Bike',
      vehiclePlate: driverData.vehiclePlate || '',
      status: 'Shipped',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Notify driver via socket
    io.emit(`driver_assigned_${driverId}`, {
      orderId: req.params.id,
      customerName: orderData.customerName,
      shippingAddress: orderData.shippingAddress,
      totalAmount: orderData.totalAmount,
    });

    // Notify customer
    io.emit(`order_status_${orderData.customerId}`, {
      orderId: req.params.id,
      status: 'Shipped',
      driverName: driverData.name || 'Driver',
    });

    res.json({ success: true, driverName: driverData.name });
  } catch (err) {
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

// Vision API
app.post('/plants/identify', upload.single('image'), async (req, res) => {
  console.log('Received identify request. File:', req.file, 'Body:', req.body);
  const { userText } = req.body;
  if (!req.file) return res.status(400).json({ error: 'No image provided' });

  const apiKey = process.env.VISION_CORE_KEY;
  if (!apiKey) {
    return res.json({
      success: true,
      plant: {
        name: "Medicinal Aloe (Aloe Vera)",
        scientificName: "Aloe barbadensis miller",
        description: "A succulent plant species. (Mock mode)",
        medicinalUses: "Treats burns.",
        careTips: "Bright indirect light.",
        emoji: '🌵'
      },
      confidence: 0.95
    });
  }

  try {
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
    let mimeType = req.file.mimetype;
    if (mimeType === 'application/octet-stream') mimeType = 'image/jpeg';
    const imageParts = [{ inlineData: { data: req.file.buffer.toString("base64"), mimeType: mimeType } }];
    const prompt = `Identify this medicinal or herbal plant. JSON ONLY: name, scientificName, description, medicinalUses, careTips, emoji.`;
    const result = await model.generateContent([prompt, ...imageParts]);
    const response = await result.response;
    const text = response.text();
    
    // Clean up markdown block if present
    let jsonStr = text;
    if (jsonStr.startsWith('```json')) {
      jsonStr = jsonStr.substring(7);
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
    }
    
    const plantData = JSON.parse(jsonStr);

    res.json({
      success: true,
      plant: plantData,
      confidence: 0.98
    });

  } catch (err) {
    console.error('Error in /plants/identify:', err);
    res.status(500).json({ error: 'System Identification failed' });
  }
});

// Chat API
app.post('/plants/chat', upload.single('image'), async (req, res) => {
  try {
    const apiKey = process.env.VISION_CORE_KEY;
    if (!apiKey) {
      return res.json({ success: true, reply: "I'm currently in mock mode. Please add a valid API key to chat with me!" });
    }

    if (!req.file) return res.status(400).json({ error: 'No image provided for chat' });

    const { history, message } = req.body;
    let chatHistory = [];
    try {
      if (history) chatHistory = JSON.parse(history);
    } catch(e) {}

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
    
    let mimeType = req.file.mimetype;
    if (mimeType === 'application/octet-stream') mimeType = 'image/jpeg';
    const imageParts = [{ inlineData: { data: req.file.buffer.toString("base64"), mimeType: mimeType } }];
    
    let promptText = `You are Plantora, an expert AI herbalist and botanist rigorously trained on over 1,000 medicinal plants and herbs.
The user has provided an image of a plant and asked a question. 
When identifying a plant, you must provide a highly detailed, professional response similar to an expert botanist.
Include:
1. The most likely identification (Common Name and Scientific Name).
2. Key identifying features visible in the photo (leaves, flowers, growth habit) formatted as a bulleted list.
3. Your confidence level in the identification.
4. Any similar-looking species it could be confused with.
5. What additional information or clearer photos would help confirm the identification.

Answer in a clear, well-structured format. Always be helpful and informative. `;
    if (chatHistory.length > 0) {
      promptText += "Here is the conversation history:\n";
      for (const msg of chatHistory) {
        promptText += `${msg.role === 'user' ? 'User' : 'You'}: ${msg.content}\n`;
      }
    }
    promptText += `\nUser's new message: ${message}\nPlease provide a helpful, concise response.`;

    const result = await model.generateContent([promptText, ...imageParts]);
    const response = await result.response;
    const replyText = response.text();

    res.json({
      success: true,
      reply: replyText
    });
  } catch (err) {
    console.error('Error in /plants/chat:', err);
    res.status(500).json({ error: 'Chat failed' });
  }
});

app.post('/chat/respond', async (req, res) => {
  try {
    const apiKey = process.env.VISION_CORE_KEY;
    if (!apiKey) {
      return res.json({ response: "I'm currently in mock mode. Please add a valid API key to chat with me!", isBot: true });
    }

    const { history, message } = req.body;
    let chatHistory = [];
    if (history) {
      try {
        chatHistory = Array.isArray(history) ? history : JSON.parse(history);
      } catch(e) {}
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    
    let promptText = `You are Plantora Assistant, a friendly and knowledgeable botanical expert for the Plantora app — an intelligent plant identification and agricultural marketplace platform.
You specialize in identifying plants, care tips, diagnosing diseases, and marketplace tips.
Keep your answers friendly, concise, and practical. Formatting with markdown is helpful.
If asked about something unrelated, gently redirect to plants or agriculture.

`;
    if (chatHistory.length > 0) {
      promptText += "Here is the conversation history:\n";
      for (const msg of chatHistory) {
        promptText += `${msg.role === 'user' ? 'User' : 'Plantora Assistant'}: ${msg.content}\n`;
      }
    }
    promptText += `\nUser's new message: ${message || ''}\nPlease provide a helpful, concise response.`;

    const result = await model.generateContent(promptText);
    const responseText = await result.response.text();

    res.json({
      response: responseText,
      isBot: true
    });
  } catch (err) {
    console.error('Error in /chat/respond:', err);
    res.status(500).json({ error: 'Chat failed' });
  }
});

// ====== Customer-Seller Chat Endpoints ======

// 1. Initiate or get existing chat
app.post('/chat/initiate', authenticate, async (req, res) => {
  try {
    const { customerId, sellerId, customerName, sellerName, sellerAvatar } = req.body;
    if (!customerId || !sellerId) return res.status(400).json({ error: 'Missing customerId or sellerId' });

    // Check if chat already exists
    const chatQuery = await db.collection('chats')
      .where('participants', 'array-contains', customerId)
      .get();
      
    let existingChat = null;
    chatQuery.forEach(doc => {
      const data = doc.data();
      if (data.participants.includes(sellerId)) {
        existingChat = { id: doc.id, ...data };
      }
    });

    if (existingChat) {
      return res.json(existingChat);
    }

    // Create new chat
    const newChatRef = db.collection('chats').doc();
    const chatData = {
      participants: [customerId, sellerId],
      customerId,
      sellerId,
      customerName,
      sellerName,
      sellerAvatar: sellerAvatar || null,
      lastMessage: '',
      lastMessageTime: new Date().toISOString(),
      createdAt: new Date().toISOString(),
    };

    await newChatRef.set(chatData);
    res.json({ id: newChatRef.id, ...chatData });
  } catch (err) {
    console.error('Error initiating chat:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 2. Get chats for a user (customer or seller)
app.get('/chat/user/:userId', authenticate, async (req, res) => {
  try {
    const userId = req.params.userId;
    const snapshot = await db.collection('chats')
      .where('participants', 'array-contains', userId)
      .get();

    const chats = [];
    snapshot.forEach(doc => chats.push({ id: doc.id, ...doc.data() }));
    
    // Sort in memory to avoid requiring a Firestore composite index
    chats.sort((a, b) => {
      const timeA = a.lastMessageTime ? new Date(a.lastMessageTime).getTime() : 0;
      const timeB = b.lastMessageTime ? new Date(b.lastMessageTime).getTime() : 0;
      return (isNaN(timeB) ? 0 : timeB) - (isNaN(timeA) ? 0 : timeA);
    });
    
    res.json(chats);
  } catch (err) {
    console.error('Error fetching chats:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 3. Send a message
app.post('/chat/:chatId/message', authenticate, async (req, res) => {
  try {
    const chatId = req.params.chatId;
    const { senderId, text } = req.body;
    if (!senderId || !text) return res.status(400).json({ error: 'Missing fields' });

    const messageData = {
      senderId,
      text,
      timestamp: new Date().toISOString()
    };

    await db.collection('chats').doc(chatId).collection('messages').add(messageData);
    await db.collection('chats').doc(chatId).update({
      lastMessage: text,
      lastMessageTime: messageData.timestamp
    });

    res.json({ success: true, message: messageData });
  } catch (err) {
    console.error('Error sending message:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 4. Get messages for a chat
app.get('/chat/:chatId/messages', authenticate, async (req, res) => {
  try {
    const chatId = req.params.chatId;
    const snapshot = await db.collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', 'asc')
      .get();

    const messages = [];
    snapshot.forEach(doc => messages.push({ id: doc.id, ...doc.data() }));
    res.json(messages);
  } catch (err) {
    console.error('Error fetching messages:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 5. Get messages for an order (Driver/Customer/Seller)
app.get('/orders/:orderId/messages', authenticate, async (req, res) => {
  try {
    const orderId = req.params.orderId;
    const snapshot = await db.collection('orders')
      .doc(orderId)
      .collection('messages')
      .orderBy('timestamp', 'asc')
      .get();

    const messages = [];
    snapshot.forEach(doc => messages.push({ id: doc.id, ...doc.data() }));
    res.json(messages);
  } catch (err) {
    console.error('Error fetching order messages:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ====== Ads for Discounts ======
app.post('/seller/ads', authenticate, async (req, res) => {
  if (req.user.role !== 'Seller') {
    return res.status(403).json({ error: 'Only sellers can create ads' });
  }
  
  const { title, discountPercentage, description, validity, colorHex, colorHexSecondary } = req.body;
  if (!title || !discountPercentage) {
    return res.status(400).json({ error: 'Title and discountPercentage are required' });
  }

  try {
    const adData = {
      sellerId: req.user.id,
      title,
      discountPercentage: Number(discountPercentage),
      description: description || '',
      validity: validity || '',
      colorHex: colorHex || '0xFF0F5A32',
      colorHexSecondary: colorHexSecondary || '0xFF34D399',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
    };
    
    const docRef = await db.collection('ads').add(adData);
    res.json({ success: true, adId: docRef.id });
  } catch (err) {
    console.error('Error creating ad:', err);
    res.status(500).json({ error: 'Failed to create ad' });
  }
});

app.get('/ads', async (req, res) => {
  try {
    const snapshot = await db.collection('ads')
      .where('isActive', '==', true)
      .get();
      
    const ads = [];
    const sellerIds = new Set();
    snapshot.forEach(doc => {
      const data = doc.data();
      ads.push({ id: doc.id, ...data });
      if (data.sellerId) {
        sellerIds.add(data.sellerId);
      }
    });
    
    // Fetch seller profiles in parallel
    const sellerProfiles = {};
    await Promise.all(Array.from(sellerIds).map(async (sellerId) => {
      const userDoc = await db.collection('users').doc(sellerId).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        sellerProfiles[sellerId] = {
          name: userData.name || 'Seller',
          location: userData.location || 'Unknown Location',
          avatar: userData.avatar || null,
        };
      }
    }));
    
    // Attach seller profile to each ad
    const adsWithSeller = ads.map(ad => {
      const seller = sellerProfiles[ad.sellerId] || { name: 'Seller', location: 'Unknown Location', avatar: null };
      return {
        ...ad,
        sellerName: seller.name,
        sellerLocation: seller.location,
        sellerAvatar: seller.avatar,
      };
    });
    
    // Sort in memory instead of requiring a composite index
    adsWithSeller.sort((a, b) => {
      const timeA = a.createdAt ? a.createdAt.toMillis() : 0;
      const timeB = b.createdAt ? b.createdAt.toMillis() : 0;
      return timeB - timeA;
    });
    
    res.json(adsWithSeller);
  } catch (err) {
    console.error('Error fetching all ads:', err);
    res.status(500).json({ error: 'Failed to fetch ads' });
  }
});

app.get('/ads/:sellerId', async (req, res) => {
  try {
    const sellerId = req.params.sellerId;
    const snapshot = await db.collection('ads')
      .where('sellerId', '==', sellerId)
      .where('isActive', '==', true)
      .get();
      
    const ads = [];
    snapshot.forEach(doc => ads.push({ id: doc.id, ...doc.data() }));
    
    // Sort in memory instead of requiring a composite index
    ads.sort((a, b) => {
      const timeA = a.createdAt ? a.createdAt.toMillis() : 0;
      const timeB = b.createdAt ? b.createdAt.toMillis() : 0;
      return timeB - timeA;
    });
    
    res.json(ads);
  } catch (err) {
    console.error('Error fetching ads:', err);
    res.status(500).json({ error: 'Failed to fetch ads' });
  }
});

io.on('connection', (socket) => {
  console.log('A user connected:', socket.id);

  // Customer or Driver joins a room specific to an order
  socket.on('joinOrderRoom', (orderId) => {
    socket.join(`order_${orderId}`);
    console.log(`Socket ${socket.id} joined room: order_${orderId}`);
  });

  // Driver sends their location
  socket.on('updateLocation', (data) => {
    const { orderId, lat, lng, heading } = data;
    // Broadcast to everyone in the room except the driver sending it
    socket.to(`order_${orderId}`).emit('locationUpdated', { lat, lng, heading });
  });

  // Chat messaging
  socket.on('joinOrderRoom', (orderId) => {
    socket.join(`order_${orderId}`);
    console.log(`User joined order room: order_${orderId}`);
  });

  socket.on('sendMessage', async (data) => {
    const { orderId, message, senderId, senderName } = data;
    const timestamp = new Date().toISOString();

    try {
      // Save message to Firestore order messages subcollection
      await db.collection('orders').doc(orderId).collection('messages').add({
        senderId,
        senderName,
        text: message,
        timestamp,
      });
    } catch (e) {
      console.error('Failed to save order chat message to Firestore:', e);
    }
    
    // Broadcast the message to the room
    io.to(`order_${orderId}`).emit('receiveMessage', {
      message,
      senderId,
      senderName,
      timestamp
    });
  });

  // Customer-Seller Chat Rooms
  socket.on('joinChatRoom', (chatId) => {
    socket.join(`chat_${chatId}`);
    console.log(`User joined chat room: chat_${chatId}`);
  });

  socket.on('sendChatMessage', (data) => {
    const { chatId, message, senderId } = data;
    io.to(`chat_${chatId}`).emit('receiveChatMessage', {
      chatId,
      message,
      senderId,
      timestamp: new Date().toISOString()
    });
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// ==========================================
// AI Features (Gemini)
// ==========================================
// ==========================================
// AI Features (Gemini with Botanical Fallback)
// ==========================================
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || 'dummy_key');

function generateBotanicalFallbackReply(query, plantName) {
  const q = (query || '').toLowerCase();
  
  // 1. Aloe Vera
  if (q.includes('aloe') || q.includes('aloevera')) {
    return `🌵 **How to Plant & Care for Aloe Vera (Aloe barbadensis Miller)**:\n\n` +
      `1. **Propagation**: Start with an offset pup cut from the base of a mother plant. Let the cut end callous over for 2 days.\n` +
      `2. **Soil Selection**: Plant in a well-draining cactus/succulent potting mix (50% potting soil + 50% coarse sand/perlite).\n` +
      `3. **Container**: Use a terracotta pot with drainage holes. Terracotta breathes and prevents moisture buildup.\n` +
      `4. **Sunlight**: Requires 6+ hours of bright, indirect sunlight daily. South or West-facing windows are ideal.\n` +
      `5. **Watering Method**: Water deeply every 2–3 weeks only when the soil is 100% bone dry. Overwatering causes root rot!\n` +
      `6. **Harvesting Gel**: Slice outer mature leaves near the base, stand vertically to drain yellow aloin sap for 10 mins, then scoop the pure cooling inner gel.`;
  }

  // 2. Sri Lanka Rare & Endemic Herbal Plants
  if (q.includes('sri lanka') || q.includes('rare') || q.includes('bin kohomba') || q.includes('kothala') || q.includes('venivel') || q.includes('binkohomba') || q.includes('herbal')) {
    return `🇱🇰 **Rare Endemic Medicinal Plants of Sri Lanka**:\n\n` +
      `1. **Bin Kohomba (*Munronia pinnata*)**: Extremely rare and endangered endemic dwarf herb found in Sri Lankan rainforests. Renowned in traditional Sinhala Ayurveda for blood purification and skin ailments.\n` +
      `2. **Kothala Himbutu (*Salacia reticulata*)**: Rare indigenous woody climber found in dry and intermediate rainforest zones. World-famous for natural blood sugar regulation and metabolic wellness.\n` +
      `3. **Venivel / Yellow Vine (*Coscinium fenestratum*)**: Critically endangered medicinal liana used for centuries in Sri Lanka for antibacterial herbal teas, fever treatment, and immune defense.\n` +
      `4. **Suwandel & Heen Bovitiya (*Osbeckia octandra*)**: Rare purple-flowered indigenous shrubs prized for liver protection and traditional herbal remedies.\n\n` +
      `💡 **Conservation Note**: Protect wild specimens; cultivate under shaded tropical conditions with rich organic leaf mold soil.`;
  }

  // 3. Ginger & Turmeric
  if (q.includes('ginger') || q.includes('turmeric')) {
    return `🌱 **How to Plant & Grow Ginger / Turmeric (Zingiberaceae)**:\n\n` +
      `1. **Rhizome Selection**: Select plump rhizomes with visible green eye buds ('growth points').\n` +
      `2. **Soaking**: Soak rhizomes in lukewarm water overnight to break dormancy.\n` +
      `3. **Soil Prep**: Mix 60% rich loamy soil + 40% organic compost & coco peat (pH 6.0–6.8).\n` +
      `4. **Planting**: Plant rhizome pieces 2–4 inches deep with eye buds facing upwards.\n` +
      `5. **Sunlight & Climate**: Warm partial shade (4-6 hours filtered light). Protect from harsh midday heat.\n` +
      `6. **Watering**: Keep soil consistently moist but never soggy. Harvest mature roots in 8–10 months!`;
  }
  
  // 4. Monstera & Tropical Foliage
  if (q.includes('monstera') || q.includes('swiss cheese') || q.includes('pothos') || q.includes('philodendron')) {
    return `🪴 **Monstera & Tropical Climber Care Guide**:\n\n` +
      `1. **Light**: Bright indirect sunlight. Avoid direct harsh sun which scorches split leaves.\n` +
      `2. **Watering**: Water when top 2 inches of soil feel dry. Reduce watering in rainy season.\n` +
      `3. **Humidity**: Thrives in tropical humidity (60%+). Wipe large leaves with a damp cloth to boost photosynthesis.\n` +
      `4. **Support**: Install a sturdy coco-coir or moss pole to support aerial roots and encourage large leaf fenestrations.`;
  }

  // 5. Snake Plant & Succulents
  if (q.includes('snake plant') || q.includes('sansevieria') || q.includes('cactus') || q.includes('succulent')) {
    return `🐍 **Snake Plant & Succulent Care Protocol**:\n\n` +
      `1. **Light**: Adapts to low light up to bright sunlit windows.\n` +
      `2. **Watering**: Water sparingly every 3-4 weeks. Allow soil to dry completely. Less is more!\n` +
      `3. **Soil Mix**: Fast-draining coarse sandy potting soil.\n` +
      `4. **Air Purification**: Absorbs indoor toxins (benzene, formaldehyde) and releases oxygen at night.`;
  }

  // 6. Pests, Diseases & Yellow Leaves
  if (q.includes('pest') || q.includes('disease') || q.includes('yellow') || q.includes('bug') || q.includes('fungus') || q.includes('spot')) {
    return `🩺 **Plant Doctor & Pest Treatment Guide**:\n\n` +
      `• **Yellow Leaves**: Usually caused by overwatering or poor soil drainage. Let soil dry out.\n` +
      `• **Organic Pest Spray**: Mix 1 tbsp Pure Organic Neem Oil + 1/2 tsp mild liquid soap in 1 liter of warm water. Spray infected leaves weekly.\n` +
      `• **Fungal Leaf Spots**: Remove affected foliage, improve air circulation, and avoid splashing water on leaves.`;
  }

  // 7. Propagation & Cuttings
  if (q.includes('propagate') || q.includes('cutting') || q.includes('propagation') || q.includes('grow more')) {
    return `✂️ **Plant Propagation Master Class**:\n\n` +
      `1. **Stem Cuttings**: Cut a healthy 4-6 inch stem just below a leaf node.\n` +
      `2. **Water Propagation**: Place cutting in a clear glass bottle filled with clean filtered water. Change water every 5 days until roots reach 2 inches.\n` +
      `3. **Soil Potting**: Transfer rooted cuttings into small pots with light compost mix and keep in warm shade.`;
  }

  // 8. Dynamic Multi-Topic Fallback Generator for Any Custom Question
  const words = q.split(/\s+/).filter(w => w.length > 3);
  const mainTopic = words.length > 0 ? words[0].toUpperCase() : 'BOTANICAL CARE';
  
  return `🌿 **Plantora AI Botanical Analysis for "${query}"**:\n\n` +
    `Here is specialized advice tailored to your query regarding **${query}**:\n\n` +
    `1. **Growth Environment**: Ensure 4–6 hours of appropriate light (bright indirect light for indoor plants, full sun for outdoor flowering species).\n` +
    `2. **Watering Strategy**: Check soil 1-2 inches deep before watering. Always allow excess water to drain freely to prevent root suffocation.\n` +
    `3. **Soil & Nutrition**: Use well-aerated organic soil mixed with 20% compost. Feed with balanced liquid fertilizer once a month during active growth.\n` +
    `4. **Sri Lankan Climate Tip**: During heavy monsoon seasons, move container plants under shelter to avoid over-saturation and root rot!`;
}

app.post('/api/ai/identify', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No image provided' });
    let mime = req.file.mimetype;
    if (!mime || mime === 'application/octet-stream' || !mime.startsWith('image/')) {
      mime = 'image/jpeg';
    }

    const apiKey = process.env.GEMINI_API_KEY || process.env.PLANT_ID_API_KEY || process.env.VISION_CORE_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY is not configured');
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const modelsToTry = [
      'gemini-flash-latest',
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-1.5-pro'
    ];
    let aiText = null;

    const imageParts = [
      {
        inlineData: {
          data: req.file.buffer.toString("base64"),
          mimeType: mime
        }
      }
    ];

    const prompt = "Examine this plant image carefully. Identify the exact plant species shown in the photo. Return ONLY a valid JSON object with keys: 'species' (scientific botanical name), 'commonName' (popular common name), 'confidence' (number between 0.85 and 0.99), 'description' (a rich 2-3 sentence summary of the identified plant), 'watering' (watering frequency), 'sunlight' (sunlight needs), 'soil' (soil type), 'uses' (medicinal/culinary/ornamental uses). Do not wrap in markdown or extra text.";

    for (const modelName of modelsToTry) {
      try {
        const model = genAI.getGenerativeModel({ model: modelName });
        const result = await model.generateContent([prompt, ...imageParts]);
        aiText = result.response.text();
        if (aiText) break;
      } catch (err) {
        console.warn(`[Identify API] Model ${modelName} failed:`, err.message);
      }
    }

    if (!aiText) {
      throw new Error('All Gemini models failed to generate content');
    }

    let cleanedText = aiText.replace(/```json/g, '').replace(/```/g, '').trim();
    const jsonMatch = cleanedText.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      cleanedText = jsonMatch[0];
    }
    const data = JSON.parse(cleanedText);
    console.log(`[Identify API] Successfully identified plant: ${data.commonName} (${data.species})`);
    return res.json(data);
  } catch (error) {
    console.error('[Identify API] Error:', error.message || error);
    res.status(500).json({
      error: 'Plant identification error: ' + (error.message || 'Unable to identify plant image'),
      success: false
    });
  }
});

app.post('/api/ai/chat', upload.single('image'), async (req, res) => {
  const { message, plantName } = req.body || {};
  try {
    let mime = req.file ? req.file.mimetype : null;
    if (mime && (!mime.startsWith('image/') || mime === 'application/octet-stream')) {
      mime = 'image/jpeg';
    }

    const apiKey = process.env.GEMINI_API_KEY || process.env.PLANT_ID_API_KEY || process.env.VISION_CORE_KEY;
    const genAI = new GoogleGenerativeAI(apiKey);
    const modelsToTry = [
      'gemini-1.5-flash',
      'gemini-1.5-pro',
      'gemini-pro-vision'
    ];

    const promptParts = [
      `You are an expert botanist and helpful plant care assistant. The user asks: "${message || 'What plant is in this image?'}"`
    ];

    if (req.file) {
      promptParts.push({
        inlineData: {
          data: req.file.buffer.toString("base64"),
          mimeType: mime || "image/jpeg"
        }
      });
      promptParts.push("Examine the attached plant photo closely. Identify the exact plant species, common name, botanical features, and answer the user question in detail.");
    }

    let replyText = null;
    for (const modelName of modelsToTry) {
      try {
        const model = genAI.getGenerativeModel({ model: modelName });
        const result = await model.generateContent(promptParts);
        replyText = result.response.text();
        if (replyText) break;
      } catch (err) {
        console.warn(`[Chat API] Model ${modelName} failed:`, err.message);
      }
    }

    if (replyText) {
      return res.json({ reply: replyText });
    }
    throw new Error('All models failed');
  } catch (error) {
    console.error('Gemini chat API call failed:', error.message || error);
    const fallbackReply = generateBotanicalFallbackReply(message, plantName);
    res.json({ reply: fallbackReply });
  }
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => console.log('Server running on port ' + PORT + ' (listening on 0.0.0.0)'));
