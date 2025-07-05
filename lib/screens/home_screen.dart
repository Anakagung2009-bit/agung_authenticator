import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/totp_service.dart';
import 'add_totp_screen.dart';
import 'scan_qr_screen.dart';
import '../components/custom_app_bar.dart';
import '../components/code_card.dart';
import '../components/empty_state.dart';
import '../components/no_search_results.dart';
import 'export_authenticator_screen.dart';
import 'passwords_screen.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TOTPService _totpService = TOTPService();
  Timer? _timer;
  int _timeLeft = 30;
  int _currentPeriod = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // FIX: Tambahkan variable yang hilang
  List<Map<String, dynamic>> _totps = []; // Variable yang hilang!
  List<Map<String, dynamic>>? _cachedTotps;
  bool _isLoading = true;
  bool _isFabExpanded = false;
  
  // Bottom navigation
  int _selectedIndex = 0;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadTotps();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _loadInitialData();
    
    // Initialize tab controller
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  void _loadInitialData() async {
    _totpService.getTOTPs().first.then((totps) {
      if (mounted) {
        setState(() {
          _cachedTotps = totps;
          _totps = totps;
          _isLoading = false;
        });
        // PENTING: Update widget setelah data dimuat
        WidgetService.updateWidgetData(_totps);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _startTimer() {
    // Sinkronkan timer dengan periode 30 detik dari epoch time
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final currentPeriod = now ~/ 30;
    _currentPeriod = currentPeriod;
    _timeLeft = 30 - (now % 30);

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      final newNow = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final newPeriod = newNow ~/ 30;
      
      if (mounted) {
        setState(() {
          if (newPeriod > _currentPeriod) {
            // Periode TOTP telah berubah, perlu memperbarui kode
            _currentPeriod = newPeriod;
            _timeLeft = 30 - (newNow % 30);
            
            // Hanya muat ulang data ketika periode berubah
            _refreshTotpData();
          } else {
            // Hanya perbarui timer, tidak perlu memuat ulang data
            _timeLeft = 30 - (newNow % 30);
          }
        });
        
        // Update widget setiap detik untuk countdown
        WidgetService.updateWidget();
      }
    });
  }
  
    void _refreshTotpData() {
    _totpService.getTOTPs().first.then((totps) {
      if (mounted) {
        setState(() {
          _cachedTotps = totps;
          _totps = totps;
        });
        // PENTING: Update widget setelah data di-refresh
        WidgetService.updateWidgetData(_totps);
      }
    });
  }

  void _showExportDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExportAuthenticatorScreen()),
    );
  }

  void _showHowItWorksDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('How TOTP works'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TOTP (Time-based One-Time Password) is:'),
            SizedBox(height: 8),
            Text('• Temporary code that changes every 30 seconds'),
            Text('• Based on current time and secret key'),
            Text('• Used for two-factor authentication (2FA)'),
            Text('• Helps secure your account from hacking'),
            SizedBox(height: 16),
            Text('This app stores your secret keys securely and syncs them across all your devices.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      extendBody: true,
      key: _scaffoldKey,
      backgroundColor: colorScheme.surface,
      appBar: _selectedIndex == 0
        ? CustomAppBar(
            searchController: _searchController,
            onMenuPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          )
        : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Authenticator Tab
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _isLoading 
                    ? Center(
                        child: CircularProgressIndicator.adaptive(
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        )
                      )
                    : _buildTotpList(colorScheme),
                ),
              ],
            ),
          ),
          // Passwords Tab
          PasswordsScreen(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 
        ? Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_isFabExpanded) ...[
            FloatingActionButton(
              heroTag: 'sync',
              onPressed: _syncTOTPData,
              mini: true,
              tooltip: 'Sync TOTP Data',
              child: Icon(Icons.sync),
            ),
            SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'scan',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScanQRScreen()),
                ).then((_) => _refreshTotpData());
              },
              mini: true,
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              elevation: 4,
              child: Icon(Icons.qr_code_scanner),
            ),
            SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'add_code',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddTOTPScreen()),
                ).then((_) => _refreshTotpData());
              },
              mini: true,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Icon(Icons.vpn_key),
              tooltip: 'Add Code',
            ),
            SizedBox(height: 16),
          ],
          FloatingActionButton.extended(
            heroTag: 'toggle_add',
            onPressed: () {
              setState(() {
                _isFabExpanded = !_isFabExpanded;
              });
            },
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            icon: Icon(_isFabExpanded ? Icons.close : Icons.add),
            label: Text(_isFabExpanded ? 'Close' : 'Add Code'),
          ),
        ],
      ) : null,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
            _tabController.animateTo(index);
          });
        },
        selectedIndex: _selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.security),
            label: 'Authenticator',
          ),
          NavigationDestination(
            icon: Icon(Icons.password),
            label: 'Passwords',
          ),
        ],
      ),
    );
  }
  
  Widget _buildTotpList(ColorScheme colorScheme) {
    if (_cachedTotps == null) {
      return Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        )
      );
    }
    
    if (_cachedTotps!.isEmpty) {
      return EmptyState();
    }
    
    // Filter TOTP berdasarkan pencarian
    final filteredTotps = _cachedTotps!.where((totp) {
      final name = totp['name']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();
    
    if (filteredTotps.isEmpty) {
      return NoSearchResults();
    }
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: filteredTotps.length,
      itemBuilder: (context, index) {
        final totp = filteredTotps[index];
        final code = _totpService.generateTOTP(
          totp['secret'],
          counter: _currentPeriod,
        );
        
        return Card(
          elevation: 0,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: CodeCard(
            totp: totp,
            code: code,
            timeLeft: _timeLeft,
            onDelete: () {
              _totpService.deleteTOTP(totp['id']).then((_) {
                _refreshTotpData();
              });
            },
          ),
        );
      },
    );
  }

  Future<void> _syncTOTPData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _totpService.syncEncryptionKey();
      if (!result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sync data')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data successfully synced')),
        );
        // Setelah sync, refresh data TOTP
        _refreshTotpData();
      }
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

  // FIX: Perbaiki method _loadTotps
  Future<void> _loadTotps() async {
    _totpService.getTOTPs().first.then((totps) {
      if (mounted) {
        setState(() {
          _totps = totps;
          _cachedTotps = totps; // Update kedua variable
        });
        // Update widget data setiap kali TOTP di-load
        WidgetService.updateWidgetData(_totps);
      }
    });
  }
}

// Widget Service untuk komunikasi dengan Android Widget
// Di home_screen.dart, update WidgetService
class WidgetService {
  static const platform = MethodChannel('com.example.agung_auth/widget');

  static Future<void> updateWidgetData(List<Map<String, dynamic>> totps) async {
    try {
      // Convert TOTP data to JSON dengan format yang benar
      final widgetData = totps.map((totp) => {
        'name': totp['name'] ?? 'Unknown',
        'secret': totp['secret'] ?? '',
      }).toList();
      
      final jsonString = jsonEncode(widgetData);
      
      print('Sending widget data: $jsonString'); // Debug log
      
      await platform.invokeMethod('updateWidgetData', {
        'totpData': jsonString,
      });
      
      // Juga update widget setelah data dikirim
      await platform.invokeMethod('updateWidget');
      
      print('Widget data updated successfully');
    } catch (e) {
      print('Error updating widget data: $e');
    }
  }

  static Future<void> updateWidget() async {
    try {
      await platform.invokeMethod('updateWidget');
    } catch (e) {
      print('Error updating widget: $e');
    }
  }
}