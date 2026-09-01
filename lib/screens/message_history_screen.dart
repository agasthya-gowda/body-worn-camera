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

  void _showSentDetailSheet(Map<String, dynamic> message) {
    final searchController = TextEditingController();
    final bhController = TextEditingController();
    List<Map<String, dynamic>> sentList = [];
    bool isLoadingSent = true;
    Timer? debounce;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> loadSentList() async {
              setSheetState(() => isLoadingSent = true);
              final searchText = searchController.text.trim();
              final bhText = bhController.text.trim();
              final result = await _apiService.getSentMessageList(
                id: message['id'].toString(),
                keyword: searchText.isEmpty ? null : searchText,
                bh: bhText.isEmpty ? null : bhText,
              );
              if (result['code'] == 200) {
                final data = result['data'];
                setSheetState(() {
                  sentList = List<Map<String, dynamic>>.from(data['list'] ?? []);
                  isLoadingSent = false;
                });
              } else {
                setSheetState(() => isLoadingSent = false);
              }
            }

            if (isLoadingSent && sentList.isEmpty) {
              loadSentList();
            }

            void onFilterChanged() {
              debounce?.cancel();
              debounce = Timer(const Duration(milliseconds: 400), loadSentList);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message['title'] ?? 'Sent To',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  overflow: TextOverflow.ellipsis),
                              const Text('Recipient Delivery Status',
                                  style: TextStyle(color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search officer name or badge',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFF43F5E), width: 1.5)),
                        filled: true,
                        fillColor: const Color(0xFF020617),
                      ),
                      onChanged: (_) => onFilterChanged(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: bhController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Filter by unit',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        prefixIcon: const Icon(Icons.apartment, color: Colors.white38, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFF43F5E), width: 1.5)),
                        filled: true,
                        fillColor: const Color(0xFF020617),
                        isDense: true,
                      ),
                      onChanged: (_) => onFilterChanged(),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: isLoadingSent
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A9EFF)))
                          : sentList.isEmpty
                              ? const Center(
                                  child: Text('Not sent to anyone yet',
                                      style: TextStyle(color: Colors.white38, fontSize: 12)))
                              : ListView.builder(
                                  itemCount: sentList.length,
                                  itemBuilder: (context, index) {
                                    final sent = sentList[index];
                                    final isOffline = sent['offline'] == '1';
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF020617),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFF1E293B)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF43F5E).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: const Color(0xFFF43F5E).withOpacity(0.3)),
                                            ),
                                            child: Center(
                                              child: Text(
                                                (sent['hostname'] ?? '?')[0].toUpperCase(),
                                                style: const TextStyle(
                                                    color: Color(0xFFFB7185), fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(sent['hostname'] ?? 'Unknown',
                                                    style: const TextStyle(
                                                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                                const SizedBox(height: 2),
                                                Text('Badge: ${sent['hostcode'] ?? ''} · ${sent['sendtime'] ?? ''}',
                                                    style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(isOffline ? Icons.cloud_off : Icons.cloud_done,
                                                  size: 15, color: isOffline ? Colors.amberAccent : Colors.greenAccent),
                                              const SizedBox(width: 4),
                                              Text(isOffline ? 'OFFLINE' : 'ONLINE',
                                                  style: TextStyle(
                                                      color: isOffline ? Colors.amberAccent : Colors.greenAccent,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'monospace')),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMessagePreview(Map<String, dynamic> message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
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
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (message['imgurl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    (_webRoot ?? ApiService.baseUrl) + message['imgurl'].toString(),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: const Color(0xFF020617),
                      child: const Icon(Icons.broken_image, color: Colors.white24),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(message['content'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  _HoverIconButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Message History',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Delivery Status & Broadcast Audit', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                  _HoverIconButton(icon: Icons.refresh, onTap: _isLoading ? () {} : _loadMessages, isLoading: _isLoading),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A9EFF)))
                  : _messages.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history, size: 40, color: Colors.white24),
                              SizedBox(height: 8),
                              Text('No broadcast history records found.',
                                  style: TextStyle(color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isSent = message['flag'] == '1';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _HoverHistoryCard(
                                onTap: () => _showSentDetailSheet(message),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isSent
                                            ? const Color(0xFF059669).withOpacity(0.15)
                                            : const Color(0xFF334155).withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: isSent
                                                ? const Color(0xFF059669).withOpacity(0.4)
                                                : const Color(0xFF334155)),
                                      ),
                                      child: Icon(
                                        isSent ? Icons.check_circle_outline : Icons.schedule,
                                        size: 18,
                                        color: isSent ? Colors.greenAccent : Colors.white38,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(message['title'] ?? 'Untitled',
                                              style: const TextStyle(
                                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 3),
                                          Text(isSent ? 'Sent' : 'Not sent yet',
                                              style: TextStyle(
                                                  color: isSent ? Colors.greenAccent : Colors.white38,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    _HoverPreviewButton(onTap: () => _showMessagePreview(message)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right, size: 18, color: Colors.white38),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
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
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  _HoverIconButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.message['title'] ?? 'Sent To',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis),
                        const Text('Recipient Delivery Status', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search officer name or badge',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFF43F5E), width: 1.5)),
                      filled: true,
                      fillColor: const Color(0xFF020617),
                    ),
                    onChanged: (_) => _onFilterChanged(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bhController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Filter by unit',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      prefixIcon: const Icon(Icons.apartment, color: Colors.white38, size: 18),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFF43F5E), width: 1.5)),
                      filled: true,
                      fillColor: const Color(0xFF020617),
                      isDense: true,
                    ),
                    onChanged: (_) => _onFilterChanged(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A9EFF)))
                  : _sentList.isEmpty
                      ? const Center(
                          child: Text('Not sent to anyone yet', style: TextStyle(color: Colors.white38, fontSize: 12)))
                      : RefreshIndicator(
                          onRefresh: _loadSentList,
                          color: const Color(0xFF4A9EFF),
                          backgroundColor: const Color(0xFF0F172A),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: _sentList.length,
                            itemBuilder: (context, index) {
                              final sent = _sentList[index];
                              final isOffline = sent['offline'] == '1';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF1E293B)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF43F5E).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFF43F5E).withOpacity(0.3)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          (sent['hostname'] ?? '?')[0].toUpperCase(),
                                          style: const TextStyle(
                                              color: Color(0xFFFB7185), fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(sent['hostname'] ?? 'Unknown',
                                              style: const TextStyle(
                                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                          const SizedBox(height: 2),
                                          Text('Badge: ${sent['hostcode'] ?? ''} · ${sent['sendtime'] ?? ''}',
                                              style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(isOffline ? Icons.cloud_off : Icons.cloud_done,
                                            size: 15, color: isOffline ? Colors.amberAccent : Colors.greenAccent),
                                        const SizedBox(width: 4),
                                        Text(isOffline ? 'OFFLINE' : 'ONLINE',
                                            style: TextStyle(
                                                color: isOffline ? Colors.amberAccent : Colors.greenAccent,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'monospace')),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;
  const _HoverIconButton({required this.icon, required this.onTap, this.isLoading = false});

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF334155) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
              : Icon(widget.icon, color: Colors.white70, size: 18),
        ),
      ),
    );
  }
}

class _HoverHistoryCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HoverHistoryCard({required this.child, required this.onTap});

  @override
  State<_HoverHistoryCard> createState() => _HoverHistoryCardState();
}

class _HoverHistoryCardState extends State<_HoverHistoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHovered ? const Color(0xFFF43F5E).withOpacity(0.4) : const Color(0xFF1E293B),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _HoverPreviewButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverPreviewButton({required this.onTap});

  @override
  State<_HoverPreviewButton> createState() => _HoverPreviewButtonState();
}

class _HoverPreviewButtonState extends State<_HoverPreviewButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF4A9EFF).withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.visibility_outlined, size: 18, color: _isHovered ? const Color(0xFF4A9EFF) : Colors.white38),
        ),
      ),
    );
  }
}