import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/auth_check.dart';
import 'services/theme_service.dart';
import 'services/totp_service.dart';

import 'services/update_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const platform = MethodChannel('com.example.agung_auth/widget');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Atur navigation bar & status bar transparan
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Fungsi untuk update widget
  Future<void> updateWidget() async {
    try {
      await platform.invokeMethod('updateWidget');
    } on PlatformException catch (e) {
      print("Failed to update widget: '${e.message}'.");
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: const MyAppWithTheme(),
    ),
    
  );
}

class MyAppWithTheme extends StatelessWidget {
  const MyAppWithTheme({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamicColor, ColorScheme? darkDynamicColor) {
        return MaterialApp(
          title: 'Agung Auth',
          theme: themeService.getLightTheme(lightDynamicColor),
          darkTheme: themeService.getDarkTheme(darkDynamicColor),
          themeMode: themeService.themeMode,
          debugShowCheckedModeBanner: false,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  final TOTPService _totpService = TOTPService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncEncryptionKey();

      // Tambahkan ini untuk auto check update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context);
    });
  }

  Future<void> _syncEncryptionKey() async {
    try {
      await _totpService.syncEncryptionKey();
    } catch (e) {
      print('Error saat sinkronisasi kunci enkripsi: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      AuthCheck.resetAuthentication();
    } else if (state == AppLifecycleState.resumed) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return LoginScreen();
          }

          return FutureBuilder<bool>(
            future: AuthCheck.authenticate(context),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  extendBody: true,
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (authSnapshot.data == true) {
                return const HomeScreen();
              }

              return Scaffold(
                extendBody: true,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Needed Authenticate'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return const Scaffold(
          extendBody: true,
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
