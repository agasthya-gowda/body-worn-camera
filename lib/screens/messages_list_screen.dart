import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'compose_message_screen.dart';
import 'send_message_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic> _messTypes = {};
  String? _webRoot;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final result = await _apiService.searchMessages();
    if (result['code'] == 200) {
      final data = result['data'];
      setState(() {
        _messages = List<Map<String, dynamic>>.from(data['list'] ?? []);
        _messTypes = Map<String, dynamic>.from(data['messtype'] ?? {});
        _webRoot = data['web_root'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load messages: ${result['msg']}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Messages', style: TextStyle(color: Color(0xFF0A1628), fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1A3A6B)),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ComposeMessageScreen()),
              );
              _loadMessages();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? const Center(child: Text('No messages yet'))
              : RefreshIndicator(
                  onRefresh: _loadMessages,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isSent = message['flag'] == '1';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSent ? Colors.green[50] : Colors.orange[50],
                            child: Icon(
                              isSent ? Icons.check_circle : Icons.schedule,
                              color: isSent ? Colors.green : Colors.orange,
                            ),
                          ),
                          title: Text(message['title'] ?? 'Untitled'),
                          subtitle: Text(
                            '${_messTypes[message['type']] ?? 'Notice'} · ${message['content'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFF1A3A6B)),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SendMessageScreen(message: message),
                                ),
                              );
                              _loadMessages();
                            },
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ComposeMessageScreen(existingMessage: message, webRoot: _webRoot),
                              ),
                            );
                            _loadMessages();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}