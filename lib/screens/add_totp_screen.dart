import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/totp_service.dart';

class AddTOTPScreen extends StatefulWidget {
  @override
  _AddTOTPScreenState createState() => _AddTOTPScreenState();
}

class _AddTOTPScreenState extends State<AddTOTPScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _secretController = TextEditingController();
  final TOTPService _totpService = TOTPService();
  bool _isLoading = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _secretController.dispose();
    super.dispose();
  }
  
  void _generateRandomSecret() {
    setState(() {
      _secretController.text = _totpService.generateSecret();
    });
  }
  
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _totpService.addTOTP(
        name: _nameController.text.trim(),
        secret: _secretController.text.trim().toUpperCase().replaceAll(' ', ''),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New TOTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Account Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Account Name cannot be empty';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Menghapus field Publisher (Optional)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _secretController,
                      decoration: InputDecoration(
                        labelText: 'Secret Key',
                        border: OutlineInputBorder(),
                        hintText: 'Example: JBSWY3DPEHPK3PXP',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Secret key cannot be empty';
                        }
                        // Validasi format base32
                        final cleanValue = value.toUpperCase().replaceAll(' ', '');
                        final base32Regex = RegExp(r'^[A-Z2-7]+=*$');
                        if (!base32Regex.hasMatch(cleanValue)) {
                          return 'Secret key must be in Base32 format';
                        }
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _generateRandomSecret,
                    tooltip: 'Generate Secret Key',
                  ),
                ],
              ),
              SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Save'),
                style: FilledButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}