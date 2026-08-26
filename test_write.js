const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function run() {
  try {
    const batch = db.batch();
    batch.update(db.collection('clubs').doc('gX2ll3aNnBZKXyMYoIuB').collection('tables').doc('t1'), { status: 'running' });
    await batch.commit();
    console.log("Success!");
  } catch (e) {
    console.log("Error:", e.code, e.message);
  }
  process.exit(0);
}
run();