const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function run() {
  const snapshot = await db.collection('debug_logs').orderBy('timestamp', 'desc').limit(20).get();
  snapshot.docs.forEach(doc => {
    console.log(doc.data().timestamp?.toDate(), doc.data().message);
  });
  process.exit(0);
}
run();