const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function checkTables() {
    const snap = await db.collection('clubs').doc('ObnNL7TGuMA8hr1JhBCZ').collection('tables').get();
    console.log(`Found ${snap.size} tables.`);
    for (const doc of snap.docs) {
        console.log(`Table: ${doc.id}`);
        console.log(doc.data());
    }
}
checkTables();
