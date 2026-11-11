import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:snooker_club/features/games/presentation/widgets/payment_complete_modal.dart';

enum PaperWidth {
  mm58(32, '58mm (32 chars)'),
  mm80(48, '80mm (48 chars)');

  final int charsPerLine;
  final String label;
  const PaperWidth(this.charsPerLine, this.label);
}

class ReceiptFormatter {
  // ESC/POS Commands
  static const int _esc = 0x1B;
  static const int _gs = 0x1D;
  static const int _lf = 0x0A;

  /// Format clean ASCII string replacing special symbols (like ₹ to Rs.)
  static String _cleanText(String text) {
    return text
        .replaceAll('\u20B9', 'Rs.')
        .replaceAll('₹', 'Rs.')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'");
  }

  /// Converts string to ASCII bytes safely
  static List<int> _textBytes(String text) {
    return latin1.encode(_cleanText(text));
  }

  /// Format an amount safely without unicode currency symbol
  static String _formatAmount(double amount) {
    final isNegative = amount < 0;
    final absVal = amount.abs();
    final formatted = absVal % 1 == 0
        ? absVal.toInt().toString()
        : absVal.toStringAsFixed(2);
    return isNegative ? '-Rs.$formatted' : 'Rs.$formatted';
  }

  /// Word-wrap text into lines that each do not exceed [maxLen] characters
  static List<String> _wrapWords(String text, int maxLen) {
    final words = text.split(' ');
    final lines = <String>[];
    String curr = '';

    for (final w in words) {
      if (w.isEmpty) continue;
      if (curr.isEmpty) {
        if (w.length > maxLen) {
          for (int i = 0; i < w.length; i += maxLen) {
            lines.add(w.substring(i, (i + maxLen > w.length) ? w.length : i + maxLen));
          }
          curr = '';
        } else {
          curr = w;
        }
      } else if (curr.length + 1 + w.length <= maxLen) {
        curr = '$curr $w';
      } else {
        lines.add(curr);
        if (w.length > maxLen) {
          for (int i = 0; i < w.length; i += maxLen) {
            lines.add(w.substring(i, (i + maxLen > w.length) ? w.length : i + maxLen));
          }
          curr = '';
        } else {
          curr = w;
        }
      }
    }
    if (curr.isNotEmpty) {
      lines.add(curr);
    }
    return lines;
  }

  /// Formats key-value metadata rows (e.g. Invoice, Date, Customer)
  static List<int> _formatKeyValue(String key, String value, int width) {
    final cleanKey = _cleanText(key);
    final cleanVal = _cleanText(value);
    final bytes = <int>[];

    if (cleanKey.length + cleanVal.length + 1 <= width) {
      final spaces = width - cleanKey.length - cleanVal.length;
      final line = '$cleanKey${' ' * (spaces > 0 ? spaces : 1)}$cleanVal';
      bytes.addAll(_textBytes(line));
      bytes.add(_lf);
    } else {
      // Key on line 1, wrapped value on subsequent lines
      bytes.addAll(_textBytes(cleanKey));
      bytes.add(_lf);
      final valLines = _wrapWords(cleanVal, width);
      for (final vl in valLines) {
        bytes.addAll(_textBytes(vl));
        bytes.add(_lf);
      }
    }

    return bytes;
  }

  /// Formats line items with description and right-aligned amount
  static List<int> _formatItemRow(String item, String amount, int width) {
    final cleanItem = _cleanText(item);
    final cleanAmt = _cleanText(amount);
    final bytes = <int>[];

    if (cleanItem.length + cleanAmt.length + 1 <= width) {
      final spaces = width - cleanItem.length - cleanAmt.length;
      final line = '$cleanItem${' ' * (spaces > 0 ? spaces : 1)}$cleanAmt';
      bytes.addAll(_textBytes(line));
      bytes.add(_lf);
      return bytes;
    }

    final allLines = _wrapWords(cleanItem, width);
    if (allLines.isEmpty) {
      final spaces = width - cleanAmt.length;
      bytes.addAll(_textBytes('${' ' * (spaces > 0 ? spaces : 1)}$cleanAmt'));
      bytes.add(_lf);
      return bytes;
    }

    if (allLines.length == 1) {
      // 1 line of item, amount goes on line 2 right-aligned
      bytes.addAll(_textBytes(allLines[0]));
      bytes.add(_lf);
      final spaces = width - cleanAmt.length;
      bytes.addAll(_textBytes('${' ' * (spaces > 0 ? spaces : 1)}$cleanAmt'));
      bytes.add(_lf);
      return bytes;
    }

    // Multiple lines: print lines before last, then check if last line fits amount
    for (int i = 0; i < allLines.length - 1; i++) {
      bytes.addAll(_textBytes(allLines[i]));
      bytes.add(_lf);
    }

    final lastLine = allLines.last;
    if (lastLine.length + cleanAmt.length + 1 <= width) {
      final spaces = width - lastLine.length - cleanAmt.length;
      bytes.addAll(_textBytes('$lastLine${' ' * (spaces > 0 ? spaces : 1)}$cleanAmt'));
      bytes.add(_lf);
    } else {
      bytes.addAll(_textBytes(lastLine));
      bytes.add(_lf);
      final spaces = width - cleanAmt.length;
      bytes.addAll(_textBytes('${' ' * (spaces > 0 ? spaces : 1)}$cleanAmt'));
      bytes.add(_lf);
    }

    return bytes;
  }

  /// Builds the ESC/POS byte sequence for a full bill receipt
  static List<int> buildReceipt(
    ReceiptData data, {
    PaperWidth paper = PaperWidth.mm58,
  }) {
    final bytes = <int>[];
    final w = paper.charsPerLine;

    // 1. Initialize printer
    bytes.addAll([_esc, 0x40]); // Reset

    // 2. Club Header (Centered)
    bytes.addAll([_esc, 0x61, 0x01]); // Align Center
    bytes.addAll([_gs, 0x21, 0x11]); // Double height + Double width
    bytes.addAll(_textBytes(data.clubName));
    bytes.add(_lf);
    bytes.addAll([_gs, 0x21, 0x00]); // Normal size

    if (data.clubAddress != null && data.clubAddress!.trim().isNotEmpty) {
      bytes.addAll(_textBytes(data.clubAddress!.trim()));
      bytes.add(_lf);
    }
    if (data.clubPhone != null && data.clubPhone!.trim().isNotEmpty) {
      bytes.addAll(_textBytes('Tel: ${data.clubPhone!.trim()}'));
      bytes.add(_lf);
    }

    // Separator
    bytes.addAll(_textBytes('-' * w));
    bytes.add(_lf);

    // 3. Invoice & Session Details (Left-aligned)
    bytes.addAll([_esc, 0x61, 0x00]); // Align Left
    final dateFormat = DateFormat('dd/MM/yyyy  hh:mm a');
    bytes.addAll(_formatKeyValue('Invoice:', data.invoiceNumber, w));
    bytes.addAll(_formatKeyValue('Date:', dateFormat.format(data.date), w));

    // In case of multiple games (comma in tableName), remove Table row after invoice number as requested
    if (!data.tableName.contains(',')) {
      bytes.addAll(_formatKeyValue('Table:', data.tableName, w));
    }

    if (data.customerName != null && data.customerName!.trim().isNotEmpty) {
      bytes.addAll(_formatKeyValue('Customer:', data.customerName!.trim(), w));
    }
    if (data.customerPhone != null && data.customerPhone!.trim().isNotEmpty) {
      bytes.addAll(_formatKeyValue('Phone:', data.customerPhone!.trim(), w));
    }

    // Separator
    bytes.addAll(_textBytes('-' * w));
    bytes.add(_lf);

    // 4. Line Items Table Header
    bytes.addAll([_esc, 0x45, 0x01]); // Bold ON
    bytes.addAll(_formatKeyValue('ITEM', 'AMOUNT', w));
    bytes.addAll([_esc, 0x45, 0x00]); // Bold OFF
    bytes.addAll(_textBytes('-' * w));
    bytes.add(_lf);

    // Line Items
    for (final item in data.lineItems) {
      bytes.addAll(_formatItemRow(item.description, _formatAmount(item.amount), w));
    }

    // Separator
    bytes.addAll(_textBytes('-' * w));
    bytes.add(_lf);

    // 5. Totals
    bytes.addAll(_formatKeyValue('Subtotal:', _formatAmount(data.subtotal), w));

    if (data.taxAmount > 0) {
      bytes.addAll(_formatKeyValue('Tax:', _formatAmount(data.taxAmount), w));
    }

    if (data.roundingAmount != 0) {
      bytes.addAll(_formatKeyValue('Round Off:', _formatAmount(data.roundingAmount), w));
    }

    if (data.prepaidAmount != null && data.prepaidAmount! > 0) {
      bytes.addAll(_formatKeyValue('Prepaid Advance:', _formatAmount(-data.prepaidAmount!), w));
    }

    bytes.addAll(_textBytes('=' * w));
    bytes.add(_lf);

    // Grand Total (Large font or bold)
    if (data.isPartialPayment) {
      bytes.addAll(_formatKeyValue('TOTAL BILLED:', _formatAmount(data.grandTotal), w));
      bytes.addAll(_formatKeyValue('AMOUNT PAID:', _formatAmount(data.paidAmount ?? 0.0), w));
      bytes.addAll([_esc, 0x45, 0x01]); // Bold ON
      bytes.addAll([_gs, 0x21, 0x01]); // Double height
      bytes.addAll(_formatKeyValue('BALANCE LEFT:', _formatAmount(data.remainingAmount ?? 0.0), w));
      bytes.addAll([_gs, 0x21, 0x00]); // Normal size
      bytes.addAll([_esc, 0x45, 0x00]); // Bold OFF
    } else {
      bytes.addAll([_esc, 0x45, 0x01]); // Bold ON
      bytes.addAll([_gs, 0x21, 0x01]); // Double height
      bytes.addAll(_formatKeyValue('TOTAL DUE:', _formatAmount(data.amountDue), w));
      bytes.addAll([_gs, 0x21, 0x00]); // Normal size
      bytes.addAll([_esc, 0x45, 0x00]); // Bold OFF
    }

    bytes.addAll(_textBytes('=' * w));
    bytes.add(_lf);

    // 6. Payment Status & Method (Centered)
    bytes.addAll([_esc, 0x61, 0x01]); // Align Center
    bytes.addAll(_textBytes('Payment: ${data.paymentMethodLabel}'));
    bytes.add(_lf);

    if (data.paymentBreakdown != null && data.paymentBreakdown!.length > 1) {
      bytes.addAll([_esc, 0x61, 0x00]); // Left
      for (final entry in data.paymentBreakdown!.entries) {
        bytes.addAll(_formatKeyValue('  - ${entry.key}:', _formatAmount(entry.value), w));
      }
      bytes.addAll([_esc, 0x61, 0x01]); // Center
    }

    bytes.addAll([_esc, 0x45, 0x01]); // Bold ON
    if (data.isPartialPayment) {
      bytes.addAll(_textBytes('*** PARTIAL PAYMENT (BAL: ${_formatAmount(data.remainingAmount ?? 0.0)}) ***'));
    } else if (data.isCredit || data.paymentMethodLabel.toLowerCase().contains('credit')) {
      bytes.addAll(_textBytes('*** RECORDED ON CREDIT ***'));
    } else if (data.isPaid) {
      bytes.addAll(_textBytes('*** PAID FULLY ***'));
    } else {
      bytes.addAll(_textBytes('*** BALANCE PENDING ***'));
    }
    bytes.addAll([_esc, 0x45, 0x00]); // Bold OFF
    bytes.add(_lf);

    // 7. Footer
    bytes.addAll(_textBytes('-' * w));
    bytes.add(_lf);
    bytes.addAll(_textBytes('Thank you, visit again'));
    bytes.add(_lf);
    bytes.addAll(_textBytes('Software by S&B Manager'));
    bytes.add(_lf);

    // Extra lines for paper tear clearance
    bytes.addAll([_lf, _lf, _lf]);

    // Paper Cut command (auto-cutter models)
    bytes.addAll([_gs, 0x56, 0x01]); // Partial cut

    return bytes;
  }

  /// Builds a quick test print receipt
  static List<int> buildTestReceipt({PaperWidth paper = PaperWidth.mm58}) {
    final bytes = <int>[];
    final w = paper.charsPerLine;

    bytes.addAll([_esc, 0x40]); // Reset
    bytes.addAll([_esc, 0x61, 0x01]); // Center
    bytes.addAll([_gs, 0x21, 0x11]); // Double size
    bytes.addAll(_textBytes('TEST RECEIPT'));
    bytes.add(_lf);
    bytes.addAll([_gs, 0x21, 0x00]); // Normal size
    bytes.addAll(_textBytes('S&B Manager'));
    bytes.add(_lf);
    bytes.addAll(_textBytes('-' * w));
    bytes.add(_lf);

    bytes.addAll([_esc, 0x61, 0x00]); // Left
    bytes.addAll(_formatKeyValue('Printer:', 'DC Code M21', w));
    bytes.addAll(_formatKeyValue('Paper Mode:', paper.label, w));
    final dateStr = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());
    bytes.addAll(_formatKeyValue('Timestamp:', dateStr, w));
    bytes.addAll(_formatKeyValue('Status:', 'Connected OK', w));

    bytes.addAll(_textBytes('-' * w));
    bytes.add(_lf);
    bytes.addAll([_esc, 0x61, 0x01]); // Center
    bytes.addAll(_textBytes('*** Bluetooth Thermal Ready ***'));
    bytes.add(_lf);
    bytes.addAll(_textBytes('-' * w));
    bytes.add(_lf);

    bytes.addAll([_lf, _lf, _lf]);
    bytes.addAll([_gs, 0x56, 0x01]); // Cut

    return bytes;
  }
}
