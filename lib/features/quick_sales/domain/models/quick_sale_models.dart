import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/core/models/audit_log.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';

class QuickSale {
  final String? createdByUserId;
  final String? createdByName;
  final String? updatedByUserId;
  final String? updatedByName;
  final String id;
  final String? customerName;
  final String? customerId;
  final List<GameOrder> items;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final String? paymentStatus;
  final double? paidAmount;
  final double? remainingAmount;
  final String employeeName;
  final DateTime date;
  final List<AuditLog> auditLogs;

  const QuickSale({
    this.createdByUserId,
    this.createdByName,
    this.updatedByUserId,
    this.updatedByName,
    required this.id,
    this.customerName,
    this.customerId,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    this.paymentStatus,
    this.paidAmount,
    this.remainingAmount,
    required this.employeeName,
    required this.date,
    this.auditLogs = const [],
  });

  QuickSale copyWith({
    String? createdByUserId,
    String? createdByName,
    String? updatedByUserId,
    String? updatedByName,
    String? id,
    String? customerName,
    String? customerId,
    List<GameOrder>? items,
    double? totalAmount,
    PaymentMethod? paymentMethod,
    String? paymentStatus,
    double? paidAmount,
    double? remainingAmount,
    String? employeeName,
    DateTime? date,
    List<AuditLog>? auditLogs,
  }) {
    return QuickSale(
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByName: createdByName ?? this.createdByName,
      updatedByUserId: updatedByUserId ?? this.updatedByUserId,
      updatedByName: updatedByName ?? this.updatedByName,
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      employeeName: employeeName ?? this.employeeName,
      date: date ?? this.date,
      auditLogs: auditLogs ?? this.auditLogs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdByUserId': createdByUserId,
      'createdByName': createdByName,
      'updatedByUserId': updatedByUserId,
      'updatedByName': updatedByName,
      'customerName': customerName,
      'customerId': customerId,
      'items': items.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod.name,
      'paymentStatus': paymentStatus,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'employeeName': employeeName,
      'date': Timestamp.fromDate(date),
      'auditLogs': auditLogs.map((a) => a.toMap()).toList(),
    };
  }

  factory QuickSale.fromMap(String id, Map<String, dynamic> map) {
    return QuickSale(
      createdByUserId: map['createdByUserId'] as String?,
      createdByName: map['createdByName'] as String?,
      updatedByUserId: map['updatedByUserId'] as String?,
      updatedByName: map['updatedByName'] as String?,
      id: id,
      customerName: map['customerName'] as String?,
      customerId: map['customerId'] as String?,
      items:
          (map['items'] as List<dynamic>?)
              ?.map((item) => GameOrder.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.values.firstWhere(
        (p) => p.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      paymentStatus: map['paymentStatus'] as String?,
      paidAmount: (map['paidAmount'] as num?)?.toDouble(),
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble(),
      employeeName: map['employeeName'] as String? ?? 'Admin',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      auditLogs:
          (map['auditLogs'] as List<dynamic>?)
              ?.map((a) => AuditLog.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
