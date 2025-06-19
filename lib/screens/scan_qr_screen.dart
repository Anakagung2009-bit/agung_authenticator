import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/totp_service.dart';
import '../services/passkey_platform.dart';
import 'dart:convert';

class ScanQRScreen extends StatefulWidget {
  @override
  _ScanQRScreenState createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  final TOTPService _totpService = TOTPService();
  bool _isProcessing = false;
  String? _errorMessage;
  bool _hasScanned = false;


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isProcessing && !_hasScanned) {
                final String? rawValue = barcodes.first.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  _hasScanned = true; // langsung tandai sudah scan agar tidak scan ulang
                  _processQRCode(rawValue);
                }
              }
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
            ),
          if (_errorMessage != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: colorScheme.onError),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              color: Colors.black54,
              child: Text(
                'Point the camera at the QR Code',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processQRCode(String data) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      print('QR Code data: $data');

      if (data.startsWith('otpauth://totp/')) {
        await _handleTotpQr(data);
      } else {
        setState(() {
          _errorMessage = 'QR Code tidak dikenali.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      print('Error processing QR code: $e');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isProcessing = false;
      });
    }

    // Auto-clear error
    if (_errorMessage != null) {
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _errorMessage = null);
        }
      });
    }
  }

  Future<void> _handleTotpQr(String data) async {
    try {
      final totpData = _totpService.parseTotpUri(data);
      if (totpData.containsKey('name') && totpData.containsKey('secret')) {
        await _totpService.addTOTP(
          name: totpData['name']!,
          secret: totpData['secret']!,
        );

        if (mounted) Navigator.pop(context);
      } else {
        throw Exception('Format data TOTP tidak valid');
      }
    } catch (e) {
      print('TOTP parsing error: $e');
      setState(() {
        _errorMessage = 'TOTP QR tidak valid: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }
}
