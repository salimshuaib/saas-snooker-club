import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/core/models/audit_log.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';

class Expense {
  final String id;
  final String title;
  final String category;
  final double amount;
  final PaymentMethod paymentMethod; // cash, upi, credit
  final String paymentStatus; // 'paid', 'credit'
  final DateTime date;
  final String? description;
  final DateTime? creditPaidDate;
  final PaymentMethod? settledPaymentMethod; // when credit is paid: cash or upi
  final String? floorId;
  final String? floorName;
  final String? createdByUserId;
  final String? createdByName;
  final String? updatedByUserId;
  final String? updatedByName;
  final List<AuditLog> auditLogs;

  const Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    this.paymentStatus = 'paid',
    required this.date,
    this.description,
    this.creditPaidDate,
    this.settledPaymentMethod,
    this.floorId,
    this.floorName,
    this.createdByUserId,
    this.createdByName,
    this.updatedByUserId,
    this.updatedByName,
    this.auditLogs = const [],
  });

  bool get isCredit => paymentMethod == PaymentMethod.credit;
  bool get isSettled => paymentStatus == 'paid';
  bool get isOutstandingCredit => isCredit && paymentStatus != 'paid';

  Expense copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    PaymentMethod? paymentMethod,
    String? paymentStatus,
    DateTime? date,
    String? description,
    DateTime? creditPaidDate,
    PaymentMethod? settledPaymentMethod,
    String? floorId,
    String? floorName,
    String? createdByUserId,
    String? createdByName,
    String? updatedByUserId,
    String? updatedByName,
    List<AuditLog>? auditLogs,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      date: date ?? this.date,
      description: description ?? this.description,
      creditPaidDate: creditPaidDate ?? this.creditPaidDate,
      settledPaymentMethod: settledPaymentMethod ?? this.settledPaymentMethod,
      floorId: floorId ?? this.floorId,
      floorName: floorName ?? this.floorName,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByName: createdByName ?? this.createdByName,
      updatedByUserId: updatedByUserId ?? this.updatedByUserId,
      updatedByName: updatedByName ?? this.updatedByName,
      auditLogs: auditLogs ?? this.auditLogs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'paymentMethod': paymentMethod.name,
      'paymentStatus': paymentStatus,
      'date': Timestamp.fromDate(date),
      'description': description,
      'creditPaidDate':
          creditPaidDate != null ? Timestamp.fromDate(creditPaidDate!) : null,
      'settledPaymentMethod': settledPaymentMethod?.name,
      'floorId': floorId,
      'floorName': floorName,
      'createdByUserId': createdByUserId,
      'createdByName': createdByName,
      'updatedByUserId': updatedByUserId,
      'updatedByName': updatedByName,
      'auditLogs': auditLogs.map((e) => e.toMap()).toList(),
    };
  }

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    PaymentMethod pm = PaymentMethod.cash;
    if (map['paymentMethod'] != null) {
      pm = PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      );
    }

    PaymentMethod? settledPm;
    if (map['settledPaymentMethod'] != null) {
      settledPm = PaymentMethod.values.firstWhere(
        (e) => e.name == map['settledPaymentMethod'],
        orElse: () => PaymentMethod.cash,
      );
    }

    DateTime dt = DateTime.now();
    if (map['date'] is Timestamp) {
      dt = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      dt = DateTime.tryParse(map['date'] as String) ?? dt;
    }

    DateTime? cpDate;
    if (map['creditPaidDate'] is Timestamp) {
      cpDate = (map['creditPaidDate'] as Timestamp).toDate();
    }

    return Expense(
      id: id,
      title: map['title'] as String? ?? 'Expense',
      category: map['category'] as String? ?? 'Other',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: pm,
      paymentStatus: map['paymentStatus'] as String? ??
          (pm == PaymentMethod.credit ? 'credit' : 'paid'),
      date: dt,
      description: map['description'] as String?,
      creditPaidDate: cpDate,
      settledPaymentMethod: settledPm,
      floorId: map['floorId'] as String?,
      floorName: map['floorName'] as String?,
      createdByUserId: map['createdByUserId'] as String?,
      createdByName: map['createdByName'] as String?,
      updatedByUserId: map['updatedByUserId'] as String?,
      updatedByName: map['updatedByName'] as String?,
      auditLogs: (map['auditLogs'] as List<dynamic>?)
              ?.map((e) => AuditLog.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
