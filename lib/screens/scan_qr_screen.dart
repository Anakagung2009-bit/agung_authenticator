import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/totp_service.dart';

class ScanQRScreen extends StatefulWidget {
  @override
  _ScanQRScreenState createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  final TOTPService _totpService = TOTPService();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code TOTP'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isProcessing) {
                final String? rawValue = barcodes.first.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
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
                'Point the camera at the TOTP QR Code',
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
      // Tambahkan log untuk debugging
      print('QR Code data: $data');
      
      if (data.startsWith('otpauth://totp/')) {
        try {
          final totpData = _totpService.parseTotpUri(data);
          
          if (totpData.containsKey('name') && totpData.containsKey('secret')) {
            await _totpService.addTOTP(
              name: totpData['name']!,
              secret: totpData['secret']!,
            );
            
            if (mounted) {
              Navigator.pop(context);
            }
          } else {
            throw Exception('Format data TOTP tidak valid');
          }
        } catch (parseError) {
          print('Error parsing TOTP URI: $parseError');
          setState(() {
            _errorMessage = 'Format QR Code TOTP tidak valid: ${parseError.toString()}';
            _isProcessing = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'QR Code bukan TOTP yang valid';
          _isProcessing = false;
        });
      }
      
      // Hapus pesan error setelah beberapa detik
      if (_errorMessage != null) {
        Future.delayed(Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _errorMessage = null;
            });
          }
        });
      }
    } catch (e) {
      print('Error processing QR code: $e');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isProcessing = false;
      });
      
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    }
  }
}