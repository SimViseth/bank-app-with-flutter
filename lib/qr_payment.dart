import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'bottom_nav_bar.dart';
import 'dart:convert';
import 'transaction_receipt.dart';

const Color primaryBlue = Color(0xFF1E3A8A);
const Color secondaryBlue = Color(0xFF4C1D95);

class QrPaymentPage extends StatefulWidget {
  const QrPaymentPage({super.key});

  @override
  State<QrPaymentPage> createState() => _QrPaymentPageState();
}

class _QrPaymentPageState extends State<QrPaymentPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedNavIndex = 2; // QR payment is at index 2

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (index == 2) {
      // Already on QR payment page
      return;
    }
    
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        // Navigate to account page when created
        break;
      case 3:
        // Navigate to apply page when created
        break;
      case 4:
        // Navigate to more page when created
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QR Payment',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.qr_code),
              text: 'My QR Code',
            ),
            Tab(
              icon: Icon(Icons.qr_code_scanner),
              text: 'Scan QR',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          GenerateQrTab(),
          ScanQrTab(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onItemTapped: _onNavItemTapped,
      ),
      floatingActionButton: CustomFloatingActionButton(
        onPressed: () {}, // Already on QR page
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// Tab 1: Generate QR Code (Simplified - No amount needed)
class GenerateQrTab extends StatefulWidget {
  const GenerateQrTab({super.key});

  @override
  State<GenerateQrTab> createState() => _GenerateQrTabState();
}

class _GenerateQrTabState extends State<GenerateQrTab> {
  String? _qrData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateQrCode();
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data();
  }

  void _generateQrCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userData = await _getUserData();
      if (userData == null) throw Exception('User data not found');

      // Create QR data with only user information (no amount)
      final qrPayload = {
        'userId': user.uid,
        'userName': userData['name'] ?? 'User',
        'type': 'receive_payment',
      };

      setState(() {
        _qrData = jsonEncode(qrPayload);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[100]!, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: primaryBlue)
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Icon(
                      Icons.account_circle,
                      size: 80,
                      color: primaryBlue,
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _getUserData(),
                      builder: (context, snapshot) {
                        final userName = snapshot.data?['name'] ?? 'User';
                        return Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Show this QR code to receive payment',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: _qrData != null
                          ? QrImageView(
                              data: _qrData!,
                              version: QrVersions.auto,
                              size: 250.0,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: primaryBlue,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: primaryBlue,
                              ),
                            )
                          : const SizedBox(
                              width: 250,
                              height: 250,
                              child: Center(child: Text('Unable to generate QR')),
                            ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.info_outline, color: primaryBlue, size: 20),
                          SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'The sender will enter the amount',
                              style: TextStyle(
                                color: primaryBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }
}

// Tab 2: Scan QR Code
class ScanQrTab extends StatefulWidget {
  const ScanQrTab({super.key});

  @override
  State<ScanQrTab> createState() => _ScanQrTabState();
}

class _ScanQrTabState extends State<ScanQrTab> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _processQrCode(String qrData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;
      final receiverUserId = data['userId'] as String;
      final receiverUserName = data['userName'] as String;

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Prevent self-payment
      if (currentUser.uid == receiverUserId) {
        throw Exception('Cannot pay yourself');
      }

      // Navigate to payment confirmation screen
      if (!mounted) return;
      
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentConfirmationScreen(
            receiverUserId: receiverUserId,
            receiverUserName: receiverUserName,
          ),
        ),
      );

      // If payment was successful, navigate back to home
      if (result == true && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: cameraController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && !_isProcessing) {
              final String? code = barcodes.first.rawValue;
              if (code != null) {
                _processQrCode(code);
              }
            }
          },
        ),
        // Overlay with scanning frame
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
          child: Column(
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Stack(
                    children: [
                      // Corner decorations
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.greenAccent, width: 4),
                              left: BorderSide(color: Colors.greenAccent, width: 4),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.greenAccent, width: 4),
                              right: BorderSide(color: Colors.greenAccent, width: 4),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.greenAccent, width: 4),
                              left: BorderSide(color: Colors.greenAccent, width: 4),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.greenAccent, width: 4),
                              right: BorderSide(color: Colors.greenAccent, width: 4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.qr_code_scanner, color: primaryBlue, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Scan QR code to pay',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_isProcessing)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: primaryBlue),
                      SizedBox(height: 10),
                      Text(
                        'Processing...',
                        style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ],
    );
  }
}

// New Screen: Payment Confirmation
class PaymentConfirmationScreen extends StatefulWidget {
  final String receiverUserId;
  final String receiverUserName;

  const PaymentConfirmationScreen({
    super.key,
    required this.receiverUserId,
    required this.receiverUserName,
  });

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isProcessing = false;
  double? _senderBalance;

  @override
  void initState() {
    super.initState();
    _loadSenderBalance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSenderBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (mounted) {
      setState(() {
        _senderBalance = ((doc.data()?['account_balance'] ?? 0.0) as num).toDouble();
      });
    }
  }

  Future<void> _confirmPayment() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_senderBalance != null && amount > _senderBalance!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      await _makePayment(
        currentUser.uid,
        widget.receiverUserId,
        amount,
        widget.receiverUserName,
        _noteController.text,
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful!'),
          backgroundColor: Colors.green,
        ),
      );

      // Return true to indicate success
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionReceiptPage(
            transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}_sender', 
            type: 'debit', 
            description: 'QR Payment to ${widget.receiverUserName}', 
            category: 'QR Payment', 
            amount: amount,
            timestamp: Timestamp.now(),
            note: _noteController.text.isNotEmpty ? _noteController.text : null,
            recipient: widget.receiverUserName,
          )
        )
      );


    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _makePayment(
    String senderUserId,
    String receiverUserId,
    double amount,
    String receiverUserName,
    String note,
  ) async {
    final firestore = FirebaseFirestore.instance;

    // Use batch write for atomic transaction
    final batch = firestore.batch();

    // Get sender and receiver documents
    final senderDoc = firestore.collection('users').doc(senderUserId);
    final receiverDoc = firestore.collection('users').doc(receiverUserId);

    final senderData = await senderDoc.get();
    final receiverData = await receiverDoc.get();

    if (!senderData.exists || !receiverData.exists) {
      throw Exception('User data not found');
    }

    final senderBalance = (senderData.data()?['account_balance'] ?? 0.0) as num;
    final receiverBalance = (receiverData.data()?['account_balance'] ?? 0.0) as num;
    final senderName = senderData.data()?['name'] ?? 'User';

    // Check if sender has sufficient balance
    if (senderBalance < amount) {
      throw Exception('Insufficient balance');
    }

    // Update balances
    batch.update(senderDoc, {
      'account_balance': senderBalance - amount,
    });

    batch.update(receiverDoc, {
      'account_balance': receiverBalance + amount,
    });

    // Create transaction records
    final transactionId = firestore.collection('transactions').doc().id;
    final timestamp = FieldValue.serverTimestamp();

    // Sender's transaction record
    batch.set(
      firestore.collection('transactions').doc(transactionId + '_sender'),
      {
        'userId': senderUserId,
        'type': 'debit',
        'amount': amount,
        'description': 'QR Payment to $receiverUserName',
        'note': note.isNotEmpty ? note : null,
        'recipient': receiverUserName,
        'recipientId': receiverUserId,
        'timestamp': timestamp,
        'category': 'QR Payment',
      },
    );

    // Receiver's transaction record
    batch.set(
      firestore.collection('transactions').doc(transactionId + '_receiver'),
      {
        'userId': receiverUserId,
        'type': 'credit',
        'amount': amount,
        'description': 'QR Payment from $senderName',
        'note': note.isNotEmpty ? note : null,
        'sender': senderName,
        'senderId': senderUserId,
        'timestamp': timestamp,
        'category': 'QR Payment',
      },
    );

    // Commit the batch
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Confirm Payment',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Recipient Info Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, secondaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Pay to',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Icon(
                    Icons.account_circle,
                    size: 70,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    widget.receiverUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Amount Input Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      prefixStyle: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: primaryBlue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_senderBalance != null)
                    Text(
                      'Available balance: \$${_senderBalance!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    'Note (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add a note...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: primaryBlue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _confirmPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirm Payment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Cancel Button
            TextButton(
              onPressed: _isProcessing ? null : () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}