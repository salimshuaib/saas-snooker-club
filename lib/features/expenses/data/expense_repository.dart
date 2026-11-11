import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/config/app_environment.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:snooker_club/core/models/audit_log.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/features/expenses/domain/models/expense_models.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore;
  final Ref? _ref;
  final String? clubId;

  ExpenseRepository({FirebaseFirestore? firestore, Ref? ref, this.clubId})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _ref = ref;

  StaffMember? get currentStaff {
    try {
      return _ref?.read(currentStaffProvider).value;
    } catch (_) {
      return null;
    }
  }

  String get currentUserName {
    try {
      final staff = currentStaff;
      final club = _ref?.read(clubProfileProvider).value;
      if (staff != null) {
        if (staff.role == StaffRole.owner &&
            club != null &&
            club.ownerName.isNotEmpty) {
          return club.ownerName;
        }
        if (staff.name.isNotEmpty &&
            staff.name != 'Admin' &&
            staff.name != 'Club Owner') {
          return staff.name;
        }
      }
      if (club != null && club.ownerName.isNotEmpty) return club.ownerName;
    } catch (_) {}
    return 'Admin';
  }

  String get currentUserId {
    final staff = currentStaff;
    if (staff != null) return staff.id;
    try {
      final club = _ref?.read(clubProfileProvider).value;
      if (club != null) return club.ownerUid;
    } catch (_) {}
    return 'Unknown';
  }

  DocumentReference get _clubRef {
    if (clubId == null) {
      throw Exception('clubId cannot be null for ExpenseRepository');
    }
    return _firestore.collection(FirebaseConstants.clubsCollection).doc(clubId);
  }

  CollectionReference get _expensesRef =>
      _clubRef.collection(FirebaseConstants.expensesCollection);

  Expense _enrichWithStaff(Expense expense, bool isCreate) {
    final staff = currentStaff;
    if (staff == null) return expense;

    if (isCreate) {
      return expense.copyWith(
        createdByUserId: staff.id,
        createdByName: staff.name,
      );
    } else {
      return expense.copyWith(
        updatedByUserId: staff.id,
        updatedByName: staff.name,
      );
    }
  }

  /// Create a new expense entry
  Future<String> createExpense(Expense expense) async {
    if (AppConfig.guardWrite('ExpenseRepository.createExpense')) {
      return expense.id;
    }

    final enriched = _enrichWithStaff(expense, true);
    final docRef = expense.id.isNotEmpty
        ? _expensesRef.doc(expense.id)
        : _expensesRef.doc();

    final toSave = enriched.copyWith(id: docRef.id);
    await docRef.set(toSave.toMap());
    debugPrint('[ExpenseRepository] Created expense ${docRef.id} - ${toSave.title}');
    return docRef.id;
  }

  /// Update an existing expense
  Future<void> updateExpense(Expense expense, {String? reason}) async {
    if (AppConfig.guardWrite('ExpenseRepository.updateExpense')) return;

    final enriched = _enrichWithStaff(expense, false);
    final log = AuditLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      editedBy: currentUserName,
      timestamp: DateTime.now(),
      field: 'expense',
      previousValue: '',
      newValue: reason ?? 'Expense updated',
      recordId: expense.id,
    );

    final updatedLogs = List<AuditLog>.from(enriched.auditLogs)..add(log);
    final toSave = enriched.copyWith(auditLogs: updatedLogs);

    await _expensesRef.doc(expense.id).set(toSave.toMap(), SetOptions(merge: true));
    debugPrint('[ExpenseRepository] Updated expense ${expense.id}');
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId, {String? reason}) async {
    if (AppConfig.guardWrite('ExpenseRepository.deleteExpense')) return;

    // Record audit log before deleting
    final doc = await _expensesRef.doc(expenseId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final title = data['title'] as String? ?? 'Expense';

      try {
        await _clubRef.collection('audit_logs').add({
          'type': 'deletion',
          'category': 'expense',
          'expenseId': expenseId,
          'title': title,
          'amount': amount,
          'reason': reason ?? 'Expense deleted',
          'performedBy': currentUserName,
          'performedByUserId': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('[ExpenseRepository] Failed to log deletion audit: $e');
      }
    }

    await _expensesRef.doc(expenseId).delete();
    debugPrint('[ExpenseRepository] Deleted expense $expenseId');
  }

  /// Mark business credit as paid (settled)
  Future<void> markCreditAsPaid(
    String expenseId, {
    required PaymentMethod settledVia,
    DateTime? settledDate,
  }) async {
    if (AppConfig.guardWrite('ExpenseRepository.markCreditAsPaid')) return;

    final now = settledDate ?? DateTime.now();
    final log = AuditLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      editedBy: currentUserName,
      timestamp: now,
      field: 'paymentStatus',
      previousValue: 'credit',
      newValue: 'paid (${settledVia.name})',
      recordId: expenseId,
    );

    await _expensesRef.doc(expenseId).set({
      'paymentStatus': 'paid',
      'settledPaymentMethod': settledVia.name,
      'creditPaidDate': Timestamp.fromDate(now),
      'updatedByUserId': currentUserId,
      'updatedByName': currentUserName,
      'auditLogs': FieldValue.arrayUnion([log.toMap()]),
    }, SetOptions(merge: true));
    debugPrint('[ExpenseRepository] Marked expense credit $expenseId as paid via ${settledVia.name}');
  }

  /// Watch expenses for a specific single date
  Stream<List<Expense>> watchExpenses(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _expensesRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return Expense.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// Watch expenses within a date range (for analytics / filters)
  Stream<List<Expense>> watchExpensesByDateRange(DateTime start, DateTime end) {
    return _expensesRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return Expense.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// Watch all business credit transactions (unsettled or all)
  Stream<List<Expense>> watchBusinessCreditExpenses({bool onlyUnsettled = false}) {
    return _expensesRef
        .where('paymentMethod', isEqualTo: PaymentMethod.credit.name)
        .snapshots()
        .map((snapshot) {
      var list = snapshot.docs.map((doc) {
        return Expense.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      if (onlyUnsettled) {
        list = list.where((e) => e.isOutstandingCredit).toList();
      }
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// Watch all expenses
  Stream<List<Expense>> watchAllExpenses({int limit = 100}) {
    return _expensesRef
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Expense.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
