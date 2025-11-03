import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ViewFriendRequestsScreen extends StatefulWidget {
  @override
  _ViewFriendRequestsScreenState createState() => _ViewFriendRequestsScreenState();
}

class _ViewFriendRequestsScreenState extends State<ViewFriendRequestsScreen> {
  List<dynamic> requests = [];
  bool _isLoading = true;
  String? _lid;

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
  }

  Future<void> _loadFriendRequests() async {
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
        Uri.parse('$url/viewfriendrequest/'),
        body: {'lid': _lid},
      );

      var data = json.decode(response.body);
      if (data['status'] == 'ok') {
        setState(() {
          requests = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptRequest(int reqId, int fromUserId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = prefs.getString('url') ?? '';

    try {
      var response = await http.post(
        Uri.parse('$url/accept/'),
        body: {
          'req_id': reqId.toString(),
          'from_user_id': fromUserId.toString(),
          'lid': _lid,
        },
      );

      var data = json.decode(response.body);
      if (data['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Friend request accepted!"), backgroundColor: Colors.green),
        );
        _loadFriendRequests(); // Refresh
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to accept")),
      );
    }
  }

  Future<void> _rejectRequest(int reqId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = prefs.getString('url') ?? '';

    try {
      var response = await http.post(
        Uri.parse('$url/reject/'),
        body: {
          'req_id': reqId.toString(),
          'lid': _lid,
        },
      );

      var data = json.decode(response.body);
      if (data['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Request rejected"), backgroundColor: Colors.orange),
        );
        _loadFriendRequests();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to reject")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Friend Requests"),
        backgroundColor: Colors.teal,
        elevation: 2,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_disabled, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No pending friend requests",
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    var req = requests[index];
                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(req['photo'] ?? ''),
                          child: req['photo'] == null || req['photo'].isEmpty
                              ? Text(
                                  req['name'][0].toUpperCase(),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        title: Text(
                          req['name'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Wants to connect with you"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Accept Button
                            ElevatedButton(
                              onPressed: () => _acceptRequest(req['id'], req['from_user_id']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: Text("Accept", style: TextStyle(fontSize: 12)),
                            ),
                            SizedBox(width: 8),
                            // Reject Button
                            OutlinedButton(
                              onPressed: () => _rejectRequest(req['id']),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: Text("Reject", style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}