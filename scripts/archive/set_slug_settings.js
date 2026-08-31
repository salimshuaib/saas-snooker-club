const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('../serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function setSlugSettings() {
  const allClubs = await db.collection('clubs').get();
  if (!allClubs.empty) {
    const clubId = allClubs.docs[0].id;
    await db.collection('clubs').doc(clubId).collection('settings').doc('app_config').set({
      business: { slug: 'sharma-billiards' }
    }, { merge: true });
    console.log('Successfully set slug to sharma-billiards in settings for ' + clubId);
  }
  process.exit(0);
}

setSlugSettings();
