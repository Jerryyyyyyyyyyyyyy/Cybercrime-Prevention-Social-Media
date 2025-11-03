import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'add_post.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String? _userPhoto;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPosts();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userPhoto = prefs.getString('photo');
      _userName = prefs.getString('name');
    });
  }

  Future<void> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/myapp/get_posts/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _posts = data['posts'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _likePost(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    await http.post(
      Uri.parse('http://10.0.2.2:8000/myapp/like_post/'),
      headers: {'Authorization': 'Bearer $token'},
      body: {'post_id': postId.toString()},
    );
    _loadPosts();
  }

  Future<void> _addComment(int postId, String comment) async {
    if (comment.trim().isEmpty) return;

    // AI Bullying Check
    if (_containsBullying(comment)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment blocked: Inappropriate language'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    await http.post(
      Uri.parse('http://10.0.2.2:8000/myapp/add_comment/'),
      headers: {'Authorization': 'Bearer $token'},
      body: {
        'post_id': postId.toString(),
        'comment': comment,
      },
    );
    _loadPosts();
  }

  bool _containsBullying(String text) {
    final blocked = ['stupid', 'idiot', 'hate', 'ugly', 'kill'];
    return blocked.any((word) => text.toLowerCase().contains(word));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1e3c72),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('CYBERGUARD', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          CircleAvatar(
            backgroundImage: _userPhoto != null ? NetworkImage(_userPhoto!) : null,
            child: _userPhoto == null ? Icon(Icons.person) : null,
          ),
          SizedBox(width: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF00d4ff),
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddPostScreen()),
        ).then((_) => _loadPosts()),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF00d4ff)))
          : _posts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) => _buildPostCard(_posts[index]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.post_add, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No posts yet!',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Be the first to share something!',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final isLiked = post['liked_by_user'] == true;
    final comments = List<Map<String, dynamic>>.from(post['comments']);

    return Card(
      margin: EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(post['user_photo']),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['user_name'],
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        post['date'],
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () => _showReportDialog(post['id']),
                ),
              ],
            ),
          ),

          // Post Image
          if (post['photo'] != null)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                post['photo'],
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
              ),
            ),

          // Caption
          if (post['desc'] != null && post['desc'].isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                post['desc'],
                style: TextStyle(fontSize: 14),
              ),
            ),

          // Action Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _actionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '${post['likes_count']}',
                  color: isLiked ? Colors.red : null,
                  onTap: () => _likePost(post['id']),
                ),
                _actionButton(
                  icon: Icons.comment,
                  label: '${comments.length}',
                  onTap: () => _showCommentDialog(post['id'], comments),
                ),
                _actionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () => _sharePost(post),
                ),
              ],
            ),
          ),

          Divider(height: 1),

          // Comments Preview
          if (comments.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: comments.take(2).map<Widget>((c) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${c['user_name']}: ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Expanded(child: Text(c['comment'], style: TextStyle(fontSize: 13))),
                    ],
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: color ?? Colors.grey[700]),
      label: Text(label, style: TextStyle(color: color ?? Colors.grey[700])),
      style: TextButton.styleFrom(minimumSize: Size(0, 0), padding: EdgeInsets.zero),
    );
  }

  void _showReportDialog(int postId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Report Post'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Reason for reporting...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token');
              await http.post(
                Uri.parse('http://10.0.2.2:8000/myapp/report_post/'),
                headers: {'Authorization': 'Bearer $token'},
                body: {
                  'post_id': postId.toString(),
                  'reason': controller.text,
                },
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Post reported')),
              );
            },
            child: Text('Report'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showCommentDialog(int postId, List comments) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Comments'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (comments.isEmpty)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No comments yet'),
                )
              else
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (_, i) => ListTile(
                      dense: true,
                      title: Text(comments[i]['user_name'], style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(comments[i]['comment']),
                    ),
                  ),
                ),
              TextField(
                controller: controller,
                decoration: InputDecoration(hintText: 'Add a comment...'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
          ElevatedButton(
            onPressed: () {
              _addComment(postId, controller.text);
              Navigator.pop(context);
            },
            child: Text('Post'),
          ),
        ],
      ),
    );
  }

  void _sharePost(Map<String, dynamic> post) {
    // Simulate share
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Post shared!')),
    );
  }
}