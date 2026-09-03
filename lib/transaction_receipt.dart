import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color primaryBlue = Color(0xFF1E3A8A);

class TransactionReceiptPage extends StatefulWidget {
  final String transactionId;
  final String type;
  final String description;
  final String category;
  final double amount;
  final Timestamp? timestamp;
  final String? note;
  final String? recipient;
  final String? sender;

  const TransactionReceiptPage({
    super.key,
    required this.transactionId,
    required this.type,
    required this.description,
    required this.category,
    required this.amount,
    this.timestamp,
    this.note,
    this.recipient,
    this.sender,
  });

  @override
  State<TransactionReceiptPage> createState() => _TransactionReceiptPageState();
}

class _TransactionReceiptPageState extends State<TransactionReceiptPage> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Transaction Receipt',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context), 
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: _isSharing ? null : _shareReceipt, 
            icon: const Icon(Icons.share),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              //Receipt card wrapped with RepaintBoundary for image capture
              RepaintBoundary(
                key: _receiptKey,
                child: _buildReceiptCard(),
              ),
              const SizedBox(height: 24),
              //Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptCard() {
    final isDebit = widget.type == 'debit';
    final statusColor = const Color(0xFF4CAF50);
    final amountText = '\$${widget.amount.toStringAsFixed(2)}';
    String formattedDate = 'Unknown date';
    
    if (widget.timestamp != null) {
      final date = widget.timestamp!.toDate();
      formattedDate = DateFormat('MMM dd, yyyy . hh:mm a').format(date);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        children: [
          //Header Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              )
            ),
            child: Column(
              children: [
                //Success Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isDebit ? 'Payment Sent' : 'Payment Received',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  amountText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),

          //Status Badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStatusBadge(),
          ),

          //Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: Colors.grey[300]),
          ),

          //Transaction Details
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildDetailRow(
                  'Reference Number',
                  widget.transactionId.length > 12
                    ? '${widget.transactionId.substring(0,12)}...'
                    : widget.transactionId,
                  isHighlighted: true,
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Transaction Type',
                  isDebit ? 'Payment Sent' : 'Payment Received',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Category',
                  widget.category,
                ),
                if (widget.recipient != null)...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Recipient',
                    widget.recipient!,
                  )
                ],
                if (widget.sender != null)...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Sender',
                    widget.sender!,
                  )
                ],
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Description',
                  widget.description,
                ),
                if (widget.note != null && widget.note!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Note',
                    widget.note!,
                  )
                ]
              ],
            ),
          ),

          //Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: Colors.grey[300]),
          ),

          //Amount Details
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Amount Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAmountRow('Amount', amountText),
                const SizedBox(height: 12),
                _buildAmountRow('Service Fee', '\$0.00'),
                const SizedBox(height: 16),
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 16),
                _buildAmountRow('Total Amount', amountText, isTotal: true),
              ],
            ),
          ),

          //Footer
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              )
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Keep this receipt for your records',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      )
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Need help? Contact support@edbank.com',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black87 : Colors.grey[600],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: Colors.black87,
          ),
        )
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isHighlighted ? primaryBlue : Colors.black87,
              fontSize: 14,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
            ),
          )
        )
      ],
    );
  }


  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
          SizedBox(width: 6),
          Text(
            'Completed',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          )
        ],
      ),
    );
  }


  Future<void> _shareReceipt() async {
    setState(() {
      _isSharing = true;
    });

    try {
      //Capture the receipt as image
      final boundary = _receiptKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Platform specific sharing
      if (kIsWeb) {
        //For Flutter Web: Share directly from bytes
        await Share.shareXFiles(
          [XFile.fromData(
            bytes,
            name: 'receipt_${widget.transactionId}.png',
            mimeType: 'image/png',
          )],
          text: 'Transaction Receipt - ${widget.description}',
        );
      } else {
        //For mobile (Android & iOS): Save to file first
        //Save to temporary file
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/receipt_${widget.transactionId}.png');
        await file.writeAsBytes(bytes);

        //Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Transaction Receipt - ${widget.description}',
        );
      }      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share receipt: $e'),
          backgroundColor: Colors.red,
          )
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        //Share button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isSharing ? null : _shareReceipt, 
            icon: _isSharing
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
              : const Icon(Icons.share, color: Colors.white),
            label: Text(
              _isSharing ? 'Preparing...' : 'Share Receipt',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(
                // borderRadius: BorderRadiusGeometry.circular(12),
                borderRadius: BorderRadius.circular(12)
              ),
              elevation: 2,
            )
          ),
        ),
        const SizedBox(height: 12),

        //Done Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context), 
            icon: const Icon(Icons.check),
            label: const Text(
              'Done',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryBlue,
              side: const BorderSide(color: primaryBlue, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              )
            ),
          ),
        )
      ],
    );
  }
}