import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../main.dart'; // For cameras
import 'home.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  CameraController? _cameraController;
  final faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      mode: FaceDetectorMode.accurate,
    ),
  );

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isFaceDetected = false;
  String? _statusMessage;
  String? _capturedFacePath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) return;

    _cameraController = CameraController(cameras[1], ResolutionPreset.medium);
    await _cameraController!.initialize();
    if (mounted) setState(() {});
    _startFaceDetection();
  }

  void _startFaceDetection() async {
    if (!_cameraController!.value.isStreamingImages) {
      await _cameraController!.startImageStream(_processCameraImage);
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isFaceDetected || _isLoading) return;

    final inputImage = _convertCameraImage(image);
    if (inputImage == null) return;

    final faces = await faceDetector.processImage(inputImage);
    if (faces.isNotEmpty && faces.first.smilingProbability! > 0.7) {
      setState(() {
        _isFaceDetected = true;
        _statusMessage = 'Face detected! Capturing...';
      });
      await _captureFace();
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final InputImageRotation rotation = InputImageRotation.rotation270deg;
    final InputImageFormat format = InputImageFormat.nv21;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: rotation,
      inputImageFormat: format,
      planeData: planeData,
    );

    return InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
  }

  Future<void> _captureFace() async {
    if (!_cameraController!.value.isInitialized) return;

    try {
      final xFile = await _cameraController!.takePicture();
      setState(() {
        _capturedFacePath = xFile.path;
        _statusMessage = 'Face captured! Logging in...';
      });
      await _loginWithFace();
    } catch (e) {
      setState(() {
        _statusMessage = 'Capture failed';
      });
    }
  }

  Future<void> _loginWithFace() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty || _capturedFacePath == null) {
      setState(() {
        _statusMessage = 'Fill all fields and capture face';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = await DeviceService.getImei() ?? 'unknown';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/myapp/face_login/'),
      );

      request.fields['username'] = _usernameController.text;
      request.fields['password'] = _passwordController.text;
      request.fields['device_id'] = deviceId;

      if (_capturedFacePath != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'face',
          _capturedFacePath!,
          filename: path.basename(_capturedFacePath!),
        ));
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);

      if (response.statusCode == 200 && data['status'] == 'success') {
        await prefs.setString('token', data['token']);
        await prefs.setInt('user_id', data['user_id']);
        await prefs.setString('name', data['name']);
        await prefs.setString('photo', data['photo']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        setState(() {
          _statusMessage = data['message'] ?? 'Login failed';
        });
      }
    } catch (e) {
        setState(() {
          _statusMessage = 'Network error';
        });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1e3c72),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              // Logo
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/logo.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: 20),

              Text(
                'CYBERGUARD',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Secure Login with Face + IMEI',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 30),

              // Camera Preview
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _isFaceDetected ? Colors.green : Colors.white30, width: 3),
                ),
                child: _cameraController?.value.isInitialized == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: CameraPreview(_cameraController!),
                      )
                    : Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
              SizedBox(height: 10),
              Text(
                _statusMessage ?? 'Look at camera and smile!',
                style: TextStyle(color: _isFaceDetected ? Colors.green : Colors.white70),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 25),

              // Username
              _buildTextField(
                controller: _usernameController,
                hint: 'Username',
                icon: Icons.person,
              ),
              SizedBox(height: 16),

              // Password
              _buildTextField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock,
                obscure: true,
              ),
              SizedBox(height: 30),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading || !_isFaceDetected ? null : _loginWithFace,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00d4ff),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'LOGIN SECURELY',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: Text(
                  'New User? Register',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF00d4ff), width: 2),
        ),
      ),
    );
  }
}