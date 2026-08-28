import os
import re

def fix_billing_screen():
    path = 'lib/features/games/presentation/screens/billing_screen.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()

    # 1. Add missing variables
    c = c.replace(
        """class _BillingScreenState extends ConsumerState<BillingScreen> {
  late GameSession _session;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String? _winnerId;
  String? _PlayerProfileName;
  late Map<String, PaymentMethod> _playerPaymentMethods;
  late Map<String, double> _customLiabilities;
  bool _isProcessing = false;""",
        """class _BillingScreenState extends ConsumerState<BillingScreen> {
  late GameSession _session;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String? _winnerId;
  String? _PlayerProfileName;
  late Map<String, PaymentMethod> _playerPaymentMethods;
  late Map<String, double> _customLiabilities;
  bool _isProcessing = false;
  
  late TextEditingController _finalAmountController;
  bool _isFinalAmountInitialized = false;
  
  // Custom split
  final Map<String, double> _customSplit = {};"""
    )

    # 2. Add initState
    c = c.replace(
        """  void initState() {
    super.initState();
    _session = widget.session.copyWith(endTime: DateTime.now());""",
        """  void initState() {
    super.initState();
    _finalAmountController = TextEditingController();
    _session = widget.session.copyWith(endTime: DateTime.now());"""
    )
    
    # 3. Add dispose
    c = c.replace(
        """  @override
  void dispose() {
    super.dispose();
  }""",
        """  @override
  void dispose() {
    _finalAmountController.dispose();
    super.dispose();
  }"""
    )
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)

fix_billing_screen()
