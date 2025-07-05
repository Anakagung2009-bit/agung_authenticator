import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/password_service.dart';
import '../components/account_icon.dart'; // Import widget baru

class AddPasswordScreen extends StatefulWidget {
  const AddPasswordScreen({Key? key}) : super(key: key);

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
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

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final String accountType = _selectedAccountType;
    final String accountNameText = _accountNameController.text.trim();
    final String username = _usernameController.text;
    final String password = _passwordController.text;
    
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    
    bool success = false;
    String? errorMessage;
    
    try {
      final String accountName = accountNameText.isEmpty ? accountType : accountNameText;
      
      await _passwordService.addPassword(
        accountType: accountType,
        accountName: accountName,
        username: username,
        password: password,
      );
      
      success = true;
    } catch (e) {
      errorMessage = e.toString();
    }
    
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        Navigator.of(context).pop();
      } else if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Password', style: TextStyle(fontWeight: FontWeight.bold)),
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
            
            // Account Type Dropdown dengan icon baru
            DropdownButtonFormField<String>(
              value: _selectedAccountType,
              decoration: InputDecoration(
                labelText: 'Account Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Padding(
                  padding: EdgeInsets.all(12),
                  child: AccountIcon(
                    accountType: _selectedAccountType,
                    size: 24,
                  ),
                ),
              ),
              items: _accountTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Row(
                    children: [
                      AccountIcon(
                        accountType: type,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(type),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedAccountType = value;
                    
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
                final password = _generateSecurePassword();
                _passwordController.text = password;
              },
              style: FilledButton.styleFrom(
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
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
                  borderRadius: BorderRadius.circular(100),
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
    
    password += uppercaseChars[random % uppercaseChars.length];
    password += lowercaseChars[(random ~/ 10) % lowercaseChars.length];
    password += numericChars[(random ~/ 100) % numericChars.length];
    password += specialChars[(random ~/ 1000) % specialChars.length];
    
    final allChars = uppercaseChars + lowercaseChars + numericChars + specialChars;
    for (int i = password.length; i < passwordLength; i++) {
      password += allChars[(random ~/ (i * 1000)) % allChars.length];
    }
    
    final passwordChars = password.split('');
    passwordChars.shuffle();
    
    return passwordChars.join();
  }
}