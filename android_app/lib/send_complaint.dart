import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SendComplaintScreen extends StatefulWidget {
  @override
  _SendComplaintScreenState createState() => _SendComplaintScreenState();
}

class _SendComplaintScreenState extends State<SendComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _complaintController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lid = prefs.getString('lid');
    String url = prefs.getString('url') ?? '';

    if (lid == null || lid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please login first")),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      var response = await http.post(
        Uri.parse('$url/sendcomplaint/'),
        body: {
          'lid': lid,
          'complaint': _complaintController.text,
        },
      );

      var data = json.decode(response.body);

      if (data['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Complaint sent successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        _complaintController.clear();
        Navigator.pop(context); // Go back after success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${data['message'] ?? 'Try again'}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Send Complaint"),
        backgroundColor: Colors.redAccent,
        elevation: 2,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                "Report an Issue",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Complaint Text Field
              TextFormField(
                controller: _complaintController,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: "Describe your complaint",
                  hintText: "e.g., I saw a bullying post, user is harassing, etc.",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please write your complaint";
                  }
                  if (value.trim().length < 10) {
                    return "Complaint too short (min 10 chars)";
                  }
                  return null;
                },
              ),

              SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _sendComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Send Complaint",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),

              SizedBox(height: 10),

              // View Replies Link
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/view_reply');
                },
                child: Text(
                  "View Admin Replies",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }
}