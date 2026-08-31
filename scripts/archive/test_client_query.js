const firebase = require('firebase/app');
const firestore = require('firebase/firestore');

const firebaseConfig = {
  projectId: "saas-snooker-club",
};

const app = firebase.initializeApp(firebaseConfig);
const db = firestore.getFirestore(app);

async function testQuery() {
  try {
    const q = firestore.query(firestore.collection(db, 'clubs'), firestore.where('slug', '==', 'snookerhub'), firestore.limit(1));
    const snapshot = await firestore.getDocs(q);
    if (snapshot.empty) {
      console.log('Query returned empty!');
    } else {
      console.log('Found club:', snapshot.docs[0].id);
    }
  } catch(e) {
    console.error('Error:', e.message);
  }
  process.exit(0);
}

testQuery();
