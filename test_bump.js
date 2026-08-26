const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const serviceAccount = require("./serviceAccountKey.json");

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function bump() {
  await db.collection("settings").doc("app_config").set({
    minimum_required_version: "1.0.5",
    latest_version: "1.0.5",
  }, { merge: true });
  console.log("Bumped to 1.0.5!");
  process.exit(0);
}
bump();
