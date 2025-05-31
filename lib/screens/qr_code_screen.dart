import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> selectedTotps;

  const QRCodeScreen({Key? key, required this.selectedTotps}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final qrData = _generateQRData();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Export QR Code'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Scan this QR code from your new device',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Use the "Import Codes" feature on your new device to scan this QR code',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 280,
                    backgroundColor: Colors.white,
                    errorStateBuilder: (context, error) {
                      return Center(
                        child: Text(
                          'Error generating QR code',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Card(
              color: colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security Note:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This QR code contains your authenticator secrets. Keep it private and do not share it with anyone.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateQRData() {
    // Prepare data for QR code
    final exportData = {
      'type': 'agung_auth_export',
      'version': 1,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'totps': selectedTotps.map((totp) => {
        'name': totp['name'],
        'secret': totp['secret'],
        // Tambahkan data lain yang diperlukan
      }).toList(),
    };
    
    // Convert to JSON string
    return jsonEncode(exportData);
  }
}