const fs = require('fs');
const https = require('https');

// Collection of real, high quality Unsplash plant photo IDs
const plantPhotoIds = [
  'photo-1512428559087-560fa5ceab42',
  'photo-1485955900006-10f4d324d411',
  'photo-1545241047-6083a3684587',
  'photo-1509316975850-ff9c5deb0cd9',
  'photo-1463936575829-25148e1db1b8',
  'photo-1518531933037-91b2f5f229cc',
  'photo-1501004318641-b39e6451bec6',
  'photo-1459411552884-841db9b3cc2a',
  'photo-1530836369250-ef72a3f5cda8',
  'photo-1466781783364-36c955e42a7f',
  'photo-1520412099551-62b6bafeb5bb',
  'photo-1534710961216-75c88202f43e',
  'photo-1508610048659-a06b669e3321',
  'photo-1525498128493-380d1990a112',
  'photo-1517191404922-50880b104996',
  'photo-1497250681960-ef046c08a56e',
  'photo-1509423350716-97f9360b4e09',
  'photo-1448375240586-882707db888b',
  'photo-1512428559087-560fa5ceab42',
  'photo-1535242208474-9a2793260ca8',
  'photo-1520412099551-62b6bafeb5bb',
  'photo-1544816155-12df9643f363',
  'photo-1518531933037-91b2f5f229cc',
  'photo-1509316975850-ff9c5deb0cd9',
  'photo-1501004318641-b39e6451bec6',
  'photo-1463936575829-25148e1db1b8',
  'photo-1485955900006-10f4d324d411',
  'photo-1545241047-6083a3684587',
  'photo-1459411552884-841db9b3cc2a',
  'photo-1530836369250-ef72a3f5cda8'
];

function checkUrl(url) {
  return new Promise((resolve) => {
    https.get(url, (res) => {
      resolve(res.statusCode === 200 || res.statusCode === 302);
    }).on('error', () => resolve(false));
  });
}

console.log('Testing photo IDs...');
