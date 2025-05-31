import 'package:flutter/material.dart';
import '../services/password_service.dart';

class AddPasswordScreen extends StatefulWidget {
  const AddPasswordScreen({Key? key}) : super(key: key);

  @override
  _AddPasswordScreenState createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordService = PasswordService();
  
  String _selectedAccountType = 'Custom Account';
  final _accountNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  
  final List<String> _accountTypes = [
    'Google',
    'Microsoft',
    'Discord',
    'TikTok',
    'Facebook',
    'Twitter',
    'Instagram',
    'GitHub',
    'LinkedIn',
    'Amazon',
    'Apple',
    'Netflix',
    'Spotify',
    'Custom Account',
  ];

  @override
  void dispose() {
    _accountNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Metode untuk menyimpan password dengan penanganan error yang lebih baik
  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Aktifkan loading state
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Tentukan nama akun (gunakan tipe akun jika nama kosong)
      String accountName = _accountNameController.text.trim();
      if (accountName.isEmpty) {
        accountName = _selectedAccountType;
      }
      
      // Simpan password
      await _passwordService.addPassword(
        accountType: _selectedAccountType,
        accountName: accountName,
        username: _usernameController.text,
        password: _passwordController.text,
      );
      
      // Pastikan widget masih mounted sebelum mengakses context
      if (!mounted) return;
      
      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password saved successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Kembali ke layar sebelumnya
      Navigator.of(context).pop();
    } catch (e) {
      // Pastikan widget masih mounted sebelum mengakses context
      if (!mounted) return;
      
      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      // Pastikan widget masih mounted sebelum mengubah state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
      appBar: AppBar(
        title: Text('Add Password', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(24),
          children: [
            Text(
              'Account Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 24),
            
            // Account Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedAccountType,
              decoration: InputDecoration(
                labelText: 'Account Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(_getIconForAccountType(_selectedAccountType)),
              ),
              items: _accountTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedAccountType = value;
                    
                    // Reset account name if it matches the previous account type
                    if (_accountNameController.text == _selectedAccountType) {
                      _accountNameController.clear();
                    }
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select an account type';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            
            // Account Name Field (Optional)
            TextFormField(
              controller: _accountNameController,
              decoration: InputDecoration(
                labelText: 'Account Name (Optional)',
                hintText: 'Leave empty to use Account Type as name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 24),
            
            // Username/Email Field
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username or Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.person),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username or email';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            
            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                return null;
              },
            ),
            SizedBox(height: 32),
            
            // Generate Password Button
            FilledButton.tonal(
              onPressed: () {
                // Generate a random secure password
                final password = _generateSecurePassword();
                _passwordController.text = password;
              },
              style: FilledButton.styleFrom(
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Generate Secure Password'),
            ),
            SizedBox(height: 24),
            
            // Save Button
            FilledButton(
              onPressed: _isLoading ? null : _savePassword,
              style: FilledButton.styleFrom(
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Text('Save Password'),
            ),
          ],
        ),
      ),
    );
  }
  
  String _generateSecurePassword() {
    const String uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
    const String numericChars = '0123456789';
    const String specialChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    
    final random = DateTime.now().millisecondsSinceEpoch;
    final passwordLength = 16;
    
    String password = '';
    
    // Ensure at least one character from each category
    password += uppercaseChars[random % uppercaseChars.length];
    password += lowercaseChars[(random ~/ 10) % lowercaseChars.length];
    password += numericChars[(random ~/ 100) % numericChars.length];
    password += specialChars[(random ~/ 1000) % specialChars.length];
    
    // Fill the rest with random characters from all categories
    final allChars = uppercaseChars + lowercaseChars + numericChars + specialChars;
    for (int i = password.length; i < passwordLength; i++) {
      password += allChars[(random ~/ (i * 1000)) % allChars.length];
    }
    
    // Shuffle the password characters
    final passwordChars = password.split('');
    passwordChars.shuffle();
    
    return passwordChars.join();
  }
}
