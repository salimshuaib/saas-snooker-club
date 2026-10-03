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
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';

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
  });

  factory ReceiptData.fromGameSession(
    GameSession session, {
    required String clubName,
    String? clubAddress,
    String? clubPhone,
    String? customerPhone,
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
    final double baseGame = session.gameCharge ?? session.baseGameCharge ?? 0.0;
    final int minutes = (session.activeSeconds / 60).ceil();
    final String durationLabel = minutes >= 60
        ? '${(minutes / 60).toStringAsFixed(1)}h'
        : '${minutes}m';

    items.add(ReceiptLineItem(
      description: '${session.tableName} time ($durationLabel)',
      amount: baseGame,
    ));

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
      items.add(ReceiptLineItem(
        description: 'Manual: ${mg.tableName}',
        amount: mg.calculatedAmount,
      ));
    }

    final double sub = items.fold(0.0, (sum, i) => sum + i.amount);
    final double grand = session.grandTotal ?? sub;
    final double finalAmt = session.finalAmount ?? session.roundedAmount ?? grand;
    final double roundDiff = finalAmt - grand;

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
    }

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
      amountDue: finalAmt,
      isPaid: session.status != TableStatus.pendingBill,
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
    double sub = 0.0;
    double grand = 0.0;
    double finalAmt = 0.0;

    for (final s in sessions) {
      final double baseGame = s.gameCharge ?? s.baseGameCharge ?? 0.0;
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
          description: 'Manual: ${mg.tableName}',
          amount: mg.calculatedAmount,
        ));
      }

      sub += s.gameCharge ?? s.grandTotal ?? 0.0;
      grand += s.grandTotal ?? s.finalAmount ?? 0.0;
      finalAmt += s.finalAmount ?? s.roundedAmount ?? s.grandTotal ?? 0.0;
    }

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
      grandTotal: grand > 0 ? grand : items.fold(0.0, (sum, i) => sum + i.amount),
      roundingAmount: finalAmt - (grand > 0 ? grand : items.fold(0.0, (sum, i) => sum + i.amount)),
      amountDue: finalAmt,
      isPaid: true,
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
          _buildRow('Invoice', receipt.invoiceNumber, monoStyle, monoBold),
          const SizedBox(height: 4),
          _buildRow('Table', receipt.tableName, monoStyle, monoBold),
          if (receipt.customerName != null && receipt.customerName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildMultiLineRow('Customer', receipt.customerName!, monoStyle, monoBold),
          ],
          if (receipt.customerPhone != null && receipt.customerPhone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildRow('Phone', receipt.customerPhone!, monoStyle, monoBold),
          ],
          const SizedBox(height: 4),
          _buildRow('Date', dateFormat.format(receipt.date), monoStyle, monoBold),
          const SizedBox(height: 4),
          _buildRow('Payment', receipt.paymentMethodLabel, monoStyle, monoBold),

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

          const SizedBox(height: 6),
          _buildRow(
            'AMOUNT DUE',
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

          const SizedBox(height: 14),
          _buildDashedLine(),
          const SizedBox(height: 12),

          // Footer
          Center(
            child: Text(
              'Thank you! Please visit again',
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

      final text = '🧾 Invoice ${widget.receipt.invoiceNumber} from ${widget.receipt.clubName}\nTable: ${widget.receipt.tableName}\nAmount Paid: ₹${widget.receipt.amountDue.toStringAsFixed(0)}\nThank you for visiting ${widget.receipt.clubName}!';

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
                    color: AppColors.success.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment complete',
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
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (widget.onClose != null) widget.onClose!();
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Close'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: theme.colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentReceivedCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.success,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'PAYMENT RECEIVED',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${widget.receipt.amountDue.toStringAsFixed(0)}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Invoice #${widget.receipt.invoiceNumber} completed successfully',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Details List
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.table_bar, color: theme.colorScheme.onSurfaceVariant, size: 18),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Table', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        Text(widget.receipt.tableName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                Divider(height: 16, color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.onSurfaceVariant, size: 18),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        Text(widget.receipt.paymentMethodLabel, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPreviewSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
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
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.receipt.isPaid ? 'Paid' : 'Pending',
                      style: const TextStyle(
                        color: AppColors.success,
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
