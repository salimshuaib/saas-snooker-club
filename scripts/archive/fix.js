const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('../serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function fix() {
  await db.collection('clubs').doc('gX2ll3aNnBZKXyMYoIuB').update({
    slug: 'snookerhub'
  });
  
  await db.collection('clubs').doc('gX2ll3aNnBZKXyMYoIuB').collection('settings').doc('app_config').set({
    business: {
      slug: 'snookerhub'
    }
  }, { merge: true });
  
  console.log('Fixed slug for snookerhub');
  process.exit(0);
}

fix();
