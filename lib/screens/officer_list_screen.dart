import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'add_officer_screen.dart';
import 'modify_officer_screen.dart';

class OfficerListScreen extends StatefulWidget {
  const OfficerListScreen({super.key});

  @override
  State<OfficerListScreen> createState() => _OfficerListScreenState();
}

class _OfficerListScreenState extends State<OfficerListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _officers = [];
  Map<String, dynamic> _userTypes = {};
  bool _isLoading = true;

  String? _filterBh;
  String? _filterType;
  String? _filterBind;

  bool get _hasActiveFilters => _filterBh != null || _filterType != null || _filterBind != null;

  @override
  void initState() {
    super.initState();
    _loadOfficers();
  }

  Future<void> _loadOfficers() async {
    setState(() => _isLoading = true);
    final searchText = _searchController.text.trim();
    final result = await _apiService.searchUsers(
      hostkey: searchText.isEmpty ? null : searchText,
      bh: _filterBh,
      type: _filterType,
      bind: _filterBind,
    );
    if (result['code'] == 200) {
      final data = result['data'];
      setState(() {
        _officers = List<Map<String, dynamic>>.from(data['policelist'] ?? []);
        _userTypes = Map<String, dynamic>.from(data['user_type'] ?? {});
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load officers: ${result['msg']}')),
        );
      }
    }
  }

  void _showFilterSheet() {
    String? tempBh = _filterBh;
    String? tempType = _filterType;
    String? tempBind = _filterBind;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filter Officers',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A1628))),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Unit', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: tempBh,
                    decoration: InputDecoration(
                      hintText: 'Enter unit name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, fillColor: Colors.grey[50],
                    ),
                    onChanged: (v) => tempBh = v.trim().isEmpty ? null : v.trim(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Officer Type', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ..._userTypes.entries.map((e) => ChoiceChip(
                            label: Text(e.value.toString()),
                            selected: tempType == e.key,
                            onSelected: (selected) {
                              setSheetState(() => tempType = selected ? e.key : null);
                            },
                          )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Device Binding', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: tempBind == null,
                        onSelected: (_) => setSheetState(() => tempBind = null),
                      ),
                      ChoiceChip(
                        label: const Text('Bound'),
                        selected: tempBind == '1',
                        onSelected: (_) => setSheetState(() => tempBind = '1'),
                      ),
                      ChoiceChip(
                        label: const Text('Not Bound'),
                        selected: tempBind == '2',
                        onSelected: (_) => setSheetState(() => tempBind = '2'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              tempBh = null;
                              tempType = null;
                              tempBind = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _filterBh = tempBh;
                              _filterType = tempType;
                              _filterBind = tempBind;
                            });
                            Navigator.pop(context);
                            _loadOfficers();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A3A6B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
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

  String _typeLabel(String? typeCode) {
    return _userTypes[typeCode]?.toString() ?? typeCode ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Officers', style: TextStyle(color: Color(0xFF0A1628), fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1A3A6B)),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddOfficerScreen(userTypes: _userTypes)),
              );
              _loadOfficers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or badge ID',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _loadOfficers();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _loadOfficers(),
                  ),
                ),
                const SizedBox(width: 8),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune, color: Color(0xFF1A3A6B)),
                        onPressed: _showFilterSheet,
                      ),
                    ),
                    if (_hasActiveFilters)
                      Positioned(
                        right: 6, top: 6,
                        child: Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _officers.isEmpty
                    ? const Center(child: Text('No officers found'))
                    : RefreshIndicator(
                        onRefresh: _loadOfficers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _officers.length,
                    itemBuilder: (context, index) {
                      final officer = _officers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1A3A6B),
                            child: Text(
                              (officer['realname'] ?? '?')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(officer['realname'] ?? 'Unknown'),
                          subtitle: Text(
                            'Badge: ${officer['hostcode']} · ${_typeLabel(officer['type'])}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ModifyOfficerScreen(officer: officer, userTypes: _userTypes),
                              ),
                            );
                            _loadOfficers();
                          },
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