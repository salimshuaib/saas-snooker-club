const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

const defaultTables = [
  { id: 'snooker_1', name: 'Snooker Table 1', type: 'snooker', status: 'available' },
  { id: 'snooker_2', name: 'Snooker Table 2', type: 'snooker', status: 'available' },
  { id: 'snooker_3', name: 'Snooker Table 3', type: 'snooker', status: 'available' },
  { id: 'indian_pool_1', name: 'Indian Pool Table 1', type: 'indianPool', status: 'available' },
  { id: 'indian_pool_2', name: 'Indian Pool Table 2', type: 'indianPool', status: 'available' },
  { id: 'american_pool_1', name: 'American Pool Table 1', type: 'americanPool', status: 'available' },
];

async function seed() {
    const clubId = 'ObnNL7TGuMA8hr1JhBCZ';
    const clubRef = db.collection('clubs').doc(clubId);

    const batch = db.batch();

    // Tables
    for (const table of defaultTables) {
        const tableRef = clubRef.collection('tables').doc(table.id);
        const doc = await tableRef.get();
        if (!doc.exists) {
            batch.set(tableRef, { ...table, clubId });
            console.log(`Seeding table ${table.id}`);
        }
    }

    // Settings
    const settingsRef = clubRef.collection('settings').doc('club_config');
    const settingsDoc = await settingsRef.get();
    if (!settingsDoc.exists) {
        batch.set(settingsRef, {
            business: {
                clubName: 'Sharma Billiards',
                address: 'Main Club Complex, City Center',
                contactNumber: '+91 9876543210'
            },
            game: {
                frameGracePeriodMinutes: 20,
                enableOvertimeBilling: true,
                allowPauseResume: true,
                maxPlayersPerTeam: 3,
                defaultMatchType: 'friendly'
            },
            inventory: {
                defaultInitialQuantity: 10,
                enableLowStockAlerts: true,
                lowStockThreshold: 5
            },
            pricing: {
                snookerPerMinute: 4.5,
                snookerHalfHour: 135.0,
                snookerOneHour: 270.0,
                indianPoolPerFrame: 40.0,
                indianPoolPerMinute: 3.5,
                indianPoolHalfHour: 100.0,
                indianPoolOneHour: 210.0,
                americanPoolPerFrame: 60.0,
                americanPoolPerMinute: 4.0,
                americanPoolHalfHour: 150.0,
                americanPoolOneHour: 240.0,
                snookerRacePerMinute: 3.0,
                indianPoolRacePerMinute: 3.0,
                americanPoolRacePerMinute: 4.0,
                snookerRummyPerMinute: 4.0
            }
        });
        console.log('Seeding settings');
    }

    await batch.commit();
    console.log('Done.');
}
seed();
