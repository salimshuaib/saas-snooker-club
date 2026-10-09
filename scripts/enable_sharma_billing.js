const admin = require('firebase-admin');

// Initialize the app if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function run() {
  const clubId = 'ObnNL7TGuMA8hr1JhBCZ';
  console.log(`Setting manualFinalAmountEnabled for club: ${clubId}`);
  
  const settingsRef = db.collection('clubs').doc(clubId).collection('settings').doc('club_config');
  
  await settingsRef.set({
    billingFeatures: {
      manualFinalAmountEnabled: true,
      selectionMode: 'two_adjacent_options',
      incrementPaise: 1000
    }
  }, { merge: true });
  
  console.log('Feature enabled successfully.');
  process.exit(0);
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});
