import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ViewReplyScreen extends StatefulWidget {
  @override
  _ViewReplyScreenState createState() => _ViewReplyScreenState();
}

class _ViewReplyScreenState extends State<ViewReplyScreen> {
  List<dynamic> complaints = [];
  bool _isLoading = true;
  String? _lid;

  @override
  void initState() {
    super.initState();
    _loadReplies();
  }

  Future<void> _loadReplies() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _lid = prefs.getString('lid') ?? '';
    String url = prefs.getString('url') ?? '';

    if (_lid == null || _lid!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login required")),
      );
      Navigator.pop(context);
      return;
    }

    try {
      var response = await http.post(
        Uri.parse('$url/viewreply/'),
        body: {'lid': _lid},
      );

      var data = json.decode(response.body);
      if (data['status'] == 'ok') {
        setState(() {
          complaints = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error loading replies: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Complaint Replies"),
        backgroundColor: Colors.purple,
        elevation: 2,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : complaints.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.markunread_mailbox, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No replies yet",
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Your complaints will appear here once replied",
                        style: TextStyle(color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReplies,
                  child: ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: complaints.length,
                    itemBuilder: (context, index) {
                      var c = complaints[index];
                      bool hasReply = c['reply'] != null && c['reply'].toString().trim().isNotEmpty;

                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: hasReply ? Colors.green : Colors.orange,
                            child: Icon(
                              hasReply ? Icons.check_circle : Icons.pending,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            "Complaint #${c['id']}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            c['date'],
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          children: [
                            Divider(height: 1),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Your Complaint
                                  Text(
                                    "Your Complaint:",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    c['complaint'],
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  SizedBox(height: 16),

                                  // Admin Reply
                                  Text(
                                    "Admin Reply:",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    hasReply ? c['reply'] : "Pending...",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontStyle: hasReply ? FontStyle.normal : FontStyle.italic,
                                      color: hasReply ? Colors.black87 : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/send_complaint');
        },
        child: Icon(Icons.add_comment),
        backgroundColor: Colors.purple,
        tooltip: "Send New Complaint",
      ),
    );
  }
}