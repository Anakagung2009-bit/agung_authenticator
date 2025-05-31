import 'package:flutter/material.dart';
import '../services/totp_service.dart';
import 'qr_code_screen.dart';

class SelectCodesScreen extends StatefulWidget {
  @override
  _SelectCodesScreenState createState() => _SelectCodesScreenState();
}

class _SelectCodesScreenState extends State<SelectCodesScreen> {
  final TOTPService _totpService = TOTPService();
  List<Map<String, dynamic>> _totps = [];
  Map<String, bool> _selectedTotps = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTotps();
  }

  Future<void> _loadTotps() async {
    try {
      final totps = await _totpService.getTOTPs().first;
      setState(() {
        _totps = totps;
        _isLoading = false;
        // Initialize selection map
        for (var totp in totps) {
          _selectedTotps[totp['id']] = false;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading codes: ${e.toString()}')),
      );
    }
  }

  bool get _hasSelectedTotps => _selectedTotps.values.any((selected) => selected);

  List<Map<String, dynamic>> get _getSelectedTotps {
    return _totps.where((totp) => _selectedTotps[totp['id']] == true).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Codes to Export'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _totps.isEmpty
              ? Center(
                  child: Text('No authenticator codes found'),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Select the authenticator codes you want to export',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _totps.length,
                        itemBuilder: (context, index) {
                          final totp = _totps[index];
                          final id = totp['id'];
                          
                          return CheckboxListTile(
                            title: Text(totp['name']),
                            subtitle: Text('Secret: ${_maskSecret(totp['secret'])}'),
                            value: _selectedTotps[id] ?? false,
                            onChanged: (value) {
                              setState(() {
                                _selectedTotps[id] = value!;
                              });
                            },
                            activeColor: colorScheme.primary,
                            checkColor: colorScheme.onPrimary,
                          );
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    for (var id in _selectedTotps.keys) {
                      _selectedTotps[id] = !_hasSelectedTotps;
                    }
                  });
                },
                child: Text(_hasSelectedTotps ? 'Unselect All' : 'Select All'),
              ),
              FilledButton(
                onPressed: _hasSelectedTotps
                    ? () => _navigateToQRCode(context)
                    : null,
                child: Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _maskSecret(String secret) {
    if (secret.length <= 4) return '****';
    return '${secret.substring(0, 2)}${'*' * (secret.length - 4)}${secret.substring(secret.length - 2)}';
  }

  void _navigateToQRCode(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCodeScreen(selectedTotps: _getSelectedTotps),
      ),
    );
  }
}