import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/totp_service.dart';
import 'dart:async'; // Tambahkan import ini untuk class Timer

class TOTPWidget extends StatefulWidget {
  @override
  _TOTPWidgetState createState() => _TOTPWidgetState();
}

class _TOTPWidgetState extends State<TOTPWidget> {
  final TOTPService _totpService = TOTPService();
  List<Map<String, dynamic>> _totps = [];
  int _timeLeft = 30;
  int _currentPeriod = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadTotps();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
            _loadTotps();
          } else {
            // Hanya perbarui timer
            _timeLeft = 30 - (newNow % 30);
          }
        });
      }
    });
  }

  Future<void> _loadTotps() async {
    _totpService.getTOTPs().first.then((totps) {
      if (mounted) {
        setState(() {
          _totps = totps;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF4285F4),
          secondary: Color(0xFF34A853),
          surface: Colors.black,
          background: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header dengan logo dan pengaturan
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.security, color: Colors.white, size: 16),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Agung Authenticator',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.settings, color: Colors.white, size: 20),
                  ],
                ),
              ),
              // Daftar kode TOTP
              _totps.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No authentication codes',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _totps.length > 4 ? 4 : _totps.length, // Batasi jumlah yang ditampilkan
                      itemBuilder: (context, index) {
                        final totp = _totps[index];
                        final code = _totpService.generateTOTP(
                          totp['secret'],
                          counter: _currentPeriod,
                        );
                        
                        // Tampilkan kartu TOTP seperti di gambar
                        return TOTPItemWidget(
                          name: totp['name'],
                          code: code,
                          timeLeft: _timeLeft,
                          icon: _getIconForService(totp['name']),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper untuk mendapatkan ikon berdasarkan nama layanan
  Widget _getIconForService(String name) {
    name = name.toLowerCase();
    
    if (name.contains('dropbox')) {
      return Icon(Icons.cloud, color: Colors.blue);
    } else if (name.contains('amazon')) {
      return Icon(Icons.shopping_cart, color: Colors.orange);
    } else if (name.contains('slack')) {
      return Icon(Icons.chat_bubble, color: Colors.purple);
    } else if (name.contains('gmail') || name.contains('google')) {
      return Icon(Icons.mail, color: Colors.red);
    } else {
      // Default icon
      return Icon(Icons.security, color: Colors.grey);
    }
  }
}

// Widget untuk item TOTP individual
class TOTPItemWidget extends StatelessWidget {
  final String name;
  final String code;
  final int timeLeft;
  final Widget icon;

  const TOTPItemWidget({
    Key? key,
    required this.name,
    required this.code,
    required this.timeLeft,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format kode dengan spasi di tengah seperti di gambar
    final formattedCode = code.length > 3 
        ? '${code.substring(0, 3)} ${code.substring(3)}' 
        : code;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Ikon layanan
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: icon,
          ),
          SizedBox(width: 16),
          // Nama layanan
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          // Kode dan timer
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    formattedCode,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.copy, color: Colors.white, size: 16),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Expires in: ${timeLeft}s',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}