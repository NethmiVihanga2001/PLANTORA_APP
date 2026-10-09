const fs = require('fs');
const https = require('https');

// A large pool of real Unsplash photo IDs of plants, flowers, succulents, trees, gardens, leaves
const candidatePhotoIds = [
  '1512428559087-560fa5ceab42', '1485955900006-10f4d324d411', '1545241047-6083a3684587', '1509316975850-ff9c5deb0cd9',
  '1463936575829-25148e1db1b8', '1518531933037-91b2f5f229cc', '1501004318641-b39e6451bec6', '1459411552884-841db9b3cc2a',
  '1530836369250-ef72a3f5cda8', '1466781783364-36c955e42a7f', '1520412099551-62b6bafeb5bb', '1534710961216-75c88202f43e',
  '1508610048659-a06b669e3321', '1525498128493-380d1990a112', '1517191404922-50880b104996', '1497250681960-ef046c08a56e',
  '1448375240586-882707db888b', '1535242208474-9a2793260ca8', '1544816155-12df9643f363', '1584589167171-541ce45f1eea',
  '1536882240095-0379873feb4e', '1470058869958-2a77ade41c02', '1508595165502-3e2be5429f63', '1509198397868-475647b2a1e5',
  '1513836279014-a89f7a76ae86', '1533038590840-1cde6e668a93', '1587502537745-84b86da12053', '1614594975525-e45190c55d0b',
  '1502082553048-f009c37129b9', '1518495973542-4542c06a5843', '1477414348463-c0eb7f1359b6', '1526047932273-341f2a7631f9',
  '1465146344425-f00d5f5c8f07', '1500651230702-0e2d8a49d4ad', '1512428559087-560fa5ceab42', '1533038590840-1cde6e668a93',
  '1551893478-d726eaf0442c', '1512428559087-560fa5ceab42', '1485955900006-10f4d324d411', '1545241047-6083a3684587'
];

// We can also generate valid Unsplash plant URLs using Unsplash search endpoints or Pexels high-res plant images
function checkUrl(url) {
  return new Promise((resolve) => {
    https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
      resolve(res.statusCode === 200 || res.statusCode === 301 || res.statusCode === 302);
    }).on('error', () => resolve(false));
  });
}

async function find180VerifiedUrls() {
  console.log('Finding 180 verified working plant image URLs...');
}
