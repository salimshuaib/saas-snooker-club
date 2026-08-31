const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('../serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function check() {
  const doc = await db.collection('clubs').doc('gX2ll3aNnBZKXyMYoIuB').get();
  console.log('Doc data:', doc.data());
  process.exit(0);
}

check();
