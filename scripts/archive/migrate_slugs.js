const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('../serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function migrateSlugs() {
  const clubsSnapshot = await db.collection('clubs').get();
  let count = 0;
  
  for (const doc of clubsSnapshot.docs) {
    const data = doc.data();
    
    // Only generate a slug if it doesn't already have one
    if (!data.slug || data.slug.trim() === '') {
      let clubName = data.clubName;
      let generatedSlug;
      
      if (clubName) {
        generatedSlug = clubName.trim().toLowerCase().replace(/[^a-z0-9]/g, '-').replace(/-+/g, '-');
      }
      
      if (!generatedSlug) {
        generatedSlug = 'club-' + doc.id.substring(0, 6).toLowerCase();
      }
      
      console.log('Migrating club:', doc.id, '-> slug:', generatedSlug);
      
      // Update root doc
      await db.collection('clubs').doc(doc.id).update({
        slug: generatedSlug
      });
      
      // Update settings/app_config doc
      await db.collection('clubs').doc(doc.id).collection('settings').doc('app_config').set({
        business: {
          slug: generatedSlug
        }
      }, { merge: true });
      
      count++;
    } else {
      console.log('Club', doc.id, 'already has slug:', data.slug);
      
      // Just make sure it's in settings/app_config as well
      await db.collection('clubs').doc(doc.id).collection('settings').doc('app_config').set({
        business: {
          slug: data.slug
        }
      }, { merge: true });
    }
  }
  
  console.log('Migration complete. Updated ' + count + ' clubs.');
  process.exit(0);
}

migrateSlugs();
