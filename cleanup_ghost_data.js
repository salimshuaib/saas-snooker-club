const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function deleteCollection(collectionPath, batchSize) {
  const collectionRef = db.collection(collectionPath);
  const query = collectionRef.orderBy('__name__').limit(batchSize);

  return new Promise((resolve, reject) => {
    deleteQueryBatch(query, resolve).catch(reject);
  });
}

async function deleteQueryBatch(query, resolve) {
  const snapshot = await query.get();

  const batchSize = snapshot.size;
  if (batchSize === 0) {
    resolve();
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });
  await batch.commit();

  process.nextTick(() => {
    deleteQueryBatch(query, resolve);
  });
}

async function runCleanup() {
  try {
    console.log("Starting cleanup of old ghost data...");

    console.log("Deleting root 'inventory' collection...");
    await deleteCollection('inventory', 500);
    
    console.log("Deleting root 'tables' collection...");
    await deleteCollection('tables', 500);
    
    console.log("Deleting root 'team_members' collection...");
    await deleteCollection('team_members', 500);

    console.log("Deleting root 'settings/club_config' document...");
    await db.collection('settings').doc('club_config').delete();

    console.log("Cleanup completely finished! Your database is perfectly clean.");
    process.exit(0);
  } catch (error) {
    console.error("Error during cleanup:", error);
    process.exit(1);
  }
}

runCleanup();