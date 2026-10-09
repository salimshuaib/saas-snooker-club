const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({ projectId: 'saas-snooker-club' });
const db = getFirestore();

async function run() {
  const clubsSnapshot = await db.collection('clubs').get();
  console.log('Available clubs:');
  clubsSnapshot.forEach(doc => {
    console.log(doc.id, doc.data());
  });
}

run().catch(console.error);
