import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MessageHistoryScreen extends StatefulWidget {
  const MessageHistoryScreen({super.key});

  @override
  State<MessageHistoryScreen> createState() => _MessageHistoryScreenState();
}

class _MessageHistoryScreenState extends State<MessageHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _messages = [];
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
        _webRoot = data['web_root'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _showMessagePreview(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(message['title'] ?? 'Untitled',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (message['imgurl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    (_webRoot ?? ApiService.baseUrl) + message['imgurl'].toString(),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(message['content'] ?? '', style: TextStyle(color: Colors.grey[800])),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Message History', style: TextStyle(color: Color(0xFF0A1628), fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? const Center(child: Text('No messages yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isSent = message['flag'] == '1';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSent ? Colors.green[50] : Colors.grey[200],
                          child: Icon(
                            isSent ? Icons.mark_email_read : Icons.mark_email_unread,
                            color: isSent ? Colors.green : Colors.grey,
                          ),
                        ),
                        title: Text(message['title'] ?? 'Untitled'),
                        subtitle: Text(isSent ? 'Sent' : 'Not sent yet'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, color: Color(0xFF1A3A6B), size: 26),
                              onPressed: () => _showMessagePreview(message),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            ),
                            const SizedBox(width: 18),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SentDetailScreen(message: message),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class SentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> message;

  const SentDetailScreen({super.key, required this.message});

  @override
  State<SentDetailScreen> createState() => _SentDetailScreenState();
}

class _SentDetailScreenState extends State<SentDetailScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _bhController = TextEditingController();
  List<Map<String, dynamic>> _sentList = [];
  bool _isLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadSentList();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _bhController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _loadSentList);
  }

  Future<void> _loadSentList() async {
    setState(() => _isLoading = true);
    final searchText = _searchController.text.trim();
    final bhText = _bhController.text.trim();
    final result = await _apiService.getSentMessageList(
      id: widget.message['id'].toString(),
      keyword: searchText.isEmpty ? null : searchText,
      bh: bhText.isEmpty ? null : bhText,
    );
    if (result['code'] == 200) {
      final data = result['data'];
      setState(() {
        _sentList = List<Map<String, dynamic>>.from(data['list'] ?? []);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.message['title'] ?? 'Sent To',
            style: const TextStyle(color: Color(0xFF0A1628), fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search officer name or badge',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (_) => _onFilterChanged(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _bhController,
              decoration: InputDecoration(
                hintText: 'Filter by unit',
                prefixIcon: const Icon(Icons.apartment, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
              ),
              onChanged: (_) => _onFilterChanged(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sentList.isEmpty
                    ? const Center(child: Text('Not sent to anyone yet'))
                    : RefreshIndicator(
                        onRefresh: _loadSentList,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _sentList.length,
                          itemBuilder: (context, index) {
                            final sent = _sentList[index];
                            final isOffline = sent['offline'] == '1';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF1A3A6B),
                                  child: Text(
                                    (sent['hostname'] ?? '?')[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(sent['hostname'] ?? 'Unknown'),
                                subtitle: Text('Badge: ${sent['hostcode'] ?? ''} · Sent: ${sent['sendtime'] ?? ''}'),
                                trailing: Icon(
                                  isOffline ? Icons.cloud_off : Icons.cloud_done,
                                  color: isOffline ? Colors.orange : Colors.green,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}