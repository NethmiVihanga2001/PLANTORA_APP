const admin = require('firebase-admin');
console.log('firebase-admin imported successfully.');
const serviceAccount = require('./firebase-key.json');
console.log('Service account loaded.');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: `${serviceAccount.project_id}.firebasestorage.app`
});
console.log('Firebase initialized!');
const db = admin.firestore();
console.log('Firestore reference retrieved.');
db.collection('users').limit(1).get().then(snap => {
  console.log('Database query successful, document count:', snap.size);
  process.exit(0);
}).catch(err => {
  console.error('Database query failed:', err);
  process.exit(1);
});
