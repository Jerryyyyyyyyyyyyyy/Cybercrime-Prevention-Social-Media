import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_screen.dart';

class ViewFriendsScreen extends StatefulWidget {
  @override
  _ViewFriendsScreenState createState() => _ViewFriendsScreenState();
}

class _ViewFriendsScreenState extends State<ViewFriendsScreen> {
  List<dynamic> friends = [];
  bool _isLoading = true;
  String? _lid;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
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
        Uri.parse('$url/viewfriends/'),
        body: {'lid': _lid},
      );

      var data = json.decode(response.body);
      if (data['status'] == 'ok') {
        setState(() {
          friends = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error loading friends: $e");
      setState(() => _isLoading = false);
    }
  }

  void _openChat(String friendId, String friendName, String friendPhoto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          friendId: friendId,
          friendName: friendName,
          friendPhoto: friendPhoto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Friends"),
        backgroundColor: Colors.indigo,
        elevation: 2,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : friends.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No friends yet",
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Send friend requests to connect!",
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    var friend = friends[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(friend['photo'] ?? ''),
                          child: friend['photo'] == null || friend['photo'].isEmpty
                              ? Text(
                                  friend['name'][0].toUpperCase(),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                )
                              : null,
                          backgroundColor: Colors.indigo,
                        ),
                        title: Text(
                          friend['name'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Tap to chat"),
                        trailing: Icon(Icons.chat, color: Colors.indigo),
                        onTap: () => _openChat(
                          friend['lid'],
                          friend['name'],
                          friend['photo'] ?? '',
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/view_other_users');
        },
        child: Icon(Icons.person_add),
        backgroundColor: Colors.indigo,
        tooltip: "Add Friends",
      ),
    );
  }
}