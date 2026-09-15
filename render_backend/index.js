const admin = require("firebase-admin");

// Initialize Firebase Admin using the Service Account credentials
// Render will inject the FIREBASE_SERVICE_ACCOUNT_JSON environment variable
let serviceAccount;
try {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
} catch (e) {
  console.error("Failed to parse FIREBASE_SERVICE_ACCOUNT_JSON. Make sure it is set as a secret environment variable.");
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
console.log("Started S&B Manager Push Notification Server.");

// Listen to all bookings collections across all clubs
// We use a collectionGroup query to listen to ALL "bookings" collections in real-time
db.collectionGroup("bookings").onSnapshot(async (snapshot) => {
  // Extract only the newly added bookings
  const changes = snapshot.docChanges();
  
  for (const change of changes) {
    if (change.type === "added") {
      const bookingData = change.doc.data();
      const bookingRef = change.doc.ref;
      
      // The path is clubs/{clubId}/bookings/{bookingId}
      // Let's extract the clubId from the path
      const clubId = bookingRef.parent.parent.id;
      
      console.log(`New booking detected for club ${clubId}: ${bookingData.customerName}`);
      await handleNewBooking(clubId, bookingData, change.doc.id);
    }
  }
}, (error) => {
  console.error("Error listening to Firestore:", error);
});

async function handleNewBooking(clubId, bookingData, bookingId) {
  try {
    // 1. Find all users associated with this club
    const userClubsSnapshot = await db.collection("userClubs")
      .where("clubId", "==", clubId)
      .get();

    if (userClubsSnapshot.empty) {
      console.log(`No users found for club ${clubId}`);
      return;
    }

    const userIds = userClubsSnapshot.docs.map(doc => doc.id);
    const tokens = [];

    // 2. Fetch FCM tokens for these users
    for (const uid of userIds) {
      const userDoc = await db.collection("users").doc(uid).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        if (userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
          tokens.push(...userData.fcmTokens);
        }
      }
    }

    if (tokens.length === 0) {
      console.log(`No FCM tokens found for club ${clubId}`);
      return;
    }

    // 3. Construct the notification payload
    const payload = {
      notification: {
        title: "New Booking Request \uD83C\uDFB1",
        body: `${bookingData.customerName || "A customer"} booked ${bookingData.resourceName || "a table"}.`,
      },
      data: {
        bookingId: bookingId,
        clubId: clubId,
      }
    };

    // 4. Send the push notification
    const response = await admin.messaging().sendToDevice(tokens, payload);
    console.log("Successfully sent messages:", response.successCount);
    
    // Optional: Cleanup invalid tokens
    const tokensToRemove = [];
    response.results.forEach((result, index) => {
      const error = result.error;
      if (error) {
        console.error("Failure sending notification to", tokens[index], error);
      }
    });

  } catch (error) {
    console.error("Error processing booking notification:", error);
  }
}

