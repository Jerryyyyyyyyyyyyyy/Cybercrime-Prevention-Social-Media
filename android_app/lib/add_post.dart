import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path/path.dart' as path;

class AddPostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  File? _image;
  final TextEditingController _captionController = TextEditingController();
  bool _isLoading = false;
  String? _aiResult;
  Interpreter? _interpreter;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _interpreter?.close();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      final interpreter = await Interpreter.fromAsset('assets/models/bullying_model.tflite');
      setState(() {
        _interpreter = interpreter;
      });
      print('AI Model loaded successfully');
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _aiResult = null;
      });
      await _runAIDetection();
    }
  }

  Future<void> _runAIDetection() async {
    if (_image == null || _interpreter == null) return;

    setState(() {
      _isLoading = true;
      _aiResult = 'Analyzing...';
    });

    try {
      // Simulate AI detection (Replace with actual TFLite inference)
      await Future.delayed(Duration(seconds: 2));

      final caption = _captionController.text.toLowerCase();
      final hasBullying = caption.contains('stupid') ||
          caption.contains('ugly') ||
          caption.contains('hate') ||
          caption.contains('idiot');

      setState(() {
        _aiResult = hasBullying ? 'Bullying Words Detected' : 'Safe Content';
      });
    } catch (e) {
      setState(() {
        _aiResult = 'AI Error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadPost() async {
    if (_image == null || _captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add image and caption')),
      );
      return;
    }

    if (_aiResult == 'Bullying Words Detected') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot post: Bullying content detected')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final token = prefs.getString('token');

      if (userId == null || token == null) {
        throw Exception('Not logged in');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/myapp/add_post/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['user_id'] = userId.toString();
      request.fields['desc'] = _captionController.text;

      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          _image!.path,
          filename: path.basename(_image!.path),
        ));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post uploaded successfully!')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
        title: Text('Add New Post'),
        backgroundColor: Color(0xFF1e3c72),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Image Preview
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('Tap to add photo', style: TextStyle(color: Colors.grey)),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
            ),

            SizedBox(height: 20),

            // Image Picker Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildPickerButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),

            SizedBox(height: 25),

            // Caption Field
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write a caption...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF00d4ff), width: 2),
                ),
              ),
              onChanged: (value) => _runAIDetection(),
            ),

            SizedBox(height: 15),

            // AI Status
            if (_aiResult != null)
              Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: _aiResult!.contains('Bullying')
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  border: Border.all(
                    color: _aiResult!.contains('Bullying')
                        ? Colors.red.shade300
                        : Colors.green.shade300,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _aiResult!.contains('Bullying')
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle,
                      color: _aiResult!.contains('Bullying')
                          ? Colors.red
                          : Colors.green,
                    ),
                    SizedBox(width: 10),
                    Text(
                      _aiResult!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _aiResult!.contains('Bullying')
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 30),

            // Post Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00d4ff),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'POST NOW',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1e3c72),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}