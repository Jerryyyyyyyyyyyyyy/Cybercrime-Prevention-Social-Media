import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ViewCommentsScreen extends StatefulWidget {
  final int postId;
  final String postPhoto;
  final String postDesc;

  const ViewCommentsScreen({
    Key? key,
    required this.postId,
    required this.postPhoto,
    required this.postDesc,
  }) : super(key: key);

  @override
  _ViewCommentsScreenState createState() => _ViewCommentsScreenState();
}

class _ViewCommentsScreenState extends State<ViewCommentsScreen> {
  List<dynamic> comments = [];
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = true;
  String? _lid;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _lid = prefs.getString('lid') ?? '';
    String url = prefs.getString('url') ?? '';
    String imgUrl = prefs.getString('img_url') ?? '';

    try {
      var response = await http.post(
        Uri.parse('$url/view_comments/${widget.postId}'),
        body: {'lid': _lid},
      );

      var data = json.decode(response.body);
      if (data['status'] == 'ok') {
        setState(() {
          comments = data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading comments: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please write a comment")),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = prefs.getString('url') ?? '';

    try {
      var response = await http.post(
        Uri.parse('$url/add_comment/'),
        body: {
          'lid': _lid,
          'post_id': widget.postId.toString(),
          'comment': _commentController.text,
        },
      );

      var data = json.decode(response.body);
      if (data['status'] == 'ok') {
        _commentController.clear();
        _loadComments(); // Refresh
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Comment added!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add comment")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Comments"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Post Preview
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.postPhoto,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.image, size: 60),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.postDesc,
                    style: TextStyle(fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1),

          // Comments List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : comments.isEmpty
                    ? Center(child: Text("No comments yet. Be the first!"))
                    : ListView.builder(
                        padding: EdgeInsets.all(12),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          var c = comments[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(c['photo'] ?? ''),
                                child: c['photo'] == null || c['photo'].isEmpty
                                    ? Text(c['name'][0].toUpperCase())
                                    : null,
                              ),
                              title: Text(
                                c['name'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['comments']),
                                  SizedBox(height: 4),
                                  Text(
                                    c['date'],
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: c['status'] == 'Bullying'
                                  ? Chip(
                                      label: Text("Reported", style: TextStyle(fontSize: 10)),
                                      backgroundColor: Colors.red[100],
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
          ),

          // Add Comment Box
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Write a comment...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _addComment,
                  child: Icon(Icons.send),
                  backgroundColor: Colors.deepPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}