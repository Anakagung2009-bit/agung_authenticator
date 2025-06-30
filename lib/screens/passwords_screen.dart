import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../services/password_service.dart';
import '../models/password_model.dart';
import '../services/auth_check.dart';
import '../services/auth_service.dart';
import '../components/no_search_results.dart';
import '../components/empty_password_state.dart';
import '../components/custom_app_bar.dart';
import 'add_password_screen.dart';

class PasswordsScreen extends StatefulWidget {
  const PasswordsScreen({Key? key}) : super(key: key);

  @override
  _PasswordsScreenState createState() => _PasswordsScreenState();
}

class _PasswordsScreenState extends State<PasswordsScreen> {
  final PasswordService _passwordService = PasswordService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _authenticateUser() async {
    try {
      return await AuthCheck.authenticate(context);
    } catch (e) {
      print('Authentication error: $e');
      return false;
    }
  }

  Future<void> _showPasswordDetails(PasswordModel password) async {
    // Simpan BuildContext sebelum operasi asinkron
    final BuildContext currentContext = context;
    
    // Lakukan autentikasi
    try {
      final bool isAuthenticated = await _authenticateUser();
      
      // Periksa mounted sebelum mengakses context
      if (!mounted) return;
      
      // Jika autentikasi gagal, tampilkan pesan
      if (!isAuthenticated) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text('Authentication required to view password'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // Tampilkan detail password jika autentikasi berhasil
      if (mounted) {
        showModalBottomSheet(
          context: currentContext,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildPasswordDetailsSheet(password),
        );
      }
    } catch (e) {
      // Tangani error jika terjadi
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(currentContext).colorScheme.error,
          ),
        );
      }
    }
  }


  Widget _buildPasswordDetailsSheet(PasswordModel password) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 32, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'password_icon_${password.id}',
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getIconForAccountType(password.accountType),
                    color: colorScheme.onSecondaryContainer,
                    size: 28,
                    weight: 500,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      password.accountName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Added on ${_formatDate(password.createdAt)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildDetailItem(
            context: context,
            title: 'Username/Email',
            value: password.username,
            onCopy: () => _copyToClipboard(password.username),
          ),
          SizedBox(height: 16),
          _buildDetailItem(
            context: context,
            title: 'Password',
            value: password.password,
            isPassword: true,
            onCopy: () => _copyToClipboard(password.password),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(password);
                },
                icon: Icon(Symbols.delete_rounded, size: 18),
                label: Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              Row(
                children: [
                  FilledButton.tonal(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.onSecondaryContainer,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required BuildContext context,
    required String title,
    required String value,
    bool isPassword = false,
    required VoidCallback onCopy,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final ValueNotifier<bool> showPassword = ValueNotifier<bool>(false);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (isPassword)
                ValueListenableBuilder<bool>(
                  valueListenable: showPassword,
                  builder: (context, value, child) {
                    return IconButton(
                      onPressed: () {
                        showPassword.value = !showPassword.value;
                      },
                      icon: Icon(
                        value ? Symbols.visibility_off_rounded : Symbols.visibility_rounded,
                        color: colorScheme.primary,
                        weight: 500,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    );
                  },
                ),
              Expanded(
                child: isPassword
                    ? ValueListenableBuilder<bool>(
                        valueListenable: showPassword,
                        builder: (context, showValue, child) {
                          return Text(
                            showValue ? value : '••••••••',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Monospace',
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          );
                        },
                      )
                    : Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Symbols.content_copy_rounded,
                      color: colorScheme.primary,
                      size: 20,
                      weight: 500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(PasswordModel password) {
    // Simpan BuildContext dan ColorScheme sebelum operasi asinkron
    final BuildContext currentContext = context;
    final colorScheme = Theme.of(currentContext).colorScheme;
    
    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Symbols.warning_rounded,
          color: colorScheme.error,
          size: 28,
          weight: 500,
          fill: 1,
        ),
        title: const Text('Delete Password'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        content: const Text(
          'Are you sure you want to delete this password? This action cannot be undone.',
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              // Tutup dialog terlebih dahulu
              Navigator.pop(dialogContext);
              
              try {
                // Hapus password dari database
                await _passwordService.deletePassword(password.id);
                
                // Periksa apakah widget masih mounted sebelum menampilkan snackbar
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: const Text('Password deleted'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: colorScheme.errorContainer,
                      showCloseIcon: true,
                      closeIconColor: colorScheme.onErrorContainer,
                    ),
                  );
                }
              } catch (e) {
                // Tangani error jika terjadi
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getIconForAccountType(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'google':
        return Icons.g_mobiledata;
      case 'microsoft':
        return Icons.window;
      case 'discord':
        return Icons.discord;
      case 'tiktok':
        return Icons.music_note;
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
      case 'x':
        return Icons.alternate_email;
      case 'instagram':
        return Icons.camera_alt;
      case 'github':
        return Icons.code;
      case 'linkedin':
        return Icons.work;
      case 'amazon':
        return Icons.shopping_cart;
      case 'apple':
        return Icons.apple;
      case 'netflix':
        return Icons.movie;
      case 'spotify':
        return Icons.music_note;
      default:
        return Icons.lock;
    }
  }

  @override
    Widget build(BuildContext context) {
      final colorScheme = Theme.of(context).colorScheme;

      return Scaffold(
        key: _scaffoldKey,
        appBar: CustomAppBar(
          searchController: _searchController,
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        // drawer: CustomDrawer(
        //   authService: _authService,
        //   onExportPressed: () {
        //     // Handle export
        //   },
        //   onHowItWorksPressed: () {
        //     // Handle how it works
        //   },
        // ),
        body: StreamBuilder<List<PasswordModel>>(
          stream: _passwordService.getPasswords(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
              return Center(
                child: CircularProgressIndicator.adaptive(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (_isLoading) {
              // It's generally not recommended to call setState directly within the build method.
              // Consider moving this logic elsewhere, e.g., in initState or after the stream provides its first data.
              // For now, to prevent build loops, ensure it only runs once.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _isLoading) { // Check mounted to avoid calling setState on a disposed widget
                  setState(() {
                    _isLoading = false;
                  });
                }
              });
            }

            final passwords = snapshot.data ?? [];

            if (passwords.isEmpty) {
              return const EmptyPasswordState();
            }
            // Filter passwords based on search query
            final filteredPasswords = _searchQuery.isEmpty
                ? passwords
                : passwords.where((password) {
                    final query = _searchQuery.toLowerCase();
                    return password.accountType.toLowerCase().contains(query) ||
                        password.username.toLowerCase().contains(query);
                  }).toList();

            if (filteredPasswords.isEmpty) {
              return const NoSearchResults();
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: filteredPasswords.length,
              itemBuilder: (context, index) {
                final password = filteredPasswords[index];
                return _buildPasswordCard(password);
              },
            );
          },
        ),
        // --- TAMBAHKAN BOTTOM NAVIGATION BAR ANDA DI SINI ---
        bottomNavigationBar: BottomNavigationBar(
          // Ganti dengan implementasi BottomNavigationBar Anda yang sebenarnya
          // Contoh sederhana:
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined), // Ganti dengan ikon Anda
              label: 'Passwords',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.security), // Ganti dengan ikon Anda
              label: 'Generator', // Ganti dengan label Anda
            ),
            // Tambahkan item lain jika ada
          ],
          currentIndex: 0, // Atur currentIndex sesuai dengan tab yang aktif
          onTap: (index) {
            // Handle navigasi tab di sini
          },
          // Atur properti lain seperti selectedItemColor, unselectedItemColor, etc.
          // backgroundColor: colorScheme.surface, // Contoh penggunaan colorScheme
          // selectedItemColor: colorScheme.primary,
          // unselectedItemColor: colorScheme.onSurfaceVariant,
        ),
        // ----------------------------------------------------
        floatingActionButton: FloatingActionButton.large(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddPasswordScreen()),
            );
          },
          elevation: 0, // Elevasi 0 mungkin membuat FAB terlihat datar, sesuaikan jika perlu
          tooltip: 'Add Password',
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: Icon(Symbols.add_rounded, size: 28, weight: 700),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Lokasi ini seharusnya sudah benar
      );
    }

  Widget _buildPasswordCard(PasswordModel password) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 12),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => _showPasswordDetails(password),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: 'password_icon_${password.id}',
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getIconForAccountType(password.accountType),
                    color: colorScheme.onSecondaryContainer,
                    size: 28,
                    weight: 500,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      password.accountName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      password.username,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Symbols.arrow_forward_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                  weight: 500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
