import re

with open('C:/Users/Shuai/Desktop/booking_website/app.js', 'r', encoding='utf-8') as f:
    content = f.read()

replacement = '''async function loadClubInfo() {
    try {
        let doc = await db.collection('clubs').doc(clubId).get();
        if (!doc.exists) {
            // It might be a slug! Let's query by slug.
            const slugQuery = await db.collection('clubs').where('slug', '==', clubId).limit(1).get();
            if (!slugQuery.empty) {
                doc = slugQuery.docs[0];
                clubId = doc.id; // Update global clubId for subsequent queries
            } else {
                if(window.showError) window.showError("Club not found.");
                eBookingFlow.style.display = 'none';
                return;
            }
        }'''

content = re.sub(r'async function loadClubInfo\(\) \{\n    try \{\n        const doc = await db\.collection\(\'clubs\'\)\.doc\(clubId\)\.get\(\);\n        if \(\!doc\.exists\) \{\n            if\(window\.showError\) window\.showError\("Club not found\."\);\n            eBookingFlow\.style\.display = \'none\';\n            return;\n        \}', replacement, content)

with open('C:/Users/Shuai/Desktop/booking_website/app.js', 'w', encoding='utf-8') as f:
    f.write(content)
