import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryBlue = Color(0xFF1E3A8A);
const Color secondaryBlue = Color(0xFF4C1D95);

class PinSetupPage extends StatefulWidget {
  final bool isChangingPin;
    const PinSetupPage({super.key, this.isChangingPin = false});

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  String pin = '';
  String confirmPin = '';
  String oldPin = '';
  bool isConfirmStep = false;
  bool isOldPinStep = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    isOldPinStep = widget.isChangingPin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 50),
                      _buildPinDisplay(),
                      const SizedBox(height: 20),
                      if (errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            _buildNumPad(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title;
    String subtitle;

    if (isOldPinStep) {
      title = 'Enter Current PIN';
      subtitle = 'Please enter your current PIN to continue';
    } else if (isConfirmStep) {
      title = 'Confirm Your PIN';
      subtitle = 'Please re-enter your PIN to confirm';
    } else {
      title = widget.isChangingPin ? 'Create New PIN' : 'Create Your PIN';
      subtitle = 'Please enter a 4-digit PIN';
    }

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.pin_outlined,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPinDisplay() {
    String currentPin = isOldPinStep ? oldPin : (isConfirmStep ? confirmPin : pin);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool isFilled = index < currentPin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isFilled ? primaryBlue : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isFilled ? primaryBlue : Colors.grey[300]!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: isFilled
                ? const Icon(Icons.circle, color: Colors.white, size: 16)
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildNumPad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildNumPadRow(['1', '2', '3']),
          const SizedBox(height: 15),
          _buildNumPadRow(['4', '5', '6']),
          const SizedBox(height: 15),
          _buildNumPadRow(['7', '8', '9']),
          const SizedBox(height: 15),
          _buildNumPadRow(['', '0', 'delete']),
        ],
      ),
    );
  }

  Widget _buildNumPadRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((num) {
        if (num.isEmpty) {
          return const SizedBox(width: 80, height: 80);
        }
        
        return GestureDetector(
          onTap: () => _onNumberTap(num),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: num == 'delete' ? Colors.transparent : Colors.white,
              shape: BoxShape.circle,
              border: num == 'delete' 
                  ? null 
                  : Border.all(color: Colors.grey[200]!, width: 1),
              boxShadow: num == 'delete'
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Center(
              child: num == 'delete'
                  ? Icon(Icons.backspace_outlined, 
                      color: Colors.grey[700], size: 28)
                  : Text(
                      num,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _onNumberTap(String num) async {
    setState(() {
      errorMessage = '';
    });

    if (num == 'delete') {
      setState(() {
        if (isOldPinStep) {
          if (oldPin.isNotEmpty) oldPin = oldPin.substring(0, oldPin.length - 1);
        } else if (isConfirmStep) {
          if (confirmPin.isNotEmpty) confirmPin = confirmPin.substring(0, confirmPin.length - 1);
        } else {
          if (pin.isNotEmpty) pin = pin.substring(0, pin.length - 1);
        }
      });
      return;
    }

    if (isOldPinStep) {
      if (oldPin.length < 4) {
        setState(() {
          oldPin += num;
        });
        
        if (oldPin.length == 4) {
          // Verify old PIN
          final prefs = await SharedPreferences.getInstance();
          final savedPin = prefs.getString('user_pin') ?? '';
          
          if (oldPin == savedPin) {
            setState(() {
              isOldPinStep = false;
              oldPin = '';
            });
          } else {
            setState(() {
              errorMessage = 'Incorrect PIN. Please try again.';
              oldPin = '';
            });
          }
        }
      }
    } else if (isConfirmStep) {
      if (confirmPin.length < 4) {
        setState(() {
          confirmPin += num;
        });
        
        if (confirmPin.length == 4) {
          if (pin == confirmPin) {
            // Save PIN
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_pin', pin);
            await prefs.setBool('pin_enabled', true);
            
            if (context.mounted) {
              Navigator.pop(context, true);
              _showSuccessDialog();
            }
          } else {
            setState(() {
              errorMessage = 'PINs do not match. Please try again.';
              confirmPin = '';
              isConfirmStep = false;
              pin = '';
            });
          }
        }
      }
    } else {
      if (pin.length < 4) {
        setState(() {
          pin += num;
        });
        
        if (pin.length == 4) {
          setState(() {
            isConfirmStep = true;
          });
        }
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 50,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.isChangingPin ? 'PIN Changed!' : 'PIN Created!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.isChangingPin 
                  ? 'Your PIN has been successfully changed.'
                  : 'Your PIN has been set up successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Done',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}