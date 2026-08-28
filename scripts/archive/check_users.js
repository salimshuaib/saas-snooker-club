const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function checkUserClubs() {
    const snap = await db.collection('user_clubs').get();
    console.log(`Found ${snap.size} user_clubs.`);
    for (const doc of snap.docs) {
        console.log(`UID: ${doc.id}`);
        console.log(doc.data());
        console.log('---');
    }
}
checkUserClubs();
