const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function checkLogs() {
    const snap = await db.collection('debug_logs').orderBy('timestamp', 'desc').limit(20).get();
    console.log(`Found ${snap.size} logs.`);
    for (const doc of snap.docs) {
        console.log(`Log ID: ${doc.id}`);
        console.log(doc.data());
        console.log('---');
    }
}
checkLogs();
