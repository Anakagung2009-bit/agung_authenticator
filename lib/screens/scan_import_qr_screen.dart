import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/totp_service.dart';
import 'package:otpauth_migration/otpauth_migration.dart';

class ScanImportQRScreen extends StatefulWidget {
  @override
  _ScanImportQRScreenState createState() => _ScanImportQRScreenState();
}

class _ScanImportQRScreenState extends State<ScanImportQRScreen> {
  final TOTPService _totpService = TOTPService();
  final OtpAuthMigration _otpAuthParser = OtpAuthMigration();
  bool _isProcessing = false;
  String? _errorMessage;
  int _importedCount = 0;

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Importing codes...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
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
                'Scan the QR code from your old device',
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
      // Cek apakah format otpauth-migration
      if (data.startsWith('otpauth-migration://')) {
        await _processOtpAuthMigration(data);
      } else {
        // Coba parse sebagai JSON format Agung Auth
        await _processAgungAuthFormat(data);
      }
      
      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Import Successful'),
            content: Text('Successfully imported $_importedCount authenticator codes.'),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to import screen
                  Navigator.pop(context); // Return to export authenticator screen
                },
                child: Text('Done'),
              ),
            ],
          ),
        );
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

  // Proses format Agung Auth
  Future<void> _processAgungAuthFormat(String data) async {
    // Parse QR code data
    final Map<String, dynamic> qrData = jsonDecode(data);
    
    // Validate QR code format
    if (qrData['type'] != 'agung_auth_export') {
      throw Exception('Invalid QR code format');
    }
    
    // Process TOTP data
    final List<dynamic> totps = qrData['totps'];
    _importedCount = 0;
    
    for (var totp in totps) {
      await _totpService.addTOTP(
        name: totp['name'],
        secret: totp['secret'],
      );
      _importedCount++;
    }
  }

  // Proses format otpauth-migration
  Future<void> _processOtpAuthMigration(String data) async {
    // Decode otpauth-migration format
    final List<String> otpUris = _otpAuthParser.decode(data);
    _importedCount = 0;
    
    // Proses setiap URI TOTP
    for (var uri in otpUris) {
      try {
        // Parse URI menggunakan fungsi yang sudah ada
        final Map<String, String> totpData = _totpService.parseTotpUri(uri);
        
        // Tambahkan ke database
        await _totpService.addTOTP(
          name: totpData['name'] ?? 'Imported Code',
          secret: totpData['secret'] ?? '',
        );
        
        _importedCount++;
      } catch (e) {
        print('Error processing URI: $uri, Error: $e');
        // Lanjutkan ke URI berikutnya meskipun ada error
      }
    }
    
    if (_importedCount == 0) {
      throw Exception('No valid TOTP codes found in the QR code');
    }
  }
}