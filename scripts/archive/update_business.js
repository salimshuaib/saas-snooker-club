const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('../serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function update() {
  await db.collection('clubs').doc('gX2ll3aNnBZKXyMYoIuB').collection('settings').doc('app_config').set({
    business: {
      contactNumber: '+91 98994 83973',
      address: 'Snooker Hub Yamuna Vihar',
      clubName: 'Snooker Hub',
      slug: 'snookerhub'
    }
  }, { merge: true });
  console.log('Updated!');
  process.exit(0);
}

update();
