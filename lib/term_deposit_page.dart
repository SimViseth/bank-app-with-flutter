import 'package:flutter/material.dart';

const Color _depositPrimaryBlue = Color(0xFF1E3A8A);

class TermDepositPage extends StatelessWidget {
  const TermDepositPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Deposit', style: TextStyle(color: Colors.white)),
        backgroundColor: _depositPrimaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DepositInput(
                label: 'Account',
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
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
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
