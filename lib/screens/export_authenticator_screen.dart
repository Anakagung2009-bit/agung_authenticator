import 'package:flutter/material.dart';
import '../services/auth_check.dart';
import 'select_codes_screen.dart';
import 'import_codes_screen.dart';

class ExportAuthenticatorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Transfer Codes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Transfer your authenticator codes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text(
              'You can export your authenticator codes to another device or import codes from another device.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 32),
            _buildOptionCard(
              context: context,
              title: 'Export Codes',
              description: 'Export your authenticator codes to another device',
              icon: Icons.upload,
              color: colorScheme.primaryContainer,
              onTap: () => _handleExportCodes(context),
            ),
            SizedBox(height: 16),
            _buildOptionCard(
              context: context,
              title: 'Import Codes',
              description: 'Import authenticator codes from another device',
              icon: Icons.download,
              color: colorScheme.secondaryContainer,
              onTap: () => _navigateToImportCodes(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: title == 'Export Codes' 
                    ? colorScheme.onPrimaryContainer 
                    : colorScheme.onSecondaryContainer,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: title == 'Export Codes' 
                            ? colorScheme.onPrimaryContainer 
                            : colorScheme.onSecondaryContainer,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: title == 'Export Codes' 
                            ? colorScheme.onPrimaryContainer.withOpacity(0.8) 
                            : colorScheme.onSecondaryContainer.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: title == 'Export Codes' 
                    ? colorScheme.onPrimaryContainer 
                    : colorScheme.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleExportCodes(BuildContext context) async {
    // Verifikasi autentikasi jika diaktifkan di settings
    final isAuthenticated = await AuthCheck.authenticate(context);
    
    if (isAuthenticated && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SelectCodesScreen()),
      );
    }
  }

  void _navigateToImportCodes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ImportCodesScreen()),
    );
  }
}