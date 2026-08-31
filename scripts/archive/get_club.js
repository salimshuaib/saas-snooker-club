const admin = require('./scripts/node_modules/firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function getClub() {
  const snapshot = await db.collection('clubs').limit(1).get();
  if (snapshot.empty) {
    console.log('No clubs found');
  } else {
    console.log('CLUB_ID: ' + snapshot.docs[0].id);
  }
  process.exit(0);
}

getClub();
