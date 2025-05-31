import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../services/auth_service.dart';
import '../screens/settings_screen.dart';

class CustomDrawer extends StatelessWidget {
  final AuthService authService;
  final VoidCallback onExportPressed;
  final VoidCallback onHowItWorksPressed;

  const CustomDrawer({
    Key? key,
    required this.authService,
    required this.onExportPressed,
    required this.onHowItWorksPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Drawer(
      backgroundColor: colorScheme.surface,
      elevation: 1,
      shadowColor: colorScheme.shadow.withOpacity(0.2),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.5),
          ),
          margin: EdgeInsets.zero,
          padding: EdgeInsets.fromLTRB(28, 24, 28, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Symbols.lock_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 28,
                        weight: 700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Authenticator',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Secure your accounts',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1),

        // Export Authenticator
        ListTile(
          leading: Icon(Symbols.swap_horiz_rounded, size: 24),
          title: Text('Transfer Codes'),
          onTap: () {
            Navigator.pop(context);
            onExportPressed();
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
        ),

        // How it works
        ListTile(
          leading: Icon(Symbols.help_outline_rounded, size: 24),
          title: Text('How it works'),
          onTap: () {
            Navigator.pop(context);
            onHowItWorksPressed();
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
        ),

        // Settings
        ListTile(
          leading: Icon(Symbols.settings_rounded, size: 24),
          title: Text('Settings'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            );
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
        ),

        const SizedBox(height: 16),
        Divider(indent: 28, endIndent: 28),
        const SizedBox(height: 8),

        // Logout
        ListTile(
          leading: Icon(Symbols.logout_rounded, size: 24, color: colorScheme.error),
          title: Text('Logout', style: TextStyle(color: colorScheme.error)),
          onTap: () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      authService.signOut();
                    },
                    child: const Text('Logout'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer,
                      foregroundColor: colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            );
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
        ),
      ],
    ),
  );  
  }
}