import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color _depositPrimaryBlue = Color(0xFF1E3A8A);

class TermDepositPage extends StatelessWidget {
  const TermDepositPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Term Deposits', style: TextStyle(color: Colors.white)),
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DepositInput(
                    label: 'From Account',
                    hint: 'Enter account',
                    keyboardType: TextInputType.text,
                  ),
                  SizedBox(height: 20),
                  _DepositInput(
                    label: 'Duration',
                    hint: 'Enter duration in months',
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 20),
                  _DepositInput(
                    label: 'Amount',
                    hint: 'Enter amount',
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                  ),
                  SizedBox(height: 20),
                  _DepositInput(
                    label: 'Renewal Option',
                    hint: 'Enter renewal option',
                    keyboardType: TextInputType.text,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          const TermDepositVerificationPage(),
                    ),
                  );
                },
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
}

class TermDepositVerificationPage extends StatefulWidget {
  const TermDepositVerificationPage({super.key});

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

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = snapshot.data() ?? <String, dynamic>{};
    final accountNumber = userData['account_number'] ??
        userData['card_number'] ??
        (userData['card_number_suffix'] == null
            ? 'Not available'
            : '•••• ${userData['card_number_suffix']}');

    return {
      'name': userData['name'] ?? user.displayName ?? 'User',
      'accountNumber': accountNumber,
    };
  }

  void _confirmTransaction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Term deposit details confirmed.')),
    );
    Navigator.pop(context);
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
                  child: const Column(
                    children: [
                      _StatementRow(label: 'Deposit amount', value: '3,000\$'),
                      _StatementRow(
                        label: 'Term Deposit Type',
                        value: 'Hi-Growth',
                      ),
                      _StatementRow(label: 'Deposit Term', value: '12 months'),
                      _StatementRow(
                        label: 'Renewal Option',
                        value: 'Principal (1 time)',
                      ),
                      _StatementRow(
                        label: 'Total interest',
                        value: '109.98 USD',
                      ),
                      _StatementRow(
                        label: 'Interest payment date',
                        value: '22-Feb-2027',
                      ),
                    ],
                  ),
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

  const _DepositInput({
    required this.label,
    required this.hint,
    required this.keyboardType,
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
          keyboardType: keyboardType,
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
