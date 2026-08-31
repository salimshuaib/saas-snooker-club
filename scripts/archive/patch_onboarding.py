import re

with open('lib/features/settings/data/settings_repository.dart', 'r', encoding='utf-8') as f:
    content = f.read()

new_func = '''Future<void> completeOnboarding() async {
    if (AppConfig.guardWrite('SettingsRepository.completeOnboarding')) return;
    if (clubId == null) throw Exception('clubId cannot be null');
    final ref = _db.collection(FirebaseConstants.clubsCollection).doc(clubId);
    
    // Auto-generate slug from clubName during onboarding
    final snapshot = await ref.get();
    String? generatedSlug;
    if (snapshot.exists) {
      final name = snapshot.data()?['clubName'] as String?;
      if (name != null && name.isNotEmpty) {
        generatedSlug = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-').replaceAll(RegExp(r'-+'), '-');
      }
    }
    generatedSlug ??= 'club-\';

    // Update root document
    await ref.update({
      'isOnboarded': true,
      'agreedToTermsAt': FieldValue.serverTimestamp(),
      'agreedByUid': FirebaseAuth.instance.currentUser?.uid,
      'agreementVersion': 'v1.0',
      'slug': generatedSlug,
    });

    // Also update settings/app_config document
    await _settingsDoc.set({
      'business': {
        'slug': generatedSlug,
      }
    }, SetOptions(merge: true));
  }'''

content = re.sub(r'Future<void> completeOnboarding\(\) async \{[\s\S]*?\}\n', new_func + '\n', content)

with open('lib/features/settings/data/settings_repository.dart', 'w', encoding='utf-8') as f:
    f.write(content)
