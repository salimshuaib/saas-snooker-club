import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';

enum CreditTransactionType { game, quickSale, manual }

enum CreditTransactionStatus { pending, partiallyPaid, paid }

class PlayerProfile {
  final String id;
  final String name;
  final String? mobileNumber;
  final double outstandingAmount;
  final int totalPendingTransactions;
  final DateTime lastTransactionDate;
  final DateTime? lastPaymentDate;

  const PlayerProfile({
    required this.id,
    required this.name,
    this.mobileNumber,
    this.outstandingAmount = 0.0,
    this.totalPendingTransactions = 0,
    required this.lastTransactionDate,
    this.lastPaymentDate,
  });

  PlayerProfile copyWith({
    String? id,
    String? name,
    String? mobileNumber,
    double? outstandingAmount,
    int? totalPendingTransactions,
    DateTime? lastTransactionDate,
    DateTime? lastPaymentDate,
  }) {
    return PlayerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      totalPendingTransactions:
          totalPendingTransactions ?? this.totalPendingTransactions,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mobileNumber': mobileNumber,
      'outstandingAmount': outstandingAmount,
      'totalPendingTransactions': totalPendingTransactions,
      'lastTransactionDate': Timestamp.fromDate(lastTransactionDate),
      'lastPaymentDate': lastPaymentDate != null
          ? Timestamp.fromDate(lastPaymentDate!)
          : null,
    };
  }

  factory PlayerProfile.fromMap(String id, Map<String, dynamic> map) {
    return PlayerProfile(
      id: id,
      name: map['name'] as String? ?? '',
      mobileNumber: map['mobileNumber'] as String?,
      outstandingAmount: (map['outstandingAmount'] as num?)?.toDouble() ?? 0.0,
      totalPendingTransactions:
          (map['totalPendingTransactions'] as num?)?.toInt() ?? 0,
      lastTransactionDate:
          (map['lastTransactionDate'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      lastPaymentDate: (map['lastPaymentDate'] as Timestamp?)?.toDate(),
    );
  }
}

class CreditTransaction {
  final String id;
  final String customerId;
  final CreditTransactionType type;
  final String referenceId; // GameSession ID or QuickSale ID
  final double amount;
  final double paidAmount;
  final double remainingAmount;
  final CreditTransactionStatus status;
  final DateTime date;
  final PaymentMethod? paymentMethod;
  final String? employeeName;

  // Minimal info for display without needing to fetch the referenced doc immediately
  final String title;
  final String? subtitle;

  const CreditTransaction({
    required this.id,
    required this.customerId,
    required this.type,
    required this.referenceId,
    required this.amount,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    required this.status,
    required this.date,
    this.paymentMethod,
    this.employeeName,
    required this.title,
    this.subtitle,
  });

  CreditTransaction copyWith({
    String? id,
    String? customerId,
    CreditTransactionType? type,
    String? referenceId,
    double? amount,
    double? paidAmount,
    double? remainingAmount,
    CreditTransactionStatus? status,
    DateTime? date,
    PaymentMethod? paymentMethod,
    String? employeeName,
    String? title,
    String? subtitle,
  }) {
    return CreditTransaction(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      status: status ?? this.status,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      employeeName: employeeName ?? this.employeeName,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'type': type.name,
      'referenceId': referenceId,
      'amount': amount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'status': status.name,
      'date': Timestamp.fromDate(date),
      'paymentMethod': paymentMethod?.name,
      'employeeName': employeeName,
      'title': title,
      'subtitle': subtitle,
    };
  }

  factory CreditTransaction.fromMap(String id, Map<String, dynamic> map) {
    return CreditTransaction(
      id: id,
      customerId: map['customerId'] as String? ?? '',
      type: CreditTransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CreditTransactionType.game,
      ),
      referenceId: map['referenceId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount:
          (map['remainingAmount'] as num?)?.toDouble() ??
          (map['amount'] as num?)?.toDouble() ??
          0.0,
      status: CreditTransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CreditTransactionStatus.pending,
      ),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentMethod: map['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == map['paymentMethod'],
              orElse: () => PaymentMethod.cash,
            )
          : null,
      employeeName: map['employeeName'] as String?,
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String?,
    );
  }
}

class PaymentHistory {
  final String id;
  final String customerId;
  final double amountPaid;
  final double remainingBalance;
  final PaymentMethod paymentMethod;
  final String employeeName;
  final DateTime date;

  const PaymentHistory({
    required this.id,
    required this.customerId,
    required this.amountPaid,
    required this.remainingBalance,
    required this.paymentMethod,
    required this.employeeName,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'amountPaid': amountPaid,
      'remainingBalance': remainingBalance,
      'paymentMethod': paymentMethod.name,
      'employeeName': employeeName,
      'date': Timestamp.fromDate(date),
    };
  }

  factory PaymentHistory.fromMap(String id, Map<String, dynamic> map) {
    return PaymentHistory(
      id: id,
      customerId: map['customerId'] as String? ?? '',
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      remainingBalance: (map['remainingBalance'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      employeeName: map['employeeName'] as String? ?? 'Admin',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
