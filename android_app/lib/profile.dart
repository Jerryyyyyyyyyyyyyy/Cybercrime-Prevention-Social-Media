import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  // Form Fields
  TextEditingController nameController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController placeController = TextEditingController();
  TextEditingController postController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController pinController = TextEditingController();
  TextEditingController districtController = TextEditingController();

  File? _image;
  String? _currentPhoto;
  String? _lid;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _lid = prefs.getString('lid') ?? '';

    if (_lid == null || _lid!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login required")),
      );
      Navigator.pop(context);
      return;
    }

    String url = prefs.getString('url') ?? '';
    String imgUrl = prefs.getString('img_url') ?? '';

    try {
      var response = await http.post(
        Uri.parse('$url/viewprofile/'),
        body: {'lid': _lid},
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'ok') {
          var user = data['data'][0];
          setState(() {
            nameController.text = user['name'];
            dobController.text = user['dob'];
            genderController.text = user['gender'];
            emailController.text = user['email'];
            phoneController.text = user['phone'];
            placeController.text = user['place'];
            postController.text = user['post'];
            stateController.text = user['state'];
            pinController.text = user['pin'];
            districtController.text = user['district'];
            _currentPhoto = user['photo'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error loading profile: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = prefs.getString('url') ?? '';

    var request = http.MultipartRequest('POST', Uri.parse('$url/user_editprofile/'));
    request.fields.addAll({
      'lid': _lid!,
      'name': nameController.text,
      'dob': dobController.text,
      'gender': genderController.text,
      'email': emailController.text,
      'phone': phoneController.text,
      'place': placeController.text,
      'post': postController.text,
      'state': stateController.text,
      'pin': pinController.text,
      'district': districtController.text,
    });

    if (_image != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', _image!.path));
    }

    try {
      var response = await request.send();
      var respStr = await response.stream.bytesToString();
      var data = json.decode(respStr);

      if (data['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile updated successfully!")),
        );
        _loadUserProfile(); // Refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: ${data['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Profile"),
        backgroundColor: Colors.blueGrey,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Photo
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _image != null
                              ? FileImage(_image!)
                              : (_currentPhoto != null && _currentPhoto!.isNotEmpty)
                                  ? NetworkImage('$_currentPhoto')
                                  : AssetImage('assets/placeholder.png') as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: _pickImage,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Form Fields
                    _buildTextField(nameController, "Name"),
                    _buildTextField(dobController, "Date of Birth (YYYY-MM-DD)"),
                    _buildTextField(genderController, "Gender"),
                    _buildTextField(emailController, "Email", keyboardType: TextInputType.emailAddress),
                    _buildTextField(phoneController, "Phone", keyboardType: TextInputType.phone),
                    _buildTextField(placeController, "Place"),
                    _buildTextField(postController, "Post"),
                    _buildTextField(stateController, "State"),
                    _buildTextField(districtController, "District"),
                    _buildTextField(pinController, "PIN Code", keyboardType: TextInputType.number),

                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: Text("Update Profile", style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Required';
          return null;
        },
      ),
    );
  }
}