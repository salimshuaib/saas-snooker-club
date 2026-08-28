import re

def modify_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find where to insert our getters, say right before build method
    build_idx = content.find("  @override\n  Widget build(BuildContext context) {")
    if build_idx == -1:
        print("Could not find build method")
        return

    getters = """
  int get _activePayerCount {
    if ((_isMultiRoundTP || _session.gameType != GameType.standard)) {
       return _customLiabilities.values.where((v) => v > 0).length;
    }
    return _customLiabilities.values.where((v) => v > 0).length;
  }

  bool get _isMultiPayer => _activePayerCount > 1;

  bool get _hasCredit {
    if ((_isMultiRoundTP || _session.gameType != GameType.standard)) {
      return _playerPaymentMethods.values.contains(PaymentMethod.credit);
    }
    return _paymentMethod == PaymentMethod.credit;
  }

  String get _ctaLabel {
    if (_isMultiPayer) {
      return 'Mark Payment Complete';
    } else {
      if (_hasCredit) {
        return 'Record Payment & Credit';
      }
      return 'Confirm Payment (₹${_grandTotal.toStringAsFixed(0)})';
    }
  }

  Color get _ctaColor {
    if (_isMultiPayer) {
      return AppColors.primary;
    }
    return _hasCredit ? AppColors.creditStatus : AppColors.primary;
  }

"""

    content = content[:build_idx] + getters + content[build_idx:]

    # Now replace the backgroundColor block
    bg_color_target = """backgroundColor: (_paymentMethod == PaymentMethod.credit ||
                          ((_isMultiRoundTP || _session.gameType != GameType.standard) && _playerPaymentMethods.values.contains(PaymentMethod.credit)))
                      ? AppColors.creditStatus
                      : AppColors.primary,"""
    bg_color_replacement = """backgroundColor: _ctaColor,"""
    content = content.replace(bg_color_target, bg_color_replacement)

    # Use regex for the text expression since it has rupees symbols which can be mangled
    regex = r"\(_paymentMethod == PaymentMethod\.credit \|\|[\s\S]+?\? 'Record Payment & Credit'[\s\S]+?: 'Confirm Payment \([^\)]+\)'\)"
    
    # We only want to replace the exact nested expression, not the trailing comma or parenthesis if possible.
    # The code looks like:
    #                     : Text(
    #                        (_paymentMethod == PaymentMethod.credit || ... ) ? 'Record...' : 'Confirm...',
    #                        style: ...
    #                     )
    
    # Safer to replace using line by line or simpler regex
    content = re.sub(
        r"\(_paymentMethod == PaymentMethod\.credit \|\|[^?]+?\?[ \r\n]+'Record Payment & Credit'[ \r\n]+:[ \r\n]+'Confirm Payment \([^\)]+\)'",
        "_ctaLabel",
        content
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    modify_file('lib/features/games/presentation/screens/billing_screen.dart')
    print("Done")
