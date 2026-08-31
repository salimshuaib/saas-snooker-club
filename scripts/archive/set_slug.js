const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('../serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function setSlug() {
  const allClubs = await db.collection('clubs').get();
  if (!allClubs.empty) {
    const clubId = allClubs.docs[0].id;
    await db.collection('clubs').doc(clubId).update({
      slug: 'sharma-billiards'
    });
    console.log('Successfully set slug to sharma-billiards for club ' + clubId);
  }
  process.exit(0);
}

setSlug();
