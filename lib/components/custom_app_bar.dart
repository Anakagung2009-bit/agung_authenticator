import 'package:agung_auth/screens/export_authenticator_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart'; // Import provider package
import 'package:agung_auth/screens/settings_screen.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(64);
  final TextEditingController searchController;
  final VoidCallback onMenuPressed;

  const CustomAppBar({
  Key? key,
  required this.searchController,
  required this.onMenuPressed,
  }) : super(key: key);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> with SingleTickerProviderStateMixin {
  late AnimationController _searchFocusController;
  bool _isSearchFocused = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus != _isSearchFocused) {
        setState(() {
          _isSearchFocused = _searchFocusNode.hasFocus;
        });
        if (_isSearchFocused) {
          _searchFocusController.forward();
        } else {
          _searchFocusController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchFocusController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context); // Access authService
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final hasValidPhoto = user?.photoURL != null &&
                         user!.photoURL!.isNotEmpty &&
                         (user.photoURL!.startsWith('http://') || user.photoURL!.startsWith('https://'));

    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 3,
      shadowColor: colorScheme.shadow.withOpacity(0.3),
      surfaceTintColor: colorScheme.surfaceTint,
      centerTitle: false,
      titleSpacing: 0,
      // leading: Builder(
      //   builder: (context) => IconButton(
      //     icon: Icon(
      //       Symbols.menu_rounded,
      //       color: colorScheme.onSurface,
      //       weight: 500,
      //       size: 28,
      //       fill: 0.2,
      //     ),
      //     onPressed: widget.onMenuPressed,
      //     tooltip: 'Menu',
      //     iconSize: 28,
      //     style: IconButton.styleFrom(
      //       foregroundColor: colorScheme.onSurface,
      //       backgroundColor: Colors.transparent,
      //       hoverColor: colorScheme.onSurface.withOpacity(0.08),
      //       highlightColor: colorScheme.onSurface.withOpacity(0.12),
      //     ),
      //   ),
      // ),
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: AnimatedBuilder(
          animation: _searchFocusController,
          builder: (context, child) {
            return SearchBar(
              controller: widget.searchController,
              focusNode: _searchFocusNode,
              hintText: 'Search Authentication Code',
              leading: Icon(
                Symbols.search_rounded,
                color: _isSearchFocused
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 24,
                weight: 500,
                fill: _isSearchFocused ? 1 : 0,
              ),
              trailing: [
                IconButton(
                  icon: Icon(
                    Symbols.cloud_done_rounded,
                    color: Colors.green,
                    size: 24,
                    weight: 500,
                    fill: 1,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              Symbols.cloud_done_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your codes and passwords are securely stored with Agung Dev servers',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        duration: Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: EdgeInsets.all(16),
                      ),
                    );
                  },
                  tooltip: 'Secure Cloud Storage',
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.green,
                    backgroundColor: Colors.transparent,
                    hoverColor: Colors.green.withOpacity(0.08),
                    highlightColor: Colors.green.withOpacity(0.12),
                  ),
                ),
              ],
              padding: MaterialStateProperty.all<EdgeInsets>(
                const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              elevation: MaterialStateProperty.all<double>(0),
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.focused)) {
                    return colorScheme.surfaceContainerHigh;
                  }
                  return colorScheme.surfaceContainerLow;
                },
              ),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                    color: _isSearchFocused
                        ? colorScheme.primary.withOpacity(0.5)
                        : colorScheme.outline.withOpacity(0.2),
                    width: _isSearchFocused ? 1.5 : 1.0,
                  ),
                ),
              ),
              overlayColor: MaterialStateProperty.all<Color>(
                colorScheme.onSurface.withOpacity(0.05),
              ),
            );
          },
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 24),
                          CircleAvatar(
                            backgroundImage: hasValidPhoto
                                ? NetworkImage(user!.photoURL!)
                                : null,
                            radius: 40,
                            backgroundColor: colorScheme.primaryContainer,
                            child: !hasValidPhoto
                                ? Icon(
                                    Symbols.account_circle_rounded,
                                    color: colorScheme.onPrimaryContainer,
                                    size: 48,
                                    weight: 500,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user?.displayName ?? 'Guest User',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'No email',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
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
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(Symbols.help_outline_rounded, size: 24),
                            title: Text('Transfer Codes'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ExportAuthenticatorScreen()),
                              );
                            },
                          ),
                          const Divider(height: 1),

                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text('Logout'),
                            onTap: () {
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
                                        authService.signOut(); // Use the accessed authService
                                      },
                                      child: const Text('Logout'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.errorContainer,
                                        foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          TextButton(
                            onPressed: () {
                              launchUrl(
                                Uri.parse('https://agungdev.com/privacy-policy'),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            child: const Text('Privacy Policy'),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                );
              },
              splashColor: colorScheme.primary.withOpacity(0.1),
              highlightColor: colorScheme.primary.withOpacity(0.05),
              child: Ink(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: hasValidPhoto
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(user!.photoURL!),
                        radius: 20,
                      )
                    : CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        radius: 20,
                        child: Icon(
                          Symbols.account_circle_rounded,
                          color: colorScheme.onPrimaryContainer,
                          size: 24,
                          weight: 500,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}