const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // Make sure to download this from Firebase Console

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const CLUB_ID = 'sharma_billiards'; // The ID for the migrated club

async function migrateCollection(sourceCollection, targetCollection, transform = null) {
  console.log(`Migrating ${sourceCollection} to ${targetCollection}...`);
  const snapshot = await db.collection(sourceCollection).get();
  
  if (snapshot.empty) {
    console.log(`No documents found in ${sourceCollection}. Skipping.`);
    return;
  }

  let count = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const finalData = transform ? transform(data, doc.id) : data;
    await db.collection(targetCollection).doc(doc.id).set(finalData);
    count++;
  }
  
  console.log(`Successfully migrated ${count} documents from ${sourceCollection}.`);
}

async function migrateCredits() {
  console.log('Migrating credits and subcollections...');
  const snapshot = await db.collection('credits').get();
  
  if (snapshot.empty) {
    console.log('No documents found in credits. Skipping.');
    return;
  }

  let count = 0;
  for (const doc of snapshot.docs) {
    const customerId = doc.id;
    // Migrate customer profile
    await db.collection(`clubs/${CLUB_ID}/credits`).doc(customerId).set(doc.data());
    
    // Migrate transactions
    const transSnap = await db.collection(`credits/${customerId}/transactions`).get();
    for (const txDoc of transSnap.docs) {
      const txData = txDoc.data();
      txData.clubId = CLUB_ID; // Append clubId for collectionGroup queries
      await db.collection(`clubs/${CLUB_ID}/credits/${customerId}/transactions`).doc(txDoc.id).set(txData);
    }

    // Migrate payments
    const paySnap = await db.collection(`credits/${customerId}/payments`).get();
    for (const payDoc of paySnap.docs) {
      const payData = payDoc.data();
      payData.clubId = CLUB_ID; // Append clubId for collectionGroup queries
      await db.collection(`clubs/${CLUB_ID}/credits/${customerId}/payments`).doc(payDoc.id).set(payData);
    }
    
    count++;
  }
  
  console.log(`Successfully migrated ${count} credit customers and their subcollections.`);
}

async function runMigration() {
  try {
    console.log('Starting SaaS Data Migration...');

    // 1. Create Club Document
    console.log('Creating Club document...');
    await db.collection('clubs').doc(CLUB_ID).set({
      id: CLUB_ID,
      name: 'Sharma Billiards',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
      ownerId: 'migrated_owner', 
    });

    // 2. Set Platform Config (so the app can load pricing etc.)
    console.log('Creating Platform config...');
    await db.collection('platform').doc('config').set({
      qrCodeUrl: 'https://example.com/payment_qr.png',
      monthlyPrice: 1500,
      supportPhone: '+91 98765 43210',
    });

    // 3. Migrate top-level collections to club subcollections
    await migrateCollection('tables', `clubs/${CLUB_ID}/tables`);
    await migrateCollection('games', `clubs/${CLUB_ID}/games`);
    await migrateCollection('inventory', `clubs/${CLUB_ID}/inventory`);
    await migrateCollection('stock_history', `clubs/${CLUB_ID}/stock_history`);
    await migrateCollection('quick_sales', `clubs/${CLUB_ID}/quick_sales`);
    await migrateCollection('audit_logs', `clubs/${CLUB_ID}/audit_logs`);
    await migrateCollection('settings', `clubs/${CLUB_ID}/settings`);

    // 4. Migrate credits with subcollections
    await migrateCredits();

    // 5. Migrate Team Members & create user_clubs mapping
    console.log('Migrating team members and user mappings...');
    const teamSnap = await db.collection('team_members').get();
    let teamCount = 0;
    for (const doc of teamSnap.docs) {
      const uid = doc.id;
      // Copy to club team_members
      await db.collection(`clubs/${CLUB_ID}/team_members`).doc(uid).set(doc.data());
      
      // Create user_clubs mapping
      await db.collection('user_clubs').doc(uid).set({
        userId: uid,
        clubId: CLUB_ID,
        role: doc.data().role || 'staff',
        assignedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      teamCount++;
    }
    console.log(`Successfully migrated ${teamCount} team members and created user mappings.`);

    console.log('Migration completed successfully!');
    console.log('NOTE: Original root collections have NOT been deleted for safety.');
    process.exit(0);

  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

runMigration();
