import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'view_comments.dart';

class ViewPostScreen extends StatefulWidget {
  @override
  _ViewPostScreenState createState() => _ViewPostScreenState();
}

class _ViewPostScreenState extends State<ViewPostScreen> {
  List<dynamic> posts = [];
  bool _isLoading = true;
  String? _lid;
  String? _userPhoto;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _lid = prefs.getString('lid') ?? '';
    _userPhoto = prefs.getString('photo') ?? '';

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
        Uri.parse('$url/viewpostothers/'),
        body: {'lid': _lid},
      );

      var data = json.decode(response.body);
      if (data['status'] == 'ok') {
        setState(() {
          posts = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error loading posts: $e");
      setState(() => _isLoading = false);
    }
  }

  void _openComments(int postId, String photo, String desc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewCommentsScreen(
          postId: postId,
          postPhoto: photo,
          postDesc: desc,
        ),
      ),
    );
  }

  Future<void> _sendFriendRequest(String toUserId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = prefs.getString('url') ?? '';

    try {
      var response = await http.post(
        Uri.parse('$url/send_request/'),
        body: {
          'from_lid': _lid,
          'to_lid': toUserId,
        },
      );

      var data = json.decode(response.body);
      if (data['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Friend request sent!"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Already friends or request pending")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send request")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Explore Posts"),
        backgroundColor: Colors.deepOrange,
        elevation: 2,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.post_add, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No posts to show",
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      Text(
                        "Follow friends to see their posts",
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  child: ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      var post = posts[index];
                      bool isFriend = post['is_friend'] == 'yes';
                      bool requestSent = post['request_sent'] == 'yes';

                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Header
                            ListTile(
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(post['user_photo'] ?? ''),
                                child: post['user_photo'] == null || post['user_photo'].isEmpty
                                    ? Text(post['user_name'][0].toUpperCase())
                                    : null,
                              ),
                              title: Text(
                                post['user_name'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(post['date']),
                              trailing: !isFriend && !requestSent
                                  ? TextButton.icon(
                                      onPressed: () => _sendFriendRequest(post['user_lid']),
                                      icon: Icon(Icons.person_add, size: 16),
                                      label: Text("Add"),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.deepOrange,
                                      ),
                                    )
                                  : isFriend
                                      ? Chip(
                                          label: Text("Friends", style: TextStyle(fontSize: 10)),
                                          backgroundColor: Colors.green[100],
                                        )
                                      : Chip(
                                          label: Text("Pending", style: TextStyle(fontSize: 10)),
                                          backgroundColor: Colors.orange[100],
                                        ),
                            ),

                            // Post Image
                            if (post['photo'] != null && post['photo'].isNotEmpty)
                              Container(
                                height: 300,
                                width: double.infinity,
                                child: Image.network(
                                  post['photo'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.broken_image, size: 60),
                                  ),
                                ),
                              ),

                            // Post Description
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                post['desc'],
                                style: TextStyle(fontSize: 16),
                              ),
                            ),

                            // Actions
                            ButtonBar(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _openComments(
                                    int.parse(post['id']),
                                    post['photo'] ?? '',
                                    post['desc'],
                                  ),
                                  icon: Icon(Icons.comment, color: Colors.blue),
                                  label: Text("Comments (${post['comment_count']})"),
                                ),
                                TextButton.icon(
                                  onPressed: null, // Like feature can be added
                                  icon: Icon(Icons.thumb_up, color: Colors.grey),
                                  label: Text("Like"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_post');
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.deepOrange,
        tooltip: "Add Post",
      ),
    );
  }
}