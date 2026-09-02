const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('../../serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function investigate() {
  const clubs = await db.collection('clubs').get();
  let targetClubId = null;
  let targetPlayerId = null;

  console.log("Searching for player 'Kaif Sonet'...");
  for (const clubDoc of clubs.docs) {
    const clubId = clubDoc.id;
    const credits = await db.collection('clubs').doc(clubId).collection('credits').get();
    for (const customer of credits.docs) {
      if (customer.data().name && customer.data().name.toLowerCase() === 'kaif sonet') {
        console.log(`Found Kaif Sonet in club: ${clubId}, customerId: ${customer.id}`);
        targetClubId = clubId;
        targetPlayerId = customer.id;
        console.log("Customer Data:", customer.data());
      }
    }
  }

  if (!targetClubId || !targetPlayerId) {
    console.log("Player not found!");
    process.exit(1);
  }

  console.log("\n--- GAMES ---");
  const games = await db.collection('clubs').doc(targetClubId).collection('games').get();
  for (const doc of games.docs) {
    const data = doc.data();
    if ((data.paidBy && data.paidBy.toLowerCase() === 'kaif sonet') || 
        (data.playerIdentities && Object.values(data.playerIdentities).includes(targetPlayerId))) {
      console.log("game:", doc.id, "startTime:", data.startTime?.toDate(), "paidBy:", data.paidBy, "paymentMethod:", data.paymentMethod, "totalAmount:", data.finalAmount || data.customPrice || data.roundCost, "status:", data.status);
    }
  }

  console.log("\n--- PAYMENT HISTORY ---");
  const payments = await db.collection('clubs').doc(targetClubId).collection('credits').doc(targetPlayerId).collection('payment_history').get();
  for (const doc of payments.docs) {
    console.log("payment_history:", doc.id, doc.data());
  }
  
  console.log("\n--- TRANSACTIONS ---");
  const transactions = await db.collection('clubs').doc(targetClubId).collection('credits').doc(targetPlayerId).collection('transactions').get();
  for (const doc of transactions.docs) {
    console.log("transactions:", doc.id, doc.data());
  }
  
  console.log("\n--- QUICK SALES ---");
  const quick_sales = await db.collection('clubs').doc(targetClubId).collection('quick_sales').where('customerId', '==', targetPlayerId).get();
  for (const doc of quick_sales.docs) {
    console.log("quick_sales:", doc.id, doc.data());
  }

  process.exit(0);
}

investigate().catch(console.error);
