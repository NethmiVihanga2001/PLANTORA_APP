const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccount = require('./firebase-key.json');
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket: `${serviceAccount.project_id}.firebasestorage.app`
  });
}

const db = admin.firestore();
const PRODUCTS_COL = 'products';

async function seedDatabase() {
  try {
    const seedPath = path.join(__dirname, 'seed_products.json');
    if (!fs.existsSync(seedPath)) {
      console.error('seed_products.json file not found!');
      process.exit(1);
    }

    const products = JSON.parse(fs.readFileSync(seedPath, 'utf8'));
    console.log(`Starting database seed for ${products.length} unique plant products...`);

    const batchSize = 40; // Firestore batch limit is 500 operations
    for (let i = 0; i < products.length; i += batchSize) {
      const chunk = products.slice(i, i + batchSize);
      const batch = db.batch();

      for (const p of chunk) {
        const docRef = db.collection(PRODUCTS_COL).doc(p.id);
        batch.set(docRef, {
          ...p,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
      }

      await batch.commit();
      console.log(`Uploaded batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(products.length / batchSize)} (${chunk.length} items)...`);
    }

    console.log(`🎉 SUCCESS: All ${products.length} unique plant products with unique images uploaded to Firestore database!`);
    process.exit(0);
  } catch (err) {
    console.error('Error seeding database:', err);
    process.exit(1);
  }
}

seedDatabase();
