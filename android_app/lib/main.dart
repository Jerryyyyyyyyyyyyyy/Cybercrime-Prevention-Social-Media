import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/add_post.dart';
import 'screens/chat_screen.dart';
import 'screens/change_password.dart';
import 'screens/register.dart'; // You'll create this next

// Global camera list
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CYBERGUARD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF1e3c72),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Color(0xFF00d4ff),
        ),
      ),
      home: SplashScreen(),
      routes: {
        '/login': (_) => LoginScreen(),
        '/home': (_) => HomeScreen(),
        '/add_post': (_) => AddPostScreen(),
        '/change_password': (_) => ChangePasswordScreen(),
        '/register': (_) => RegisterScreen(), // Next file
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    await Future.delayed(Duration(seconds: 3)); // Splash duration

    if (token != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logo.png',
            width: 140,
            height: 140,
          ),
          SizedBox(height: 20),
          Text(
            'CYBERGUARD',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1e3c72),
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Preventing Cybercrime on Social Media',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      nextScreen: Container(), // Will be replaced by _checkLoginStatus
      splashTransition: SplashTransition.fadeTransition,
      pageTransitionType: PageTransitionType.bottomToTop,
      backgroundColor: Colors.white,
      duration: 3000,
    );
  }
}

// Device Service (IMEI from MainActivity.kt)
class DeviceService {
  static const platform = MethodChannel('com.cyberguard/device_info');

  static Future<String?> getImei() async {
    try {
      return await platform.invokeMethod('getImei');
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getDeviceId() async {
    try {
      return await platform.invokeMethod('getDeviceId');
    } catch (e) {
      return null;
    }
  }
}