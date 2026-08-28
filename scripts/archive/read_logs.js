const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const serviceAccount = require("./serviceAccountKey.json");

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function readLogs() {
  const snapshot = await db.collection("debug_logs").orderBy("timestamp", "desc").limit(5).get();
  snapshot.forEach(doc => {
    console.log(doc.data().message);
  });
  process.exit(0);
}
readLogs();
