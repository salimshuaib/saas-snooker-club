const admin = require("firebase-admin");
const express = require("express");

// Initialize Firebase Admin using the Service Account credentials
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

// -----------------------------------------
// Express Web Server (Required for Render Web Service)
// -----------------------------------------
const app = express();
const PORT = process.env.PORT || 10000;

app.get("/", (req, res) => {
  res.send("S&B Manager Push Notification Server is running!");
});

// A ping endpoint to keep the free tier awake
app.get("/ping", (req, res) => {
  res.status(200).send("pong");
});

app.listen(PORT, () => {
  console.log(`Web server listening on port ${PORT}`);
});

// -----------------------------------------
// Firestore Listener Logic
// -----------------------------------------
console.log("Started S&B Manager Push Notification Listener.");

const START_TIME = Date.now();

db.collectionGroup("bookings").onSnapshot(async (snapshot) => {
  const changes = snapshot.docChanges();
  
  // Prevent spamming notifications for existing bookings when the server restarts
  if (Date.now() - START_TIME < 5000) {
    console.log(`Ignoring initial load of ${changes.length} bookings.`);
    return;
  }
  
  for (const change of changes) {
    if (change.type === "added") {
      const bookingData = change.doc.data();
      const bookingRef = change.doc.ref;
      
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
    const userClubsSnapshot = await db.collection("user_clubs")
      .where("clubId", "==", clubId)
      .get();

    if (userClubsSnapshot.empty) {
      console.log(`No users found for club ${clubId}`);
      return;
    }

    const userIds = userClubsSnapshot.docs.map(doc => doc.id);
    const tokens = [];

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

    const response = await admin.messaging().sendToDevice(tokens, payload);
    console.log("Successfully sent messages:", response.successCount);

  } catch (error) {
    console.error("Error processing booking notification:", error);
  }
}

