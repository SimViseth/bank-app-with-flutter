import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color _loanPrimaryBlue = Color(0xFF1E3A8A);
const Color _loanBackground = Color(0xFFF4F6FA);

class LoanCollateral {
  final String number;
  final String currency;
  final String maturityDate;
  final String amount;

  const LoanCollateral({
    required this.number,
    required this.currency,
    required this.maturityDate,
    required this.amount,
  });

  String get label => '$number  $currency';
}

const _availableCollaterals = [
  LoanCollateral(
    number: 'MM0000024',
    currency: 'KHR',
    maturityDate: '13-May-2027',
    amount: '10,000,000',
  ),
];

class LoanMenuPage extends StatelessWidget {
  const LoanMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _loanBackground,
      appBar: AppBar(
        title: const Text('Loan'),
        backgroundColor: _loanPrimaryBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _LoanMenuOption(
            title: 'Request Loan Against Term Deposit',
            icon: Icons.request_quote_outlined,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const LoanRequestPage(),
                  ),
                ),
          ),
          const SizedBox(height: 14),
          _LoanMenuOption(
            title: 'Loan status',
            icon: Icons.receipt_long_outlined,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const LoanStatusPage(),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _LoanMenuOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _LoanMenuOption({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8ECF5),
          child: Icon(icon, color: _loanPrimaryBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class LoanRequestPage extends StatefulWidget {
  const LoanRequestPage({super.key});

  @override
  State<LoanRequestPage> createState() => _LoanRequestPageState();
}

class _LoanRequestPageState extends State<LoanRequestPage> {
  LoanCollateral? _selectedCollateral = _availableCollaterals.first;
  bool _showCalculation = false;
  bool _termsAccepted = false;

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
                        'Please review the terms for a loan secured by your term deposit:',
                      ),
                      const SizedBox(height: 12),
                      const _TermBullet(
                        text:
                            'Your term deposit will be held as collateral until the loan is repaid.',
                      ),
                      const _TermBullet(
                        text:
                            'Interest and applicable fees are payable according to the loan agreement.',
                      ),
                      const _TermBullet(
                        text:
                            'The bank may apply the collateral toward unpaid loan obligations.',
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

  void _onOk() {
    if (!_showCalculation) {
      setState(() => _showCalculation = true);
      return;
    }
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms & Conditions.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder:
            (_) => LoanVerificationPage(
              collateral: _selectedCollateral!,
              username:
                  FirebaseAuth.instance.currentUser?.displayName ?? 'User',
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _loanBackground,
      appBar: AppBar(
        title: const Text('Request Loan'),
        backgroundColor: _loanPrimaryBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _LoanPageHeader(title: 'Request Loan Against Term Deposit'),
          const SizedBox(height: 24),
          DropdownButtonFormField<LoanCollateral>(
            value: _selectedCollateral,
            decoration: InputDecoration(
              labelText: 'Select Term for Collateral',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items:
                _availableCollaterals
                    .map(
                      (collateral) => DropdownMenuItem(
                        value: collateral,
                        child: Text(
                          '${collateral.number}  ${collateral.currency}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (collateral) {
              if (collateral != null) {
                setState(() {
                  _selectedCollateral = collateral;
                  _showCalculation = false;
                  _termsAccepted = false;
                });
              }
            },
          ),
          if (_selectedCollateral case final collateral?) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Maturity ${collateral.maturityDate}  ${collateral.amount} '
                '${collateral.currency}',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ),
          ],
          if (_showCalculation) ...[
            const SizedBox(height: 20),
            _LoanDetailsCard(
              rows: const [
                ('Credit Limit allowed (90%)', '9,000,000 KHR'),
                ('Interest rate', '8.75 % p.a'),
                ('Total Fee CBC', '49,200 KHR'),
                ('Request Date', '22-Feb-2026'),
                ('Expire Date', '22-Feb-2027'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'You are eligible to apply for a loan against your Term Deposit.',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _showTermsAndConditions,
              child: Row(
                children: [
                  Icon(
                    _termsAccepted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: _termsAccepted ? Colors.green : _loanPrimaryBlue,
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
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _onOk,
              style: ElevatedButton.styleFrom(
                backgroundColor: _loanPrimaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermBullet extends StatelessWidget {
  final String text;

  const _TermBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [const Text('•  '), Expanded(child: Text(text))],
      ),
    );
  }
}

class LoanVerificationPage extends StatelessWidget {
  final LoanCollateral collateral;
  final String username;

  const LoanVerificationPage({
    super.key,
    required this.collateral,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _loanBackground,
      appBar: AppBar(
        title: const Text('Please verify transaction'),
        backgroundColor: _loanPrimaryBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Please verify transaction',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _LoanIdentityHeader(
            username: username,
            subtitle: 'Loan Against Term Deposit',
          ),
          const SizedBox(height: 18),
          _LoanDetailsCard(
            rows: [
              ('Loan size', '9,000,000 ${collateral.currency}'),
              ('Collateral', collateral.number),
              ('Interest rate', '8.75% p.a'),
              ('Total CBC Fee', '16,400 ${collateral.currency}'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed:
                  () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder:
                          (_) => LoanSuccessPage(
                            username: username,
                            collateral: collateral,
                          ),
                    ),
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _loanPrimaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Confirm'),
            ),
          ),
        ],
      ),
    );
  }
}

class LoanSuccessPage extends StatelessWidget {
  final String username;
  final LoanCollateral collateral;

  const LoanSuccessPage({
    super.key,
    required this.username,
    required this.collateral,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _loanBackground,
      appBar: AppBar(
        title: const Text('Loan Request'),
        backgroundColor: _loanPrimaryBlue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 76),
          const SizedBox(height: 12),
          const Text(
            'Your Loan Against Term Deposit request successfully',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.green,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _LoanSuccessHeader(username: username),
          const SizedBox(height: 16),
          _LoanDetailsCard(
            rows: [
              ('CBC Fee', '16,400 ${collateral.currency}'),
              ('Expire date', '01-Dec-2027'),
              ('Limit account', '0001 *** 238 (KHR)'),
              ('Credit Limit', '3,000,000 KHR'),
              ('Utilized Amount', '0 KHR'),
              ('Available Balance', '4,000,000 KHR'),
              ('Interest payment', 'Working day of month end'),
              ('Collateral', collateral.number),
              ('Status', 'Success'),
              ('Reference No.', '12345678'),
              ('Date', '01-Oct-2026 | 8:35 AM'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed:
                  () => Navigator.popUntil(context, (route) => route.isFirst),
              style: OutlinedButton.styleFrom(
                foregroundColor: _loanPrimaryBlue,
                side: const BorderSide(color: _loanPrimaryBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanSuccessHeader extends StatelessWidget {
  final String username;

  const _LoanSuccessHeader({required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE8ECF5),
            child: Icon(Icons.account_balance, color: _loanPrimaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Interest rate: 8.75% p.a',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Loan Size: 9,000,000 KHR',
                  style: TextStyle(
                    color: _loanPrimaryBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoanStatusPage extends StatelessWidget {
  const LoanStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _loanBackground,
      appBar: AppBar(
        title: const Text('Loan status'),
        backgroundColor: _loanPrimaryBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _LoanDetailsCard(
            rows: [
              ('Collateral', 'MM0000024'),
              ('Loan size', '9,000,000 KHR'),
              ('Interest rate', '8.75% p.a'),
              ('Request date', '22-Feb-2026'),
              ('Expire date', '22-Feb-2027'),
              ('Status', 'Success'),
            ],
            rows: [
              ('Collateral', 'MM0000023'),
              ('Loan size', '9,000,000 KHR'),
              ('Interest rate', '8.75% p.a'),
              ('Request date', '22-Feb-2026'),
              ('Expire date', '22-Feb-2027'),
              ('Status', 'Fail'),
            ],
            dividerBeforeLast: true,
          ),
        ],
      ),
    );
  }
}

class _LoanPageHeader extends StatelessWidget {
  final String title;

  const _LoanPageHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 36,
          backgroundColor: Color(0xFFE8ECF5),
          child: Icon(
            Icons.request_quote_outlined,
            size: 40,
            color: _loanPrimaryBlue,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _loanPrimaryBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _LoanIdentityHeader extends StatelessWidget {
  final String username;
  final String subtitle;

  const _LoanIdentityHeader({required this.username, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFE8ECF5),
            child: Icon(
              Icons.account_balance,
              size: 30,
              color: _loanPrimaryBlue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanDetailsCard extends StatelessWidget {
  final List<(String, String)> rows;
  final bool dividerBeforeLast;

  const _LoanDetailsCard({required this.rows, this.dividerBeforeLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (dividerBeforeLast && i == rows.length - 1)
              const Divider(height: 28),
            if (i > 0 && !(dividerBeforeLast && i == rows.length - 1))
              const SizedBox(height: 16),
            _LoanDetailRow(
              label: rows[i].$1,
              value: rows[i].$2,
              isStatus: rows[i].$1 == 'Status',
            ),
          ],
        ],
      ),
    );
  }
}

class _LoanDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isStatus;

  const _LoanDetailRow({
    required this.label,
    required this.value,
    this.isStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(label, style: TextStyle(color: Colors.grey[700])),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isStatus ? Colors.green : Colors.black87,
              fontWeight: isStatus ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
