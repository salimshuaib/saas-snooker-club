import os
import re

def fix_billing_screen():
    path = 'lib/features/games/presentation/screens/billing_screen.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add controller state
    old_state = """class _BillingScreenState extends ConsumerState<BillingScreen> {
  late GameSession _session;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String? _winnerId;
  String? _PlayerProfileName;

  // Custom split logic
  final Map<String, double> _customSplit = {};
  bool _useCustomSplit = false;"""
  
    new_state = """class _BillingScreenState extends ConsumerState<BillingScreen> {
  late GameSession _session;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String? _winnerId;
  String? _PlayerProfileName;
  
  late TextEditingController _finalAmountController;
  bool _isFinalAmountInitialized = false;

  // Custom split logic
  final Map<String, double> _customSplit = {};
  bool _useCustomSplit = false;"""
  
    content = content.replace(old_state, new_state)
    
    # Init and dispose
    old_init = """  @override
  void initState() {
    super.initState();
    _session = widget.session;
    if (_session.gameType != GameType.standard) {
      _paymentMethod = PaymentMethod.split;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }"""
  
    new_init = """  @override
  void initState() {
    super.initState();
    _session = widget.session;
    if (_session.gameType != GameType.standard) {
      _paymentMethod = PaymentMethod.split;
    }
    _finalAmountController = TextEditingController();
  }

  @override
  void dispose() {
    _finalAmountController.dispose();
    super.dispose();
  }"""
  
    content = content.replace(old_init, new_init)
    
    # Calculations
    old_calc = """  double get _ordersTotal =>
      _session.orders.fold<double>(0, (s, o) => s + o.total);

  double get _grandTotal => _gameCharge + _ordersTotal;"""
  
    new_calc = """  double get _ordersTotal =>
      _session.orders.fold<double>(0, (s, o) => s + o.total);

  double get _grandTotal => _gameCharge + _ordersTotal;
  
  double get _roundedTotal => (_grandTotal / 10).roundToDouble() * 10;
  
  double get _finalTotal {
    if (!_isFinalAmountInitialized) {
      _finalAmountController.text = _roundedTotal.toStringAsFixed(0);
      _isFinalAmountInitialized = true;
    }
    return double.tryParse(_finalAmountController.text) ?? _roundedTotal;
  }"""
  
    content = content.replace(old_calc, new_calc)
    
    # Update totalToSplit
    content = content.replace("final totalToSplit =\n        _grandTotal;", "final totalToSplit =\n        _finalTotal;")
    content = content.replace("final totalToSplit = _grandTotal;", "final totalToSplit = _finalTotal;")
    
    # Update confirm button label
    content = content.replace("return 'Confirm Payment (₹${_grandTotal.toStringAsFixed(0)})';", "return 'Confirm Payment (₹${_finalTotal.toStringAsFixed(0)})';")
    content = content.replace("return 'Confirm Payment (â‚¹${_grandTotal.toStringAsFixed(0)})';", "return 'Confirm Payment (₹${_finalTotal.toStringAsFixed(0)})';")
    
    # Update sum validation
    content = content.replace("final isBalanced = (_grandTotal - currentSum).abs() < 0.5;", "final isBalanced = (_finalTotal - currentSum).abs() < 0.5;")
    content = content.replace("final diff = (_grandTotal - currentSum).abs();", "final diff = (_finalTotal - currentSum).abs();")
    
    # Update final session saving
    old_session_1 = """            grandTotal: _grandTotal,
            date: finalDate,
          )
        : _session.copyWith("""
        
    new_session_1 = """            grandTotal: _grandTotal,
            roundedAmount: _roundedTotal,
            finalAmount: _finalTotal,
            date: finalDate,
          )
        : _session.copyWith("""
        
    old_session_2 = """            grandTotal: _grandTotal,
            date: finalDate,
          );

    try {"""
    
    new_session_2 = """            grandTotal: _grandTotal,
            roundedAmount: _roundedTotal,
            finalAmount: _finalTotal,
            date: finalDate,
          );

    try {"""
    
    content = content.replace(old_session_1, new_session_1)
    content = content.replace(old_session_2, new_session_2)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_billing_screen()
