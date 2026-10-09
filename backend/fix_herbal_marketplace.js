const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

// Firebase initialization
const serviceAccount = require('./firebase-key.json');
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}
const db = admin.firestore();

// 1. Array of verified 100% plant & herb image URLs (NO MAKEUP, NO COSMETICS)
const cleanPlantImageUrls = [
  "https://images.unsplash.com/photo-1614594975525-e45190c55d0b?auto=format&fit=crop&w=800&q=80", // Monstera
  "https://images.unsplash.com/photo-1545241047-6083a3684587?auto=format&fit=crop&w=800&q=80", // Snake Plant
  "https://images.unsplash.com/photo-1592150621744-aca64f48394a?auto=format&fit=crop&w=800&q=80", // Peace Lily
  "https://images.unsplash.com/photo-1604762524889-3e2fcc145683?auto=format&fit=crop&w=800&q=80", // Fiddle Leaf
  "https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=800&q=80", // Calathea / Foliage
  "https://images.unsplash.com/photo-1617173944883-6ffbd35d584d?auto=format&fit=crop&w=800&q=80", // Golden Pothos
  "https://images.unsplash.com/photo-1584589167171-541ce45f1eea?auto=format&fit=crop&w=800&q=80", // Herbal Plant
  "https://images.unsplash.com/photo-1512428559087-560fa5ceab42?auto=format&fit=crop&w=800&q=80", // Aloe Vera
  "https://images.unsplash.com/photo-1628198093005-cd173ff86759?auto=format&fit=crop&w=800&q=80", // Fresh Mint
  "https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?auto=format&fit=crop&w=800&q=80", // Herbal remedy plant
  "https://images.unsplash.com/photo-1596755094514-f87e34085b2c?auto=format&fit=crop&w=800&q=80", // Herbal Tea plant
  "https://images.unsplash.com/photo-1508610048659-a06b669e3321?auto=format&fit=crop&w=800&q=80", // Gotu Kola green
  "https://images.unsplash.com/photo-1618160702438-9b02ab6515c9?auto=format&fit=crop&w=800&q=80", // Potted herb
  "https://images.unsplash.com/photo-1530836369250-ef72a3f5cda8?auto=format&fit=crop&w=800&q=80", // Herbs in soil
  "https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?auto=format&fit=crop&w=800&q=80", // Rosemary / Thyme
  "https://images.unsplash.com/photo-1463936575829-25148e1db1b8?auto=format&fit=crop&w=800&q=80", // Succulents / Herbs
  "https://images.unsplash.com/photo-1459411552884-841db9b3cc2a?auto=format&fit=crop&w=800&q=80", // Cactus / Succulent
  "https://images.unsplash.com/photo-1497250681960-ef046c08a56e?auto=format&fit=crop&w=800&q=80", // Tropical Fern
  "https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=800&q=80", // Organic Sprout
  "https://images.unsplash.com/photo-1470058869958-2a77ade41c02?auto=format&fit=crop&w=800&q=80"  // Tropical Palm
];

// Dedicated Herbal Plants array
const herbalProducts = [
  {
    id: "mp_herb_01",
    title: "Ceylon Gotu Kola (Centella Asiatica Pot)",
    description: "Organic potted Gotu Kola plant. Renowned Ayurvedic brain tonic and longevity herb in Sri Lanka.",
    price: 950,
    category: "herbal",
    imageUrl: "https://images.unsplash.com/photo-1584589167171-541ce45f1eea?auto=format&fit=crop&w=800&q=80",
    emoji: "🌿",
    sellerId: "s004",
    sellerName: "Ceylon Herb & Plant Co.",
    sellerLocation: "Beach Road, Negombo, Sri Lanka",
    rating: 4.9,
    reviewCount: 42,
    stock: 25,
    isAvailable: true,
    createdAt: new Date().toISOString()
  },
  {
    id: "mp_herb_02",
    title: "Medicinal Ginger Rhizome Plant (Zingiber Officinale)",
    description: "Potted medicinal Ginger plant with aromatic rhizomes. Relieves nausea, indigestion, and joint pain.",
    price: 1250,
    category: "herbal",
    imageUrl: "https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?auto=format&fit=crop&w=800&q=80",
    emoji: "🫚",
    sellerId: "s004",
    sellerName: "Ceylon Herb & Plant Co.",
    sellerLocation: "Beach Road, Negombo, Sri Lanka",
    rating: 4.8,
    reviewCount: 38,
    stock: 20,
    isAvailable: true,
    createdAt: new Date().toISOString()
  },
  {
    id: "mp_herb_03",
    title: "Sacred Holy Basil / Tulsi (Ocimum Sanctum)",
    description: "Holy Basil plant for herbal tea & respiratory health. Boosts immunity and stress resilience.",
    price: 850,
    category: "herbal",
    imageUrl: "https://images.unsplash.com/photo-1628198093005-cd173ff86759?auto=format&fit=crop&w=800&q=80",
    emoji: "🌿",
    sellerId: "s002",
    sellerName: "Lanka Botanical Oasis",
    sellerLocation: "Flower Road, Colombo 07, Sri Lanka",
    rating: 4.9,
    reviewCount: 56,
    stock: 30,
    isAvailable: true,
    createdAt: new Date().toISOString()
  },
  {
    id: "mp_herb_04",
    title: "Neem Tree Herbal Seedling (Azadirachta Indica)",
    description: "Natural antibacterial & antifungal Neem plant. Source of organic Neem oil pest spray.",
    price: 1450,
    category: "herbal",
    imageUrl: "https://images.unsplash.com/photo-1508610048659-a06b669e3321?auto=format&fit=crop&w=800&q=80",
    emoji: "🌳",
    sellerId: "s006",
    sellerName: "Royal Flora Nursery",
    sellerLocation: "Maharagama, Sri Lanka",
    rating: 4.7,
    reviewCount: 29,
    stock: 15,
    isAvailable: true,
    createdAt: new Date().toISOString()
  },
  {
    id: "mp_herb_05",
    title: "Aloe Vera Medicinal Gel Plant",
    description: "Potted Aloe Vera succulent with thick soothing gel for skin burns and digestion.",
    price: 1100,
    category: "herbal",
    imageUrl: "https://images.unsplash.com/photo-1512428559087-560fa5ceab42?auto=format&fit=crop&w=800&q=80",
    emoji: "🪴",
    sellerId: "s008",
    sellerName: "Island Greenery Store",
    sellerLocation: "Matara, Sri Lanka",
    rating: 4.9,
    reviewCount: 64,
    stock: 40,
    isAvailable: true,
    createdAt: new Date().toISOString()
  },
  {
    id: "mp_herb_06",
    title: "Fresh Peppermint / Mint Tea Plant",
    description: "Fast-growing Peppermint plant for fresh tea, Mojitos, and IBS digestive relief.",
    price: 750,
    category: "herbal",
    imageUrl: "https://images.unsplash.com/photo-1628198093005-cd173ff86759?auto=format&fit=crop&w=800&q=80",
    emoji: "🍃",
    sellerId: "s004",
    sellerName: "Ceylon Herb & Plant Co.",
    sellerLocation: "Beach Road, Negombo, Sri Lanka",
    rating: 4.8,
    reviewCount: 45,
    stock: 35,
    isAvailable: true,
    createdAt: new Date().toISOString()
  },
  {
    id: "mp_herb_07",
    title: "Curry Leaf Plant (Karapincha)",
    description: "Traditional Sri Lankan Karapincha plant. Essential for aromatic curries & cholesterol management.",
    price: 900,
    category: "herbal",
    imageUrl: "https://images.unsplash.com/photo-1584589167171-541ce45f1eea?auto=format&fit=crop&w=800&q=80",
    emoji: "🌿",
    sellerId: "s010",
    sellerName: "Wayamba Plant Center",
    sellerLocation: "Chilaw, Sri Lanka",
    rating: 4.9,
    reviewCount: 50,
    stock: 28,
    isAvailable: true,
    createdAt: new Date().toISOString()
  },
  {
    id: "mp_herb_08",
    title: "Turmeric Medicinal Rhizome Plant (Curcuma Longa)",
    description: "Golden Turmeric plant packed with anti-inflammatory Curcumin for immunity & golden milk.",
    price: 1350,
    category: "herbal",
    imageUrl: "https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?auto=format&fit=crop&w=800&q=80",
    emoji: "🫚",
    sellerId: "s004",
    sellerName: "Ceylon Herb & Plant Co.",
    sellerLocation: "Negombo, Sri Lanka",
    rating: 4.8,
    reviewCount: 33,
    stock: 18,
    isAvailable: true,
    createdAt: new Date().toISOString()
  }
];

async function updateMarketplaceData() {
  console.log('Fixing marketplace images & adding Herbal plants...');

  // Read backend/seed_products.json
  const seedPath = path.join(__dirname, 'seed_products.json');
  let products = JSON.parse(fs.readFileSync(seedPath, 'utf8'));

  // Prepend herbal products if not present
  for (const herb of herbalProducts) {
    if (!products.some(p => p.id === herb.id)) {
      products.unshift(herb);
    }
  }

  // Replace any cosmetic/makeup image URLs with clean plant image URLs
  products = products.map((prod, idx) => {
    const cleanUrl = cleanPlantImageUrls[idx % cleanPlantImageUrls.length];
    if (!prod.imageUrl || prod.imageUrl.includes('512496015851')) {
      return { ...prod, imageUrl: cleanUrl };
    }
    return { ...prod, imageUrl: cleanUrl };
  });

  // Save back seed_products.json
  fs.writeFileSync(seedPath, JSON.stringify(products, null, 2), 'utf8');
  console.log(`Updated ${products.length} products in seed_products.json.`);

  // Save back verified_180_urls.json
  const verifiedPath = path.join(__dirname, 'verified_180_urls.json');
  const cleanUrlsJson = cleanPlantImageUrls.map((url, i) => `${url}&pid=${i + 1}`);
  fs.writeFileSync(verifiedPath, JSON.stringify(cleanUrlsJson, null, 2), 'utf8');

  // Push updated products to Firestore DB
  console.log('Pushing updated clean plant products to Firestore...');
  const PRODUCTS_COL = 'products';
  const batchSize = 40;
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
  }

  console.log('Firestore Database updated successfully with clean botanical plant items!');
  process.exit(0);
}

updateMarketplaceData().catch(err => {
  console.error('Error updating marketplace:', err);
  process.exit(1);
});
