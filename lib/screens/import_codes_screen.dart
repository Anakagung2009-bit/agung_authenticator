import 'package:flutter/material.dart';
import 'scan_import_qr_screen.dart';

class ImportCodesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Import Codes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Go to your old device',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            _buildStepCard(
              context: context,
              step: 1,
              title: 'Open Authenticator app on your old device',
              description: 'Launch the app on your previous device',
              icon: Icons.smartphone,
            ),
            SizedBox(height: 16),
            _buildStepCard(
              context: context,
              step: 2,
              title: 'Select Export Authenticator',
              description: 'Open the menu and tap on Export Authenticator',
              icon: Icons.menu,
            ),
            SizedBox(height: 16),
            _buildStepCard(
              context: context,
              step: 3,
              title: 'Choose Export Codes',
              description: 'Select the codes you want to transfer',
              icon: Icons.check_box,
            ),
            SizedBox(height: 16),
            _buildStepCard(
              context: context,
              step: 4,
              title: 'Scan the QR code',
              description: 'Use this device to scan the QR code shown on your old device',
              icon: Icons.qr_code_scanner,
            ),
            Spacer(),
            FilledButton.icon(
              onPressed: () => _navigateToScanQR(context),
              icon: Icon(Icons.qr_code_scanner),
              label: Text('Scan QR Code'),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required BuildContext context,
    required int step,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  step.toString(),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              icon,
              color: colorScheme.primary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScanQR(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScanImportQRScreen()),
    );
  }
}