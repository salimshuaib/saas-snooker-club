const { initializeApp, cert } = require('./scripts/node_modules/firebase-admin/app');
const { getFirestore } = require('./scripts/node_modules/firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function getClub() {
  const snapshot = await db.collection('clubs').limit(1).get();
  if (snapshot.empty) {
    console.log('No clubs found');
  } else {
    console.log('YOUR_CLUB_ID_IS: ' + snapshot.docs[0].id);
  }
  process.exit(0);
}

getClub();
