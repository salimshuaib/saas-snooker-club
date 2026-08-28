const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const serviceAccount = require("./serviceAccountKey.json");

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function revert() {
  await db.collection("settings").doc("app_config").set({
    minimum_required_version: "1.0.4",
    latest_version: "1.0.4",
  }, { merge: true });
  console.log("Reverted to 1.0.4");
  process.exit(0);
}
revert();
