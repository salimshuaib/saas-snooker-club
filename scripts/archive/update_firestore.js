const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const serviceAccountPath = path.join(__dirname, '../serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error("Error: serviceAccountKey.json not found in the project root.");
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();
const pubspecPath = path.join(__dirname, '../pubspec.yaml');

async function run() {
  try {
    const pubspecContent = fs.readFileSync(pubspecPath, 'utf8');
    const pubspec = yaml.load(pubspecContent);
    
    const rawVersion = pubspec.version;
    const cleanVersion = rawVersion.split('+')[0];

    console.log(`Detected App Version: ${cleanVersion}`);

    const docRef = db.collection('settings').doc('app_config');
    const docSnap = await docRef.get();
    
    if (!docSnap.exists) {
        console.error("Error: settings/app_config document does not exist in Firestore.");
        process.exit(1);
    }
    
    const updateUrl = process.argv[2];
    
    if (!updateUrl) {
      console.error("Error: You must provide a download URL as the first argument.");
      process.exit(1);
    }

    await docRef.update({
      latest_version: cleanVersion,
      update_url: updateUrl,
      force_update: true,
      minimum_required_version: cleanVersion
    });

    console.log(`Successfully updated Firestore app_config for FORCE UPDATE!`);
    console.log(`   - latest_version: ${cleanVersion}`);
    console.log(`   - minimum_required_version: ${cleanVersion}`);
    console.log(`   - force_update: true`);
    console.log(`   - update_url: ${updateUrl}`);

    process.exit(0);
  } catch (error) {
    console.error("Error updating Firestore:", error);
    process.exit(1);
  }
}

run();
