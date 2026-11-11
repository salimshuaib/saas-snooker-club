import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart';
import 'package:snooker_club/core/providers/printer_provider.dart';
import 'package:snooker_club/core/services/receipt_formatter.dart';
import 'package:snooker_club/features/settings/presentation/screens/printer_settings_screen.dart';

import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/settings/domain/models/settings_models.dart';

/// Data object containing everything needed to render a clean receipt
class ReceiptData {
  final String invoiceNumber;
  final String clubName;
  final String? clubAddress;
  final String? clubPhone;
  final String tableName;
  final String? customerName;
  final String? customerPhone;
  final DateTime date;
  final String paymentMethodLabel;
  final List<ReceiptLineItem> lineItems;
  final double subtotal;
  final double taxAmount;
  final double grandTotal;
  final double roundingAmount;
  final double amountDue;
  final bool isPaid;
  final bool isCredit;
  final bool isPartialPayment;
  final double? paidAmount;
  final double? remainingAmount;
  final Map<String, double>? paymentBreakdown;
  final double? prepaidAmount;
  final double? settlementAmount;

  const ReceiptData({
    required this.invoiceNumber,
    required this.clubName,
    this.clubAddress,
    this.clubPhone,
    required this.tableName,
    this.customerName,
    this.customerPhone,
    required this.date,
    required this.paymentMethodLabel,
    required this.lineItems,
    required this.subtotal,
    this.taxAmount = 0.0,
    required this.grandTotal,
    this.roundingAmount = 0.0,
    required this.amountDue,
    this.isPaid = true,
    this.isCredit = false,
    this.isPartialPayment = false,
    this.paidAmount,
    this.remainingAmount,
    this.paymentBreakdown,
    this.prepaidAmount,
    this.settlementAmount,
  });

  factory ReceiptData.fromGameSession(
    GameSession session, {
    required String clubName,
    String? clubAddress,
    String? clubPhone,
    String? customerPhone,
    List<TableModel>? tables,
    PricingSettings? pricingSettings,
  }) {
    final cleanId = session.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final String invoiceId;
    if (cleanId.contains('COMBINED') || cleanId.contains('MULTI')) {
      invoiceId = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    } else {
      invoiceId = 'INV-${cleanId.length > 6 ? cleanId.substring(cleanId.length - 6) : cleanId}';
    }
    
    final List<ReceiptLineItem> items = [];

    // Main Table Time Charge
    final double baseGame = session.baseGameCharge ?? session.gameCharge ?? 0.0;
    final int minutes = (session.activeSeconds / 60).ceil();
    final String durationLabel = minutes >= 60
        ? '${(minutes / 60).toStringAsFixed(1)}h'
        : '${minutes}m';

    if (baseGame > 0) {
      if (session.tableName.contains(',')) {
        final tableNames = session.tableName
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();

        final Map<int, double> tableAmounts = {};
        double allocated = 0.0;

        for (int i = 0; i < tableNames.length; i++) {
          final name = tableNames[i];
          final match = tables
              ?.where((t) => t.name.trim().toLowerCase() == name.toLowerCase())
              .firstOrNull;
          if (match != null) {
            if (match.type == TableType.americanPool ||
                name.toLowerCase().contains('pool')) {
              final p = match.billingOptions?['perFrame']?.price ??
                  pricingSettings?.americanPoolPerFrame;
              if (p != null && p > 0 && p < baseGame) {
                tableAmounts[i] = p;
                allocated += p;
              }
            } else if (match.type == TableType.indianPool) {
              final p = match.billingOptions?['perFrame']?.price ??
                  pricingSettings?.indianPoolPerFrame;
              if (p != null && p > 0 && p < baseGame) {
                tableAmounts[i] = p;
                allocated += p;
              }
            }
          } else if (name.toLowerCase().contains('pool')) {
            final p = pricingSettings?.americanPoolPerFrame ?? 60.0;
            if (p > 0 && p < baseGame) {
              tableAmounts[i] = p;
              allocated += p;
            }
          }
        }

        final unallocated = List.generate(tableNames.length, (i) => i)
            .where((i) => !tableAmounts.containsKey(i))
            .toList();

        if (unallocated.isNotEmpty) {
          final remaining = (baseGame - allocated).clamp(0.0, double.infinity);
          final perTable = remaining / unallocated.length;
          for (final idx in unallocated) {
            tableAmounts[idx] = perTable;
          }
        }

        for (int i = 0; i < tableNames.length; i++) {
          final name = tableNames[i];
          final amt = tableAmounts[i] ?? (baseGame / tableNames.length);
          items.add(ReceiptLineItem(
            description: name,
            amount: amt,
          ));
        }
      } else {
        items.add(ReceiptLineItem(
          description: '${session.tableName} time ($durationLabel)',
          amount: baseGame,
        ));
      }
    }

    // Overtime if any
    if ((session.overtimeCharge ?? 0) > 0) {
      items.add(ReceiptLineItem(
        description: 'Overtime (${session.overtimeMinutes ?? 0}m)',
        amount: session.overtimeCharge!,
      ));
    }

    // Orders if any
    for (final order in session.orders) {
      items.add(ReceiptLineItem(
        description: '${order.productName} (x${order.quantity})',
        amount: order.total,
      ));
    }

    // Manual Game Charges if any
    for (final mg in session.manualGameCharges) {
      final nameClean = mg.tableName.startsWith('Manual:')
          ? mg.tableName.substring(7).trim()
          : mg.tableName;
      final discountSuffix = mg.appliedDiscountAmount > 0
          ? ' (disc -\u20B9${mg.appliedDiscountAmount.toStringAsFixed(0)})'
          : '';
      items.add(ReceiptLineItem(
        description: '$nameClean$discountSuffix',
        amount: mg.finalAmount,
      ));
    }

    final manualGameDiscounts = session.manualGameCharges.fold<double>(
      0.0,
      (sum, charge) => sum + charge.appliedDiscountAmount,
    );
    final totalDiscounts =
        (session.discountAmount ?? 0.0) +
        (session.currentGameDiscountAmount ?? 0.0) +
        manualGameDiscounts;
    if ((session.discountAmount ?? 0.0) > 0) {
      items.add(ReceiptLineItem(
        description: 'Bill discount',
        amount: -(session.discountAmount ?? 0.0),
      ));
    }
    if ((session.currentGameDiscountAmount ?? 0.0) > 0) {
      items.add(ReceiptLineItem(
        description: 'Current game discount',
        amount: -(session.currentGameDiscountAmount ?? 0.0),
      ));
    }

    final double prepaid = (session.isPrepaid && session.prepaidAmount > 0)
        ? session.prepaidAmount
        : 0.0;
    if (prepaid > 0) {
      items.add(ReceiptLineItem(
        description: 'Prepaid advance paid',
        amount: -prepaid,
      ));
    }

    final double sub = items.fold(0.0, (sum, i) => sum + i.amount);
    final double grand = ((session.grandTotal ?? (sub + totalDiscounts)) -
            totalDiscounts)
        .clamp(0.0, double.infinity)
        .toDouble();
    final double finalAmt = session.finalAmount ?? session.roundedAmount ?? grand;
    final double roundDiff = finalAmt - grand;

    final double effectiveDue = session.status == TableStatus.pendingBill
        ? (finalAmt - prepaid).clamp(0.0, double.infinity).toDouble()
        : (prepaid > 0
            ? (session.settlementAmountPaid ?? (finalAmt - prepaid))
                .clamp(0.0, double.infinity)
                .toDouble()
            : finalAmt);

    String? payerName = session.paidBy ?? session.pendingBillCustomerName;
    if (payerName == null || payerName.isEmpty) {
      if (session.teamA.isNotEmpty) {
        payerName = session.teamA.join(', ');
      }
    }

    String payLabel = session.paymentMethod?.displayName ?? 'Paid';
    if (session.playerPaymentSplits != null && session.playerPaymentSplits!.isNotEmpty) {
      final List<String> methods = [];
      for (final splitMap in session.playerPaymentSplits!.values) {
        for (final m in splitMap.keys) {
          if (!methods.contains(m.displayName)) methods.add(m.displayName);
        }
      }
      if (methods.isNotEmpty) payLabel = methods.join(', ');
    } else if (session.isPrepaid && session.prepaidPaymentMethod != null) {
      payLabel = '${session.prepaidPaymentMethod!.displayName} (Prepaid)';
    }

    final Map<String, double> breakdown = {};
    double totalCreditSplit = 0.0;
    double totalPaidSplit = 0.0;

    void addSplits(Map<String, Map<PaymentMethod, double>>? splits) {
      if (splits == null) return;
      for (final playerMap in splits.values) {
        for (final entry in playerMap.entries) {
          final name = entry.key.displayName;
          breakdown[name] = (breakdown[name] ?? 0.0) + entry.value;
          if (entry.key == PaymentMethod.credit) {
            totalCreditSplit += entry.value;
          } else {
            totalPaidSplit += entry.value;
          }
        }
      }
    }

    addSplits(session.playerPaymentSplits);
    addSplits(session.settlementPaymentSplits);

    if (session.isPrepaid && session.prepaidAmount > 0) {
      final pMethodName = session.prepaidPaymentMethod?.displayName ?? 'Advance';
      final label = '$pMethodName (Prepaid)';
      breakdown[label] = (breakdown[label] ?? 0.0) + session.prepaidAmount;
      if (session.prepaidPaymentMethod == PaymentMethod.credit) {
        totalCreditSplit += session.prepaidAmount;
      } else {
        totalPaidSplit += session.prepaidAmount;
      }
    }

    if (breakdown.isEmpty && session.paymentMethod != null) {
      final name = session.paymentMethod!.displayName;
      breakdown[name] = effectiveDue;
      if (session.paymentMethod == PaymentMethod.credit) {
        totalCreditSplit = effectiveDue;
      } else {
        totalPaidSplit = effectiveDue;
      }
    }

    double calcRemaining = 0.0;
    if (session.remainingAmount != null && session.remainingAmount! > 0) {
      calcRemaining = session.remainingAmount!;
    } else if (totalCreditSplit > 0) {
      calcRemaining = totalCreditSplit;
    } else if (session.paymentMethod == PaymentMethod.credit) {
      calcRemaining = effectiveDue;
    }

    double calcPaid = 0.0;
    if (session.paidAmount != null && session.paidAmount! > 0) {
      calcPaid = session.paidAmount!;
    } else if (totalPaidSplit > 0) {
      calcPaid = totalPaidSplit;
    } else if (session.paymentMethod != null && session.paymentMethod != PaymentMethod.credit) {
      calcPaid = effectiveDue;
    } else if (calcRemaining > 0 && effectiveDue > calcRemaining) {
      calcPaid = (effectiveDue - calcRemaining).clamp(0.0, double.infinity);
    }

    final bool isStatusPartiallyPaid = session.paymentStatus != null &&
        session.paymentStatus!.toLowerCase().contains('partially paid');
    final bool isStatusOutstanding = session.paymentStatus != null &&
        session.paymentStatus!.toLowerCase().contains('outstanding');

    final bool hasCreditInPayLabel = payLabel.toLowerCase().contains('credit');
    final bool hasOtherInPayLabel = payLabel.toLowerCase().contains('cash') ||
        payLabel.toLowerCase().contains('upi') ||
        payLabel.toLowerCase().contains('card');

    final bool isPartial = isStatusPartiallyPaid ||
        (hasCreditInPayLabel && hasOtherInPayLabel) ||
        (calcPaid > 0.01 && calcRemaining > 0.01) ||
        (breakdown.containsKey('Credit') && breakdown.entries.any((e) => e.key != 'Credit' && e.value > 0.01));

    final bool isCredit = !isPartial &&
        (session.paymentMethod == PaymentMethod.credit ||
            isStatusOutstanding ||
            (calcRemaining > 0.01 && calcPaid <= 0.01) ||
            payLabel.trim().toLowerCase() == 'credit');

    final bool isPaid = !isPartial && !isCredit && session.status != TableStatus.pendingBill;

    return ReceiptData(
      invoiceNumber: invoiceId,
      clubName: clubName,
      clubAddress: clubAddress,
      clubPhone: clubPhone,
      tableName: session.tableName,
      customerName: payerName,
      customerPhone: customerPhone,
      date: session.endTime ?? DateTime.now(),
      paymentMethodLabel: payLabel,
      lineItems: items,
      subtotal: sub,
      grandTotal: grand,
      roundingAmount: roundDiff,
      amountDue: effectiveDue,
      isPaid: isPaid,
      isCredit: isCredit,
      isPartialPayment: isPartial,
      paidAmount: isPartial ? calcPaid : null,
      remainingAmount: (isPartial || isCredit) ? (calcRemaining > 0 ? calcRemaining : effectiveDue) : null,
      paymentBreakdown: breakdown.isNotEmpty ? breakdown : null,
      prepaidAmount: prepaid > 0 ? prepaid : null,
      settlementAmount: prepaid > 0 ? effectiveDue : null,
    );
  }

  factory ReceiptData.fromMultipleSessions(
    List<GameSession> sessions, {
    required String clubName,
    String? customerName,
    String? customerPhone,
    required String paymentMethodLabel,
  }) {
    final first = sessions.first;
    final invoiceId = 'INV-MULTI-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final tableNames = sessions.map((s) => s.tableName).toSet().join(', ');

    final List<ReceiptLineItem> items = [];
    double grand = 0.0;
    double finalAmt = 0.0;

    for (final s in sessions) {
      final double baseGame = s.baseGameCharge ?? s.gameCharge ?? 0.0;
      final int minutes = (s.activeSeconds / 60).ceil();
      final String durationLabel = minutes >= 60
          ? '${(minutes / 60).toStringAsFixed(1)}h'
          : '${minutes}m';

      items.add(ReceiptLineItem(
        description: '${s.tableName} time ($durationLabel)',
        amount: baseGame,
      ));

      if ((s.overtimeCharge ?? 0) > 0) {
        items.add(ReceiptLineItem(
          description: '${s.tableName} Overtime (${s.overtimeMinutes ?? 0}m)',
          amount: s.overtimeCharge!,
        ));
      }

      for (final order in s.orders) {
        items.add(ReceiptLineItem(
          description: '${order.productName} (x${order.quantity})',
          amount: order.total,
        ));
      }

      for (final mg in s.manualGameCharges) {
        items.add(ReceiptLineItem(
          description:
              'Manual: ${mg.tableName}${mg.appliedDiscountAmount > 0 ? ' (discount -\u20B9${mg.appliedDiscountAmount.toStringAsFixed(2)})' : ''}',
          amount: mg.finalAmount,
        ));
      }

      final discounts = (s.discountAmount ?? 0.0) +
          (s.currentGameDiscountAmount ?? 0.0) +
          s.manualGameCharges.fold<double>(
            0.0,
            (sum, charge) => sum + charge.appliedDiscountAmount,
          );
      if ((s.discountAmount ?? 0.0) > 0) {
        items.add(ReceiptLineItem(
          description: '${s.tableName} bill discount',
          amount: -(s.discountAmount ?? 0.0),
        ));
      }
      if ((s.currentGameDiscountAmount ?? 0.0) > 0) {
        items.add(ReceiptLineItem(
          description: '${s.tableName} game discount',
          amount: -(s.currentGameDiscountAmount ?? 0.0),
        ));
      }

      grand += ((s.grandTotal ?? (s.finalAmount ?? 0.0) + discounts) -
              discounts)
          .clamp(0.0, double.infinity)
          .toDouble();
      finalAmt += s.finalAmount ?? s.roundedAmount ?? s.grandTotal ?? 0.0;
    }

    final hasCredit = paymentMethodLabel.toLowerCase().contains('credit');
    final hasOther = paymentMethodLabel.toLowerCase().contains('cash') ||
        paymentMethodLabel.toLowerCase().contains('upi') ||
        paymentMethodLabel.toLowerCase().contains('card');

    final bool isPartial = hasCredit && hasOther;
    final bool isCredit = hasCredit && !hasOther;
    final bool isPaid = !hasCredit;

    final double effectiveGrand = grand > 0 ? grand : items.fold(0.0, (sum, i) => sum + i.amount);

    return ReceiptData(
      invoiceNumber: invoiceId,
      clubName: clubName,
      tableName: tableNames,
      customerName: customerName ?? first.pendingBillCustomerName ?? first.paidBy,
      customerPhone: customerPhone,
      date: DateTime.now(),
      paymentMethodLabel: paymentMethodLabel,
      lineItems: items,
      subtotal: items.fold(0.0, (sum, i) => sum + i.amount),
      grandTotal: effectiveGrand,
      roundingAmount: finalAmt - effectiveGrand,
      amountDue: finalAmt,
      isPaid: isPaid,
      isCredit: isCredit,
      isPartialPayment: isPartial,
      paidAmount: isPartial ? (finalAmt > 0 ? finalAmt / 2 : 0.0) : null,
      remainingAmount: (isPartial || isCredit) ? (finalAmt > 0 ? finalAmt / 2 : 0.0) : null,
    );
  }
}

class ReceiptLineItem {
  final String description;
  final double amount;

  const ReceiptLineItem({
    required this.description,
    required this.amount,
  });
}

/// Realistic thermal paper receipt widget
class ThermalReceiptWidget extends StatelessWidget {
  final ReceiptData receipt;

  const ThermalReceiptWidget({
    super.key,
    required this.receipt,
  });

  @override
  Widget build(BuildContext context) {
    final monoStyle = GoogleFonts.courierPrime(
      color: Colors.black87,
      fontSize: 13,
      height: 1.35,
    );

    final monoBold = GoogleFonts.courierPrime(
      color: Colors.black,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      height: 1.35,
    );

    final monoHeader = GoogleFonts.courierPrime(
      color: Colors.black,
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
    );

    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tax Invoice Header
          Center(
            child: Text(
              'Tax Invoice',
              style: monoStyle.copyWith(
                fontSize: 12,
                color: Colors.black54,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              receipt.clubName,
              style: monoHeader,
              textAlign: TextAlign.center,
            ),
          ),
          if (receipt.clubAddress != null && receipt.clubAddress!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Center(
              child: Text(
                receipt.clubAddress!,
                style: monoStyle.copyWith(fontSize: 10, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Dashed Divider
          _buildDashedLine(),
          const SizedBox(height: 10),

          // Metadata Key-Values
          _buildMultiLineRow('Invoice', receipt.invoiceNumber, monoStyle, monoBold),
          // In case of multiple games (comma in tableName), remove Table row after invoice number as requested
          if (!receipt.tableName.contains(',')) ...[
            const SizedBox(height: 4),
            _buildMultiLineRow('Table', receipt.tableName, monoStyle, monoBold),
          ],
          if (receipt.customerName != null && receipt.customerName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildMultiLineRow('Customer', receipt.customerName!, monoStyle, monoBold),
          ],
          if (receipt.customerPhone != null && receipt.customerPhone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildMultiLineRow('Phone', receipt.customerPhone!, monoStyle, monoBold),
          ],
          const SizedBox(height: 4),
          _buildMultiLineRow('Date', dateFormat.format(receipt.date), monoStyle, monoBold),
          const SizedBox(height: 4),
          _buildMultiLineRow('Payment', receipt.paymentMethodLabel, monoStyle, monoBold),
          if (receipt.paymentBreakdown != null && receipt.paymentBreakdown!.length > 1) ...[
            const SizedBox(height: 2),
            ...receipt.paymentBreakdown!.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(left: 14, top: 2),
              child: _buildRow(
                '• ${entry.key}',
                '₹${entry.value.toStringAsFixed(0)}',
                monoStyle.copyWith(fontSize: 11, color: Colors.black54),
                monoBold.copyWith(fontSize: 11, color: Colors.black87),
              ),
            )),
          ],

          const SizedBox(height: 10),
          _buildDashedLine(),
          const SizedBox(height: 10),

          // Itemized Line Items
          ...receipt.lineItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.description,
                      style: monoStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${item.amount.toStringAsFixed(0)}',
                    style: monoBold,
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 6),
          _buildDashedLine(),
          const SizedBox(height: 10),

          // Calculation Breakdown
          _buildRow('Subtotal', '₹${receipt.subtotal.toStringAsFixed(0)}', monoStyle, monoStyle),
          if (receipt.taxAmount > 0) ...[
            const SizedBox(height: 4),
            _buildRow('Tax', '₹${receipt.taxAmount.toStringAsFixed(1)}', monoStyle, monoStyle),
          ],
          const SizedBox(height: 4),
          _buildRow('TOTAL', '₹${receipt.grandTotal.toStringAsFixed(1)}', monoBold, monoBold),
          
          if (receipt.roundingAmount != 0) ...[
            const SizedBox(height: 4),
            _buildRow(
              receipt.roundingAmount > 0 ? 'Round up' : 'Round down',
              '${receipt.roundingAmount > 0 ? "+" : ""}${receipt.roundingAmount.toStringAsFixed(1)}',
              monoStyle,
              monoStyle,
            ),
          ],

          if (receipt.prepaidAmount != null && receipt.prepaidAmount! > 0) ...[
            const SizedBox(height: 4),
            _buildRow(
              'Prepaid Advance',
              '-₹${receipt.prepaidAmount!.toStringAsFixed(0)}',
              monoStyle,
              monoStyle,
            ),
          ],

          if (receipt.isPartialPayment) ...[
            const SizedBox(height: 8),
            _buildRow(
              'Amount Paid',
              '₹${(receipt.paidAmount ?? 0.0).toStringAsFixed(0)}',
              monoStyle.copyWith(color: const Color(0xFF16A34A)),
              monoBold.copyWith(color: const Color(0xFF16A34A)),
            ),
            const SizedBox(height: 6),
            _buildRow(
              'REMAINING BALANCE',
              '₹${(receipt.remainingAmount ?? 0.0).toStringAsFixed(0)}',
              GoogleFonts.courierPrime(
                color: const Color(0xFFD97706),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
              GoogleFonts.courierPrime(
                color: const Color(0xFFD97706),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            _buildRow(
              (receipt.prepaidAmount != null && receipt.prepaidAmount! > 0)
                  ? (receipt.amountDue <= 0 ? 'BALANCE (PAID)' : 'BALANCE DUE')
                  : 'AMOUNT DUE',
              '₹${receipt.amountDue.toStringAsFixed(0)}',
              GoogleFonts.courierPrime(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
              GoogleFonts.courierPrime(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],

          const SizedBox(height: 10),
          Center(
            child: Text(
              receipt.isPartialPayment
                  ? '*** PARTIAL PAYMENT (₹${(receipt.remainingAmount ?? 0.0).toStringAsFixed(0)} LEFT) ***'
                  : (receipt.isCredit
                      ? '*** RECORDED ON CREDIT ***'
                      : (receipt.isPaid ? '*** PAID FULLY ***' : '*** BALANCE PENDING ***')),
              style: monoBold.copyWith(
                fontSize: 12,
                color: receipt.isPartialPayment || receipt.isCredit
                    ? const Color(0xFFD97706)
                    : (receipt.isPaid ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
              ),
            ),
          ),

          const SizedBox(height: 10),
          _buildDashedLine(),
          const SizedBox(height: 12),

          // Footer
          Center(
            child: Text(
              'Thank you, visit again\nSoftware by S&B Manager',
              textAlign: TextAlign.center,
              style: monoStyle.copyWith(
                fontSize: 11,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black38),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildRow(String label, String value, TextStyle labelStyle, TextStyle valueStyle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }

  Widget _buildMultiLineRow(String label, String value, TextStyle labelStyle, TextStyle valueStyle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: valueStyle,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

/// The full Payment Complete Dialog containing the green success card, receipt preview, and WhatsApp share buttons
class PaymentCompleteModal extends ConsumerStatefulWidget {
  final ReceiptData receipt;
  final VoidCallback? onClose;

  const PaymentCompleteModal({
    super.key,
    required this.receipt,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required ReceiptData receipt,
    VoidCallback? onClose,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: PaymentCompleteModal(
          receipt: receipt,
          onClose: onClose,
        ),
      ),
    );
  }

  @override
  ConsumerState<PaymentCompleteModal> createState() => _PaymentCompleteModalState();
}

class _PaymentCompleteModalState extends ConsumerState<PaymentCompleteModal> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSharing = false;
  bool _isPrinting = false;
  bool _isBtPrinting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoPrint();
    });
  }

  Future<void> _checkAutoPrint() async {
    if (kIsWeb) return;
    final autoPrint = ref.read(printerSettingsProvider).autoPrint;
    if (autoPrint) {
      _printViaBluetooth(silent: true);
    }
  }

  Future<void> _printViaBluetooth({bool silent = false}) async {
    if (_isBtPrinting) return;
    setState(() => _isBtPrinting = true);

    try {
      final service = ref.read(bluetoothPrinterServiceProvider);
      bool isConnected = await service.isConnected;

      if (!isConnected) {
        // Try auto-reconnect to saved printer
        final printerState = ref.read(printerSettingsProvider);
        final savedMac = printerState.savedMac;
        final savedName = printerState.savedName;
        if (savedMac != null) {
          isConnected = await service.connectByMac(savedMac, name: savedName);
          if (isConnected) {
            ref.read(printerSettingsProvider.notifier).setConnected(true);
          }
        }
      }

      if (!isConnected) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'No Bluetooth printer connected. Go to Settings -> Thermal Bill Printer to connect your DC Code M21.',
              ),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrinterSettingsScreen(),
                    ),
                  );
                },
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      final printerState = ref.read(printerSettingsProvider);
      final paper = printerState.paperWidth;
      final copies = printerState.printCopies;
      final receiptBytes = ReceiptFormatter.buildReceipt(widget.receipt, paper: paper);

      bool allSuccess = true;
      for (int i = 0; i < copies; i++) {
        final success = await service.printBytes(receiptBytes);
        if (!success) allSuccess = false;
        if (i < copies - 1) {
          await Future.delayed(const Duration(milliseconds: 600));
        }
      }

      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              allSuccess
                  ? (copies > 1 ? 'Printed $copies copies successfully!' : 'Receipt printed successfully!')
                  : 'Printed with warnings. Please check paper.',
            ),
            backgroundColor: allSuccess ? AppColors.success : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      debugPrint('[PaymentCompleteModal] Bluetooth print error: $e');
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBtPrinting = false);
      }
    }
  }

  Future<Uint8List?> _captureReceiptPng() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing receipt PNG: $e');
      return null;
    }
  }

  Future<void> _sendViaWhatsApp() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final pngBytes = await _captureReceiptPng();
      if (pngBytes == null) {
        throw Exception('Failed to generate receipt image');
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/receipt_${widget.receipt.invoiceNumber}.png');
      await file.writeAsBytes(pngBytes);

      final String amtLine;
      if (widget.receipt.isPartialPayment) {
        amtLine = 'Amount Paid: ₹${(widget.receipt.paidAmount ?? 0.0).toStringAsFixed(0)}\nRemaining Balance: ₹${(widget.receipt.remainingAmount ?? 0.0).toStringAsFixed(0)} (Added to Khata)';
      } else if (widget.receipt.isCredit) {
        amtLine = 'Credit Amount: ₹${widget.receipt.amountDue.toStringAsFixed(0)}';
      } else {
        amtLine = 'Amount Paid: ₹${widget.receipt.amountDue.toStringAsFixed(0)}';
      }
      final text = '🧾 Invoice ${widget.receipt.invoiceNumber} from ${widget.receipt.clubName}\nTable: ${widget.receipt.tableName}\n$amtLine\nThank you for visiting ${widget.receipt.clubName}!';

      // Native Share Sheet allows selecting WhatsApp directly with the receipt PNG image!
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: text,
        subject: 'Receipt ${widget.receipt.invoiceNumber}',
      );
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing receipt: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _printReceipt() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);

    try {
      final pngBytes = await _captureReceiptPng();
      if (pngBytes == null) throw Exception('Could not render receipt image');

      final pdf = pw.Document();
      final image = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Receipt_${widget.receipt.invoiceNumber}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing receipt: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;

    return Container(
      width: isDesktop ? 860 : size.width * 0.95,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (widget.receipt.isPartialPayment || widget.receipt.isCredit
                            ? const Color(0xFFF59E0B)
                            : (widget.receipt.isPaid ? AppColors.success : AppColors.error))
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.receipt.isPartialPayment
                        ? Icons.payments_outlined
                        : (widget.receipt.isCredit
                            ? Icons.credit_score
                            : (widget.receipt.isPaid
                                ? Icons.check_circle_outline
                                : Icons.pending_actions)),
                    color: widget.receipt.isPartialPayment || widget.receipt.isCredit
                        ? const Color(0xFFF59E0B)
                        : (widget.receipt.isPaid ? AppColors.success : AppColors.error),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.receipt.isPartialPayment
                            ? 'Partial payment'
                            : (widget.receipt.isCredit
                                ? 'Credit recorded'
                                : (widget.receipt.isPaid
                                    ? 'Payment complete'
                                    : 'Bill generated')),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.receipt.tableName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (widget.onClose != null) widget.onClose!();
                  },
                  icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.3)),

          // Main Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Payment Received Card
                        Expanded(child: _buildPaymentReceivedCard(theme)),
                        const SizedBox(width: 20),
                        // Right Column: Receipt Preview
                        Expanded(child: _buildReceiptPreviewSection(theme)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildPaymentReceivedCard(theme),
                        const SizedBox(height: 20),
                        _buildReceiptPreviewSection(theme),
                      ],
                    ),
            ),
          ),

          Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.3)),

          // Bottom Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                if (isDesktop) ...[
                  Icon(Icons.print_outlined, color: theme.colorScheme.onSurfaceVariant, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Your receipt is ready to print.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                ],

                // Action Buttons
                if (isDesktop) ...[
                  if (!kIsWeb) ...[
                    FilledButton.icon(
                      onPressed: _isBtPrinting ? null : () => _printViaBluetooth(),
                      icon: _isBtPrinting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.print, size: 18),
                      label: const Text('Print Bill'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _isPrinting ? null : _printReceipt,
                      icon: _isPrinting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('Save PDF'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ] else ...[
                    FilledButton.icon(
                      onPressed: _isPrinting ? null : _printReceipt,
                      icon: _isPrinting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.print, size: 18),
                      label: const Text('Print Receipt'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _isSharing ? null : _sendViaWhatsApp,
                    icon: _isSharing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.success))
                        : const Icon(Icons.message, size: 18, color: AppColors.success),
                    label: const Text('Send Receipt'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ] else ...[
                  if (!kIsWeb) ...[
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        onPressed: _isBtPrinting ? null : () => _printViaBluetooth(),
                        icon: _isBtPrinting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.print, size: 18),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Print Bill'),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.outlined(
                      tooltip: 'Save / System PDF',
                      onPressed: _isPrinting ? null : _printReceipt,
                      icon: _isPrinting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf, size: 18),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        onPressed: _isSharing ? null : _sendViaWhatsApp,
                        icon: _isSharing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.success))
                            : const Icon(Icons.message, size: 18, color: AppColors.success),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('WhatsApp'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isPrinting ? null : _printReceipt,
                        icon: _isPrinting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.print, size: 18),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Print Receipt'),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSharing ? null : _sendViaWhatsApp,
                        icon: _isSharing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.success))
                            : const Icon(Icons.message, size: 18, color: AppColors.success),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Send Receipt'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentReceivedCard(ThemeData theme) {
    final isPartial = widget.receipt.isPartialPayment;
    final isCredit = widget.receipt.isCredit;
    final isPrepaid = widget.receipt.prepaidAmount != null &&
        widget.receipt.prepaidAmount! > 0;
    final isFullyPaidUpfront = isPrepaid && widget.receipt.amountDue <= 0;

    final Color statusColor = (isPartial || isCredit)
        ? const Color(0xFFF59E0B)
        : (widget.receipt.isPaid ? AppColors.success : AppColors.error);

    final IconData statusIcon = isPartial
        ? Icons.payments_outlined
        : (isCredit
            ? Icons.credit_score
            : (widget.receipt.isPaid ? Icons.check : Icons.access_time));

    final String headerText;
    if (isPartial) {
      headerText = 'PARTIAL PAYMENT';
    } else if (isCredit) {
      headerText = 'CREDIT RECORDED';
    } else if (isFullyPaidUpfront) {
      headerText = 'PREPAID SESSION SETTLED';
    } else if (widget.receipt.isPaid) {
      headerText = 'PAYMENT RECEIVED';
    } else {
      headerText = 'BILL PENDING';
    }

    final double displayAmount = isPartial
        ? (widget.receipt.paidAmount ?? (widget.receipt.grandTotal - (widget.receipt.remainingAmount ?? 0.0)))
        : (isFullyPaidUpfront
            ? widget.receipt.prepaidAmount!
            : widget.receipt.amountDue);

    final String subtitle;
    if (isPartial) {
      final cust = widget.receipt.customerName;
      final rem = (widget.receipt.remainingAmount ?? 0.0).toStringAsFixed(0);
      subtitle = (cust != null && cust.isNotEmpty)
          ? 'Paid of \u20B9${widget.receipt.grandTotal.toStringAsFixed(0)} total \u2022 \u20B9$rem to $cust\'s Khata'
          : 'Paid of \u20B9${widget.receipt.grandTotal.toStringAsFixed(0)} total \u2022 \u20B9$rem on Credit';
    } else if (isCredit) {
      final cust = widget.receipt.customerName;
      subtitle = (cust != null && cust.isNotEmpty)
          ? 'Invoice #${widget.receipt.invoiceNumber} \u2022 Added to $cust\'s Khata'
          : 'Invoice #${widget.receipt.invoiceNumber} \u2022 Added to Customer Khata';
    } else if (isFullyPaidUpfront) {
      subtitle = 'Invoice #${widget.receipt.invoiceNumber} \u2022 Prepaid advance settled';
    } else if (isPrepaid) {
      subtitle = 'Invoice #${widget.receipt.invoiceNumber} \u2022 Total Billed: \u20B9${widget.receipt.grandTotal.toStringAsFixed(0)}';
    } else if (widget.receipt.isPaid) {
      subtitle = 'Invoice #${widget.receipt.invoiceNumber} completed successfully';
    } else {
      subtitle = 'Invoice #${widget.receipt.invoiceNumber} pending settlement';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              Text(
                headerText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '\u20B9${displayAmount.toStringAsFixed(0)}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Details List
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.table_bar_outlined, color: theme.colorScheme.onSurfaceVariant, size: 18),
                    const SizedBox(width: 10),
                    Text('Table', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const Spacer(),
                    Text(widget.receipt.tableName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                Divider(height: 16, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
                Row(
                  children: [
                    Icon(Icons.credit_card_outlined, color: theme.colorScheme.onSurfaceVariant, size: 18),
                    const SizedBox(width: 10),
                    Text('Payment', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const Spacer(),
                    Text(widget.receipt.paymentMethodLabel, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                if (isPartial) ...[
                  Divider(height: 16, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
                  Row(
                    children: [
                      const Icon(Icons.bookmark_outline, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 10),
                      Text('Balance Left', style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFFF59E0B))),
                      const Spacer(),
                      Text(
                        '₹${(widget.receipt.remainingAmount ?? 0.0).toStringAsFixed(0)} (Khata)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPreviewSection(ThemeData theme) {
    final isPartial = widget.receipt.isPartialPayment;
    final isCredit = widget.receipt.isCredit;
    final Color badgeColor = (isPartial || isCredit)
        ? const Color(0xFFF59E0B)
        : (widget.receipt.isPaid ? AppColors.success : AppColors.error);
    final String badgeLabel = isPartial
        ? 'Partial'
        : (isCredit ? 'Credit' : (widget.receipt.isPaid ? 'Paid' : 'Pending'));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipt preview',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Review before printing',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: RepaintBoundary(
              key: _repaintKey,
              child: ThermalReceiptWidget(receipt: widget.receipt),
            ),
          ),
        ],
      ),
    );
  }
}
