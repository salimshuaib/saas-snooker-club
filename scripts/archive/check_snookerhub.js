const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('../serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function checkData() {
  const q = await db.collection('clubs').where('slug', '==', 'snookerhub').get();
  if (q.empty) {
    console.log('No club found with slug snookerhub');
  } else {
    const docId = q.docs[0].id;
    console.log('Found club ID:', docId);
    const settings = await db.collection('clubs').doc(docId).collection('settings').doc('app_config').get();
    console.log('Settings:', settings.data());
  }
  process.exit(0);
}

checkData();
