import os

files = [
    'lib/features/games/data/games_repository.dart',
    'lib/features/quick_sales/data/quick_sales_repository.dart'
]

for filepath in files:
    with open(filepath, 'r', encoding='utf-8') as f:
        text = f.read()
    
    if "GameSession _enrichWithStaff" in text:
        old_enrich = """  GameSession _enrichWithStaff(GameSession session, bool isCreate) {
    final staff = currentStaff;
    if (staff == null) return session;

    if (isCreate) {
      return session.copyWith(
        createdByUserId: staff.id,
        createdByName: staff.name,
      );
    } else {
      return session.copyWith(
        lastUpdatedByUserId: staff.id,
        lastUpdatedByName: staff.name,
      );
    }
  }"""
        new_enrich = """  GameSession _enrichWithStaff(GameSession session, bool isCreate) {
    if (isCreate) {
      return session.copyWith(
        createdByUserId: currentUserId,
        createdByName: currentUserName,
      );
    } else {
      return session.copyWith(
        lastUpdatedByUserId: currentUserId,
        lastUpdatedByName: currentUserName,
      );
    }
  }"""
        text = text.replace(old_enrich, new_enrich)
    
    if "QuickSale _enrichWithStaff" in text:
        old_enrich = """  QuickSale _enrichWithStaff(QuickSale sale, bool isCreate) {
    final staff = currentStaff;
    if (staff == null) return sale;

    if (isCreate) {
      return sale.copyWith(
        createdByUserId: staff.id,
        createdByName: staff.name,
      );
    } else {
      return sale.copyWith(
        lastUpdatedByUserId: staff.id,
        lastUpdatedByName: staff.name,
      );
    }
  }"""
        new_enrich = """  QuickSale _enrichWithStaff(QuickSale sale, bool isCreate) {
    if (isCreate) {
      return sale.copyWith(
        createdByUserId: currentUserId,
        createdByName: currentUserName,
      );
    } else {
      return sale.copyWith(
        lastUpdatedByUserId: currentUserId,
        lastUpdatedByName: currentUserName,
      );
    }
  }"""
        text = text.replace(old_enrich, new_enrich)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(text)
