const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('../serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function check() {
  const q = await db.collection('user_clubs').get();
  for (const doc of q.docs) {
    console.log(doc.id, '->', doc.data().clubId);
  }
  process.exit(0);
}

check();
