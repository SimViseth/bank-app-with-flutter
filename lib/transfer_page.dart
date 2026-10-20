import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color _transferPrimaryBlue = Color(0xFF1E3A8A);
const Color _transferBackground = Color(0xFFF4F6FA);

class TransferAccount {
  final String number;
  final String currency;

  const TransferAccount({required this.number, required this.currency});

  factory TransferAccount.fromMap(Map<String, dynamic> data) {
    final number = data['account_number'] ?? data['number'];
    final currency = data['currency'];
    if (number is! String || number.isEmpty) {
      throw const FormatException('An account is missing its account number.');
    }

    return TransferAccount(
      number: number,
      currency: currency is String && currency.isNotEmpty ? currency : 'USD',
    );
  }

  String get label => '$number ($currency)';
}

class TransferProfile {
  final String name;
  final List<TransferAccount> accounts;

  const TransferProfile({required this.name, required this.accounts});
}

class OwnTransferDetails {
  final String name;
  final TransferAccount fromAccount;
  final TransferAccount toAccount;
  final double amount;

  const OwnTransferDetails({
    required this.name,
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
  });
}

class TransferPage extends StatelessWidget {
  const TransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _transferBackground,
      appBar: AppBar(
        title: const Text('Transfer'),
        backgroundColor: _transferPrimaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose transfer type',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            _TransferOption(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Transfer Own Accounts',
              subtitle: 'Move money between your accounts',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder:
                          (_) => const TransferEntryPage(
                            title: 'Transfer Own Accounts',
                          ),
                    ),
                  ),
            ),
            const SizedBox(height: 14),
            _TransferOption(
              icon: Icons.swap_horiz,
              title: 'Transfer to other account',
              subtitle: 'Send money to another bank account',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder:
                          (_) => const TransferEntryPage(
                            title: 'Transfer to other account',
                            requiresManualToAccount: true,
                          ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TransferOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8ECF5),
          child: Icon(icon, color: _transferPrimaryBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class TransferEntryPage extends StatefulWidget {
  final String title;
  final bool requiresManualToAccount;

  const TransferEntryPage({
    super.key,
    required this.title,
    this.requiresManualToAccount = false,
  });

  @override
  State<TransferEntryPage> createState() => _TransferEntryPageState();
}

class _TransferEntryPageState extends State<TransferEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _toAccountController = TextEditingController();
  late final Future<TransferProfile> _profileFuture;
  TransferAccount? _fromAccount;
  TransferAccount? _toAccount;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _toAccountController.dispose();
    super.dispose();
  }

  Future<TransferProfile> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to transfer between accounts.');
    }

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final nameValue = data['name'];
    final name =
        nameValue is String && nameValue.isNotEmpty
            ? nameValue
            : user.displayName ?? 'User';

    final rawAccounts = data['accounts'];
    if (rawAccounts is List) {
      final accounts =
          rawAccounts
              .whereType<Map>()
              .map(
                (account) =>
                    TransferAccount.fromMap(Map<String, dynamic>.from(account)),
              )
              .toList();
      if (accounts.length >= 2) {
        return TransferProfile(name: name, accounts: accounts);
      }
    }

    final accountValue =
        data['account_number'] ?? data['card_number'] ?? '0994-78589854-17';
    final accountNumber = accountValue.toString();
    final secondAccountNumber =
        accountNumber.endsWith('-17')
            ? '${accountNumber.substring(0, accountNumber.length - 2)}18'
            : '0994-78589854-18';
    final currencyValue = data['currency'];
    final currency =
        currencyValue is String && currencyValue.isNotEmpty
            ? currencyValue
            : 'USD';

    return TransferProfile(
      name: name,
      accounts: [
        TransferAccount(number: accountNumber, currency: currency),
        TransferAccount(number: secondAccountNumber, currency: currency),
      ],
    );
  }

  void _continueToVerification(TransferProfile profile) {
    if (!_formKey.currentState!.validate()) return;
    final fromAccount = _fromAccount!;
    final toAccount =
        widget.requiresManualToAccount
            ? TransferAccount(
              number: _toAccountController.text.trim(),
              currency: fromAccount.currency,
            )
            : _toAccount!;
    final amount = double.parse(_amountController.text.trim());

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder:
            (_) => TransferVerificationPage(
              details: OwnTransferDetails(
                name: profile.name,
                fromAccount: fromAccount,
                toAccount: toAccount,
                amount: amount,
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _transferBackground,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: _transferPrimaryBlue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<TransferProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _transferPrimaryBlue),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load your accounts: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final profile = snapshot.data!;
          _fromAccount ??= profile.accounts.first;
          _toAccount ??=
              profile.accounts.length > 1 ? profile.accounts[1] : _fromAccount;
          _toAccountController.text =
              _toAccountController.text.isEmpty &&
                      widget.requiresManualToAccount
                  ? _toAccount?.number ?? ''
                  : _toAccountController.text;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 8),
                const _TransferHeader(),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _transferPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 20),
                _accountDropdown(
                  label: 'From account',
                  value: _fromAccount,
                  accounts: profile.accounts,
                  onChanged:
                      (account) => setState(() => _fromAccount = account),
                ),
                const SizedBox(height: 18),
                widget.requiresManualToAccount
                    ? TextFormField(
                      controller: _toAccountController,
                      decoration: InputDecoration(
                        labelText: 'To account',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Enter a destination account';
                        }
                        return null;
                      },
                    )
                    : _accountDropdown(
                      label: 'To account',
                      value: _toAccount,
                      accounts: profile.accounts,
                      onChanged:
                          (account) => setState(() => _toAccount = account),
                    ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    suffixText: _fromAccount?.currency ?? 'USD',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Enter an amount greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _continueToVerification(profile),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _transferPrimaryBlue,
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
        },
      ),
    );
  }

  Widget _accountDropdown({
    required String label,
    required TransferAccount? value,
    required List<TransferAccount> accounts,
    required ValueChanged<TransferAccount?> onChanged,
  }) {
    return DropdownButtonFormField<TransferAccount>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items:
          accounts
              .map(
                (account) => DropdownMenuItem(
                  value: account,
                  child: Text(account.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
      onChanged: onChanged,
      validator: (account) => account == null ? 'Select an account' : null,
    );
  }
}

class _TransferHeader extends StatelessWidget {
  const _TransferHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: const Color(0xFFE8ECF5),
          child: const Icon(
            Icons.sync_alt,
            size: 36,
            color: _transferPrimaryBlue,
          ),
        ),
      ],
    );
  }
}

class TransferVerificationPage extends StatelessWidget {
  final OwnTransferDetails details;

  const TransferVerificationPage({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _transferBackground,
      appBar: AppBar(
        title: const Text('Please verify transaction'),
        backgroundColor: _transferPrimaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _TransferStatement(
        details: details,
        success: false,
        action: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed:
                () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TransferSuccessPage(details: details),
                  ),
                ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _transferPrimaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ),
      ),
    );
  }
}

class TransferSuccessPage extends StatelessWidget {
  final OwnTransferDetails details;

  const TransferSuccessPage({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _transferBackground,
      appBar: AppBar(
        title: const Text('Transfer Complete'),
        backgroundColor: _transferPrimaryBlue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _TransferStatement(
        details: details,
        success: true,
        action: SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed:
                () => Navigator.popUntil(context, (route) => route.isFirst),
            style: OutlinedButton.styleFrom(
              foregroundColor: _transferPrimaryBlue,
              side: const BorderSide(color: _transferPrimaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Done'),
          ),
        ),
      ),
    );
  }
}

class _TransferStatement extends StatelessWidget {
  final OwnTransferDetails details;
  final bool success;
  final Widget action;

  const _TransferStatement({
    required this.details,
    required this.success,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (success) ...[
          const Icon(Icons.check_circle, color: Colors.green, size: 76),
          const SizedBox(height: 12),
          const Text(
            'Transfer Own account Successfully',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.green,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
        ] else ...[
          const Text(
            'Please verify transaction',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          _ProfileTransferHeader(
            name: details.name,
            account: details.fromAccount,
          ),
          const SizedBox(height: 18),
        ],
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _detailRow(
                'Amount',
                '${details.amount.toStringAsFixed(2)} ${details.fromAccount.currency}',
                emphasized: true,
              ),
              const Divider(height: 26),
              _detailRow('Transfer From', details.name),
              const SizedBox(height: 18),
              _detailRow('From account', details.fromAccount.label),
              const SizedBox(height: 18),
              _detailRow('To account', details.toAccount.label),
            ],
          ),
        ),
        const SizedBox(height: 24),
        action,
      ],
    );
  }

  Widget _detailRow(String label, String value, {bool emphasized = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: emphasized ? FontWeight.bold : FontWeight.w500,
              fontSize: emphasized ? 18 : 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileTransferHeader extends StatelessWidget {
  final String name;
  final TransferAccount account;

  const _ProfileTransferHeader({required this.name, required this.account});

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
              Icons.swap_horiz,
              color: _transferPrimaryBlue,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  account.number,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
