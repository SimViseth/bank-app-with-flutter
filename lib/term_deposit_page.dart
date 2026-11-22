import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

const Color _depositPrimaryBlue = Color(0xFF1E3A8A);

const List<String> _renewalOptions = [
  'No Renewal',
  'Renewal with principle',
  'Renewal with principle & Interest',
];

class TermDepositMenuPage extends StatelessWidget {
  const TermDepositMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Deposit', style: TextStyle(color: Colors.white)),
        backgroundColor: _depositPrimaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DepositMenuItem(
            icon: Icons.savings_outlined,
            title: 'Open Term Deposit',
            onTap: () => Navigator.pushNamed(context, '/deposit'),
          ),
          const SizedBox(height: 12),
          _DepositMenuItem(
            icon: Icons.receipt_long_outlined,
            title: 'Term Deposit Status',
            onTap: () => Navigator.pushNamed(context, '/deposit_status'),
          ),
        ],
      ),
    );
  }
}

class _DepositMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DepositMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: _depositPrimaryBlue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class TermDepositStatusPage extends StatelessWidget {
  const TermDepositStatusPage({super.key});

  static const _records = [
    (
      number: 'MM08739738',
      amount: '1000.00 USD',
      effectiveDate: '27-Oct-2026',
      maturityDate: '27-Apr-2027',
    ),
    (
      number: 'MM08739739',
      amount: '1000.00 USD',
      effectiveDate: '27-Oct-2026',
      maturityDate: '27-Apr-2027',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Term Deposit Status',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _depositPrimaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _records.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final record = _records[index];
          return Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        record.number,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        record.amount,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _StatementRow(label: 'Term Deposit Type', value: 'Hi-Growth'),
                  _StatementRow(
                    label: 'Effective date',
                    value: record.effectiveDate,
                  ),
                  const _StatementRow(label: 'Interest', value: '1.45%'),
                  _StatementRow(
                    label: 'Maturity date',
                    value: record.maturityDate,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TermDepositPage extends StatefulWidget {
  const TermDepositPage({super.key});

  @override
  State<TermDepositPage> createState() => _TermDepositPageState();
}

class _TermDepositPageState extends State<TermDepositPage> {
  final _accountController = TextEditingController();
  final _durationController = TextEditingController(text: '6');
  final _amountController = TextEditingController(text: '1000');
  String? _selectedRenewal;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _accountController.dispose();
    _durationController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  int? get _durationMonths {
    final months = int.tryParse(_durationController.text);
    return months != null && months > 0 ? months : null;
  }

  double? get _depositAmount {
    final amount = double.tryParse(_amountController.text);
    return amount != null && amount > 0 ? amount : null;
  }

  bool get _canContinue =>
      _selectedRenewal != null &&
      _durationMonths != null &&
      _depositAmount != null &&
      _termsAccepted;

  DateTime _addMonths(DateTime date, int months) {
    final monthIndex = date.month - 1 + months;
    final year = date.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final day = date.day.clamp(1, DateUtils.getDaysInMonth(year, month));
    return DateTime(year, month, day);
  }

  Future<void> _showTermsAndConditions() async {
    var acknowledged = false;
    final accepted = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Terms & Conditions'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Please review the terms for opening a Hi-Growth Term Deposit:',
                      ),
                      const SizedBox(height: 12),
                      const _TermConditionBullet(
                        text:
                            'The deposit will be held for the selected term and earns interest at the applicable rate.',
                      ),
                      const _TermConditionBullet(
                        text:
                            'A 6.00% tax is applied to interest earned, subject to applicable regulations.',
                      ),
                      const _TermConditionBullet(
                        text:
                            'At maturity, the deposit will follow the renewal option selected in this application.',
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap:
                            () => setDialogState(
                              () => acknowledged = !acknowledged,
                            ),
                        child: Row(
                          children: [
                            Icon(
                              acknowledged
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: acknowledged ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'I have read and agree to these terms',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Decline'),
                    ),
                    FilledButton(
                      onPressed:
                          acknowledged
                              ? () => Navigator.pop(dialogContext, true)
                              : null,
                      child: const Text('Accept'),
                    ),
                  ],
                ),
          ),
    );

    if (!mounted) return;
    if (accepted == true) {
      setState(() => _termsAccepted = true);
    } else if (accepted == false) {
      setState(() => _termsAccepted = false);
    }
  }

  void _continueToVerification() {
    final amount = _depositAmount!;
    final months = _durationMonths!;
    final interest = amount * 0.04 * months / 12;
    final tax = interest * 0.06;
    final effectiveDate = DateTime.now();
    final maturityDate = _addMonths(effectiveDate, months);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder:
            (context) => TermDepositVerificationPage(
              deposit: TermDepositDetails(
                amount: amount,
                durationMonths: months,
                renewalOption: _selectedRenewal!,
                interest: interest,
                tax: tax,
                effectiveDate: effectiveDate,
                maturityDate: maturityDate,
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Term Deposits',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _depositPrimaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: Color(0xFFE8ECF5),
              child: Icon(
                Icons.savings_outlined,
                size: 40,
                color: _depositPrimaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hi-Growth Term Deposit',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _depositPrimaryBlue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DepositInput(
                    label: 'From Account',
                    hint: 'Enter account',
                    keyboardType: TextInputType.text,
                    controller: _accountController,
                  ),
                  const SizedBox(height: 20),
                  _DepositInput(
                    label: 'Duration',
                    hint: 'Enter duration in months',
                    keyboardType: TextInputType.number,
                    controller: _durationController,
                    onChanged: (_) => setState(() => _termsAccepted = false),
                  ),
                  const SizedBox(height: 20),
                  _DepositInput(
                    label: 'Amount',
                    hint: 'Enter amount',
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    controller: _amountController,
                    onChanged: (_) => setState(() => _termsAccepted = false),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedRenewal,
                    decoration: InputDecoration(
                      labelText: 'Renewal Option',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items:
                        _renewalOptions
                            .map(
                              (option) => DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (option) => setState(() {
                          _selectedRenewal = option;
                          _termsAccepted = false;
                        }),
                  ),
                ],
              ),
            ),
            if (_selectedRenewal != null &&
                _durationMonths != null &&
                _depositAmount != null) ...[
              const SizedBox(height: 16),
              _buildCalculationCard(),
            ],
            const SizedBox(height: 24),
            InkWell(
              onTap: _showTermsAndConditions,
              child: Row(
                children: [
                  Icon(
                    _termsAccepted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: _termsAccepted ? Colors.green : _depositPrimaryBlue,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'I have read and agreed with the Terms & Conditions',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canContinue ? _continueToVerification : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _depositPrimaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationCard() {
    final amount = _depositAmount!;
    final months = _durationMonths!;
    final interest = amount * 0.04 * months / 12;
    final tax = interest * 0.06;
    final effectiveDate = DateTime.now();
    final maturityDate = _addMonths(effectiveDate, months);
    final currencyFormat = NumberFormat('#,##0.##');
    final dateFormat = DateFormat('MMMM d, y');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _StatementRow(label: 'Term Deposit Type', value: 'Hi-Growth'),
          _StatementRow(
            label: 'Deposit Term',
            value: '$months ${months == 1 ? 'month' : 'months'}',
          ),
          _StatementRow(
            label: 'Interest Amount',
            value: '${currencyFormat.format(interest)} USD',
          ),
          _StatementRow(
            label: 'Tax 6.00%',
            value: '${currencyFormat.format(tax)} USD',
          ),
          _StatementRow(
            label: 'Effective date',
            value: dateFormat.format(effectiveDate),
          ),
          _StatementRow(
            label: 'Maturity date',
            value: dateFormat.format(maturityDate),
          ),
          _StatementRow(label: 'Auto Renewal', value: _selectedRenewal!),
        ],
      ),
    );
  }
}

class TermDepositVerificationPage extends StatefulWidget {
  final TermDepositDetails deposit;

  const TermDepositVerificationPage({super.key, required this.deposit});

  @override
  State<TermDepositVerificationPage> createState() =>
      _TermDepositVerificationPageState();
}

class _TermDepositVerificationPageState
    extends State<TermDepositVerificationPage> {
  late final Future<Map<String, dynamic>> _accountDetails;

  @override
  void initState() {
    super.initState();
    _accountDetails = _loadAccountDetails();
  }

  Future<Map<String, dynamic>> _loadAccountDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to verify this transaction.');
    }

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final userData = snapshot.data() ?? <String, dynamic>{};
    final accountNumber =
        userData['account_number'] ??
        userData['card_number'] ??
        (userData['card_number_suffix'] == null
            ? 'Not available'
            : '•••• ${userData['card_number_suffix']}');
    final name = userData['name'];

    return {
      'name':
          name is String && name.isNotEmpty ? name : user.displayName ?? 'User',
      'accountNumber': accountNumber.toString(),
    };
  }

  void _confirmTransaction() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TermDepositSuccessPage(deposit: widget.deposit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Verify transaction',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _depositPrimaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _accountDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _depositPrimaryBlue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load account details: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final accountDetails = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFFE8ECF5),
                        child: Icon(
                          Icons.person_outline,
                          color: _depositPrimaryBlue,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              accountDetails['name'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Account number: '
                              '${accountDetails['accountNumber']}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _TermDepositStatement(deposit: widget.deposit),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Remark: When the term deposit contract is ended, the '
                    'bank will automatically renew this contract for you by '
                    'using the latest official interest rate on the start '
                    'date of each term deposit contract.',
                    style: TextStyle(height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _confirmTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _depositPrimaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TermDepositSuccessPage extends StatelessWidget {
  final TermDepositDetails deposit;

  const TermDepositSuccessPage({super.key, required this.deposit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Term Deposit',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _depositPrimaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 88),
            const SizedBox(height: 16),
            const Text(
              'Success',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _TermDepositStatement(deposit: deposit),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermDepositStatement extends StatelessWidget {
  final TermDepositDetails deposit;

  const _TermDepositStatement({required this.deposit});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('dd-MMM-yyyy');
    return Column(
      children: [
        _StatementRow(
          label: 'Deposit amount',
          value: '${currencyFormat.format(deposit.amount)} USD',
        ),
        _StatementRow(label: 'Term Deposit Type', value: 'Hi-Growth'),
        _StatementRow(
          label: 'Deposit Term',
          value:
              '${deposit.durationMonths} '
              '${deposit.durationMonths == 1 ? 'month' : 'months'}',
        ),
        _StatementRow(label: 'Auto Renewal', value: deposit.renewalOption),
        _StatementRow(
          label: 'Interest Amount',
          value: '${currencyFormat.format(deposit.interest)} USD',
        ),
        _StatementRow(
          label: 'Tax 6.00%',
          value: '${currencyFormat.format(deposit.tax)} USD',
        ),
        _StatementRow(
          label: 'Effective date',
          value: dateFormat.format(deposit.effectiveDate),
        ),
        _StatementRow(
          label: 'Maturity date',
          value: dateFormat.format(deposit.maturityDate),
        ),
      ],
    );
  }
}

class TermDepositDetails {
  final double amount;
  final int durationMonths;
  final String renewalOption;
  final double interest;
  final double tax;
  final DateTime effectiveDate;
  final DateTime maturityDate;

  const TermDepositDetails({
    required this.amount,
    required this.durationMonths,
    required this.renewalOption,
    required this.interest,
    required this.tax,
    required this.effectiveDate,
    required this.maturityDate,
  });
}

class _TermConditionBullet extends StatelessWidget {
  final String text;

  const _TermConditionBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [const Text('\u2022  '), Expanded(child: Text(text))],
      ),
    );
  }
}

class _StatementRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatementRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepositInput extends StatelessWidget {
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _DepositInput({
    required this.label,
    required this.hint,
    required this.keyboardType,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _depositPrimaryBlue),
            ),
          ),
        ),
      ],
    );
  }
}
