const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function checkClubs() {
    const clubsSnap = await db.collection('clubs').get();
    console.log(`Found ${clubsSnap.size} clubs.`);
    for (const doc of clubsSnap.docs) {
        console.log(`Club ID: ${doc.id}`);
        console.log(doc.data());
        // check settings
        const settingsSnap = await db.collection('clubs').doc(doc.id).collection('settings').doc('club_config').get();
        console.log('Settings exists:', settingsSnap.exists);
        if (settingsSnap.exists) {
            console.log('Settings data:', settingsSnap.data());
        }
        console.log('---');
    }
}
checkClubs();
