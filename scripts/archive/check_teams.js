const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function checkTeams() {
    const snap = await db.collection('clubs').doc('ObnNL7TGuMA8hr1JhBCZ').collection('team_members').get();
    console.log(`Found ${snap.size} team members.`);
    for (const doc of snap.docs) {
        console.log(`UID: ${doc.id}`);
        console.log(doc.data());
    }
}
checkTeams();
