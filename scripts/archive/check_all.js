const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('../serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function checkAll() {
  const allClubs = await db.collection('clubs').get();
  for (const doc of allClubs.docs) {
    console.log('Club:', doc.id, doc.data().clubName, doc.data().slug);
    const settings = await db.collection('clubs').doc(doc.id).collection('settings').doc('app_config').get();
    console.log('  Settings:', settings.data());
  }
  process.exit(0);
}

checkAll();
