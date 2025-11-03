import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ChatScreen extends StatefulWidget {
  final int receiverId;
  final String receiverName;
  final String receiverPhoto;

  ChatScreen({
    required this.receiverId,
    required this.receiverName,
    required this.receiverPhoto,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Encryption Key (In real app, use secure key exchange)
  final key = encrypt.Key.fromUtf8('cyberguard32bytekey1234567890!!');
  final iv = encrypt.IV.fromLength(16);
  late final encrypter = encrypt.Encrypter(encrypt.AES(key));

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/myapp/get_chat/?sender=$userId&receiver=${widget.receiverId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages = List<Map<String, dynamic>>.from(data['messages']);
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Load messages error: $e');
    }
  }

  Future<void> _sendMessage({String? text, File? image}) async {
    if ((text == null || text.isEmpty) && image == null) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final token = prefs.getString('token');

    if (userId == null || token == null) return;

    // AI Bullying Check
    if (text != null && _containsBullying(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot send: Inappropriate language detected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/myapp/send_message/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['sender_id'] = userId.toString();
      request.fields['receiver_id'] = widget.receiverId.toString();

      if (text != null) {
        final encryptedText = encrypter.encrypt(text, iv: iv).base64;
        request.fields['message'] = encryptedText;
      }

      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          image.path,
          filename: image.path.split('/').last,
        ));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        _messageController.clear();
        _loadMessages();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _containsBullying(String text) {
    final blocked = ['stupid', 'idiot', 'hate', 'kill', 'ugly', 'die'];
    return blocked.any((word) => text.toLowerCase().contains(word));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      _sendMessage(image: File(file.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1e3c72),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.receiverPhoto),
            ),
            SizedBox(width: 10),
            Text(
              widget.receiverName,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.message, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('No messages yet. Start the conversation!'),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender_id'].toString() == 
                          SharedPreferences.getInstance().then((p) => p.getInt('user_id')).toString();

                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
          ),

          // Input Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(offset: Offset(0, -2), blurRadius: 6, color: Colors.black12),
              ],
            ),
            child: Row(
              children: [
                // Image Picker
                IconButton(
                  icon: Icon(Icons.image, color: Color(0xFF00d4ff)),
                  onPressed: _pickImage,
                ),

                // Text Input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(text: _messageController.text),
                  ),
                ),

                // Send Button
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _isLoading ? null : () => _sendMessage(text: _messageController.text),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF00d4ff),
                      shape: BoxShape.circle,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final text = msg['message'] != null
        ? encrypter.decrypt64(msg['message'], iv: iv)
        : null;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Color(0xFF00d4ff) : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg['photo'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  msg['photo'],
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            if (text != null)
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            SizedBox(height: 4),
            Text(
              msg['time'].substring(11, 16),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}