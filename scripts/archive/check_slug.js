const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('../serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function checkSlug() {
  const snapshot = await db.collection('clubs').where('slug', '==', 'sharma-billiards').get();
  if (snapshot.empty) {
    console.log('Slug not found in database!');
    
    // Let's check what IS in the database for the club!
    const allClubs = await db.collection('clubs').get();
    if (!allClubs.empty) {
      console.log('First club data:', allClubs.docs[0].data());
    }
  } else {
    console.log('Found club with slug:', snapshot.docs[0].id);
  }
  process.exit(0);
}

checkSlug();
