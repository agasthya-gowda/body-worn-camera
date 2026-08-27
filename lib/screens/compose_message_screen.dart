import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class ComposeMessageScreen extends StatefulWidget {
  final Map<String, dynamic>? existingMessage;
  final String? webRoot;

  const ComposeMessageScreen({super.key, this.existingMessage, this.webRoot});

  @override
  State<ComposeMessageScreen> createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends State<ComposeMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  String? _existingImageUrl;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existingMessage != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingMessage?['title'] ?? '');
    _contentController = TextEditingController(text: widget.existingMessage?['content'] ?? '');
    if (_isEditing) {
      _existingImageUrl = widget.existingMessage?['imgurl'];
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageName = image.name;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // If editing and no new image was picked, fetch the existing image's bytes
    // (still needed since doc marks pic_mess as Required even for edit)
    Uint8List? imageBytesToSend = _pickedImageBytes;
    String? imageNameToSend = _pickedImageName;

    if (imageBytesToSend == null && _isEditing && _existingImageUrl != null) {
      try {
        final imageBaseUrl = widget.webRoot ?? ApiService.baseUrl;
        final imageUrl = imageBaseUrl + _existingImageUrl!;
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          imageBytesToSend = response.bodyBytes;
          imageNameToSend = _existingImageUrl!.split('/').last;
        }
      } catch (e) {
        // fall through to error below if this fails
      }
    }

    if (imageBytesToSend == null) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image (required)')),
        );
      }
      return;
    }

    Map<String, dynamic> result;
    if (_isEditing) {
      result = await _apiService.modifyMessage(
        messId: widget.existingMessage!['id'].toString(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imageBytes: imageBytesToSend,
        imageFileName: imageNameToSend!,
      );
    } else {
      result = await _apiService.createMessage(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imageBytes: imageBytesToSend,
        imageFileName: imageNameToSend!,
      );
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['code'] == 200) {
      final newMessageId = result['data']?['id'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Message updated'
              : 'Message created (ID: $newMessageId)'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${result['msg']}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteMessage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    final result = await _apiService.deleteMessage(widget.existingMessage!['id'].toString());
    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['code'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['msg'] ?? 'Deleted'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${result['msg']}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_isEditing ? 'Edit Message' : 'New Message',
            style: const TextStyle(color: Color(0xFF0A1628), fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content *', border: OutlineInputBorder()),
              maxLines: 4,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: _pickedImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_pickedImageBytes!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : (_isEditing && _existingImageUrl != null)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  (widget.webRoot ?? ApiService.baseUrl) + _existingImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8, right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('Tap to change', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Tap to select image *', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A6B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isEditing ? 'Update Message' : 'Create Message', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isSubmitting ? null : _deleteMessage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Delete Message', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}