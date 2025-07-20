import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationPanel extends StatefulWidget {
  final VoidCallback onClose;

  const NotificationPanel({super.key, required this.onClose});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  List<Map<String, dynamic>> _sentNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadSentNotifications();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
      });
    }
  }

  Future<void> _loadSentNotifications() async {
    try {
      final response = await Supabase.instance.client
          .from('admin_notifications')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _sentNotifications = response.map<Map<String, dynamic>>((item) {
          return {
            "message": item['message'] ?? '',
            "time": DateTime.tryParse(item['created_at'] ?? '')
                    ?.toLocal()
                    .toString()
                    .substring(0, 16) ??
                'Unknown Time',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint("Failed to load notifications: $e");
    }
  }

  Future<void> _sendNotification() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('user_tokens')
          .select('fcm_token');
   if (!mounted) return; 
      final tokens = response.map((e) => e['fcm_token'].toString()).toList();
      if (tokens.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user tokens found.")),
        );
        setState(() => _isSending = false);
        return;
      }

      final url = Uri.parse(
          'https://hydrecojpufsqnzpfqjp.functions.supabase.co/send-push');

      final body = {
        "tokens": tokens,
        "title": "📢 New Notification",
        "body": text,
      };

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (res.statusCode == 200) {
        // ✅ Insert into Supabase after successful send
        await Supabase.instance.client.from('admin_notifications').insert({
          'message': text,
          'image_url': null, // optional image support later
        });
        if (!mounted) return; 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notification sent to all users")),
        );

        setState(() {
          _messageController.clear();
        });

        await _loadSentNotifications(); // Refresh list

        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      
      } 
      else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${res.body}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
    
      child: Material(
         color: Colors.transparent,
       
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
            child: Container(
               height: MediaQuery.of(context).size.height * 0.7,
          width: MediaQuery.of(context).size.width * 0.85,
                color:  Colors.black ,
                  
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Row(
                      children: [
                        const Text(
                          "Notifications",
                       style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
              
                  // Notification list
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _sentNotifications.length,
                      itemBuilder: (context, index) {
                        final item = _sentNotifications[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['message'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['time'],
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              
                  // Message input row
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color:Colors.black,
                       
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image, color: Colors.white),
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: TextField(
                                controller: _messageController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: "Type your message...",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: _isSending ? null : _sendNotification,
                            icon: _isSending
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Icon(Icons.send, color: Colors.blueAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
