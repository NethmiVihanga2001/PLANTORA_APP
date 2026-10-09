const fs = require('fs');

const verifiedUrls = JSON.parse(fs.readFileSync('backend/verified_180_urls.json', 'utf8'));
console.log('Loaded verified URLs:', verifiedUrls.length);

// 1. Update lib/data/marketplace_data.dart
let dartContent = fs.readFileSync('lib/data/marketplace_data.dart', 'utf8');
let matchIdx = 0;
dartContent = dartContent.replace(/imageUrl:\s*'([^']+)'/g, (match, oldUrl) => {
  const newUrl = verifiedUrls[matchIdx % verifiedUrls.length];
  matchIdx++;
  return `imageUrl: '${newUrl}'`;
});
fs.writeFileSync('lib/data/marketplace_data.dart', dartContent, 'utf8');
console.log('Updated marketplace_data.dart with verified URLs.');

// 2. Update backend/seed_products.json
let seedProducts = JSON.parse(fs.readFileSync('backend/seed_products.json', 'utf8'));
seedProducts = seedProducts.map((prod, idx) => {
  return {
    ...prod,
    imageUrl: verifiedUrls[idx % verifiedUrls.length]
  };
});
fs.writeFileSync('backend/seed_products.json', JSON.stringify(seedProducts, null, 2), 'utf8');
console.log('Updated seed_products.json with verified URLs.');
