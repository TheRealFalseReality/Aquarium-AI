import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main_layout.dart';
import '../models/fish.dart';

class FishCompatibilityEditorScreen extends StatefulWidget {
  const FishCompatibilityEditorScreen({super.key});

  @override
  State<FishCompatibilityEditorScreen> createState() => _FishCompatibilityEditorScreenState();
}

class _FishCompatibilityEditorScreenState extends State<FishCompatibilityEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Fish> _freshwaterFish = [];
  List<Fish> _marineFish = [];
  List<Fish> _filteredFish = [];
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';
  String _currentCategory = 'freshwater';
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentCategory = _tabController.index == 0 ? 'freshwater' : 'marine';
          _filterFish();
        });
      }
    });
    _loadFishData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFishData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final String jsonString = await rootBundle.loadString('assets/fishcompat.json');
      final Map<String, dynamic> data = json.decode(jsonString);

      setState(() {
        _freshwaterFish = (data['freshwater'] as List)
            .map((json) => Fish.fromJson(json))
            .toList();
        _marineFish = (data['marine'] as List)
            .map((json) => Fish.fromJson(json))
            .toList();
        _filterFish();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load fish data: $e';
        _isLoading = false;
      });
    }
  }

  void _filterFish() {
    final currentFishList = _currentCategory == 'freshwater' ? _freshwaterFish : _marineFish;
    
    if (_searchQuery.isEmpty) {
      _filteredFish = List.from(currentFishList);
    } else {
      _filteredFish = currentFishList.where((fish) {
        return fish.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               fish.commonNames.any((name) => name.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
    
    // Sort alphabetically
    _filteredFish.sort((a, b) => a.name.compareTo(b.name));
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterFish();
    });
  }

  Future<void> _addNewFish() async {
    final result = await showDialog<Fish>(
      context: context,
      builder: (context) => AddFishDialog(
        fishNames: _currentCategory == 'freshwater' 
            ? _freshwaterFish.map((f) => f.name).toList()
            : _marineFish.map((f) => f.name).toList(),
        waterType: _currentCategory,
      ),
    );

    if (result != null) {
      setState(() {
        if (_currentCategory == 'freshwater') {
          _freshwaterFish.add(result);
        } else {
          _marineFish.add(result);
        }
        _filterFish();
      });
    }
  }

  Future<void> _editFish(Fish fish) async {
    final allFishNames = _currentCategory == 'freshwater' 
        ? _freshwaterFish.map((f) => f.name).toList()
        : _marineFish.map((f) => f.name).toList();

    final result = await showDialog<Fish>(
      context: context,
      builder: (context) => EditFishDialog(
        fish: fish,
        allFishNames: allFishNames,
        waterType: _currentCategory,
      ),
    );

    if (result != null) {
      setState(() {
        final fishList = _currentCategory == 'freshwater' ? _freshwaterFish : _marineFish;
        final index = fishList.indexWhere((f) => f.name == fish.name);
        if (index != -1) {
          fishList[index] = result;
        }
        _filterFish();
      });
    }
  }

  Future<void> _deleteFish(Fish fish) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fish'),
        content: Text('Are you sure you want to delete "${fish.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        if (_currentCategory == 'freshwater') {
          _freshwaterFish.removeWhere((f) => f.name == fish.name);
        } else {
          _marineFish.removeWhere((f) => f.name == fish.name);
        }
        _filterFish();
      });
    }
  }

  Future<void> _exportData() async {
    try {
      final data = {
        'freshwater': _freshwaterFish.map((f) => f.toJson()).toList(),
        'marine': _marineFish.map((f) => f.toJson()).toList(),
      };
      
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(data);
      
      await Clipboard.setData(ClipboardData(text: jsonString));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fish data copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Fish Compatibility Editor',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search fish...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _exportData,
                      icon: const Icon(Icons.download),
                      tooltip: 'Export Data',
                    ),
                    IconButton(
                      onPressed: _addNewFish,
                      icon: const Icon(Icons.add),
                      tooltip: 'Add Fish',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Freshwater'),
                    Tab(text: 'Marine'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadFishData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildFishList(),
                          _buildFishList(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFishList() {
    if (_filteredFish.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.pets,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No fish found matching "$_searchQuery"'
                  : 'No fish in this category',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addNewFish,
                child: const Text('Add First Fish'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredFish.length,
      itemBuilder: (context, index) {
        final fish = _filteredFish[index];
        return FishCard(
          fish: fish,
          onEdit: () => _editFish(fish),
          onDelete: () => _deleteFish(fish),
        );
      },
    );
  }
}

class FishCard extends StatelessWidget {
  final Fish fish;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FishCard({
    super.key,
    required this.fish,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (fish.imageURL.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fish.imageURL,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.broken_image),
                          ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fish.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (fish.commonNames.isNotEmpty)
                        Text(
                          fish.commonNames.join(', '),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCompatibilitySection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilitySection(BuildContext context) {
    return Column(
      children: [
        _buildCompatibilityChips(
          context,
          'Compatible',
          fish.compatible,
          Colors.green,
        ),
        _buildCompatibilityChips(
          context,
          'With Caution',
          fish.withCaution,
          Colors.orange,
        ),
        _buildCompatibilityChips(
          context,
          'Not Recommended',
          fish.notRecommended,
          Colors.red[300]!,
        ),
        _buildCompatibilityChips(
          context,
          'Not Compatible',
          fish.notCompatible,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildCompatibilityChips(
    BuildContext context,
    String title,
    List<String> items,
    Color color,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title (${items.length})',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: items.map((item) => Chip(
              label: Text(
                item,
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: color.withOpacity(0.1),
              side: BorderSide(color: color.withOpacity(0.3)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class AddFishDialog extends StatefulWidget {
  final List<String> fishNames;
  final String waterType;

  const AddFishDialog({
    super.key,
    required this.fishNames,
    required this.waterType,
  });

  @override
  State<AddFishDialog> createState() => _AddFishDialogState();
}

class _AddFishDialogState extends State<AddFishDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commonNamesController = TextEditingController();
  final _imageUrlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _commonNamesController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New ${widget.waterType == 'freshwater' ? 'Freshwater' : 'Marine'} Fish'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Fish Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Fish name is required';
                  }
                  if (widget.fishNames.contains(value.trim())) {
                    return 'Fish with this name already exists';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commonNamesController,
                decoration: const InputDecoration(
                  labelText: 'Common Names (comma separated)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final fish = Fish(
                name: _nameController.text.trim(),
                commonNames: _commonNamesController.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList(),
                imageURL: _imageUrlController.text.trim(),
                compatible: [],
                notRecommended: [],
                notCompatible: [],
                withCaution: [],
              );
              Navigator.of(context).pop(fish);
            }
          },
          child: const Text('Add Fish'),
        ),
      ],
    );
  }
}

class EditFishDialog extends StatefulWidget {
  final Fish fish;
  final List<String> allFishNames;
  final String waterType;

  const EditFishDialog({
    super.key,
    required this.fish,
    required this.allFishNames,
    required this.waterType,
  });

  @override
  State<EditFishDialog> createState() => _EditFishDialogState();
}

class _EditFishDialogState extends State<EditFishDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _commonNamesController;
  late TextEditingController _imageUrlController;
  
  late List<String> _compatible;
  late List<String> _withCaution;
  late List<String> _notRecommended;
  late List<String> _notCompatible;
  late List<String> _available;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameController = TextEditingController(text: widget.fish.name);
    _commonNamesController = TextEditingController(text: widget.fish.commonNames.join(', '));
    _imageUrlController = TextEditingController(text: widget.fish.imageURL);
    
    _compatible = List.from(widget.fish.compatible);
    _withCaution = List.from(widget.fish.withCaution);
    _notRecommended = List.from(widget.fish.notRecommended);
    _notCompatible = List.from(widget.fish.notCompatible);
    
    _updateAvailableList();
  }

  void _updateAvailableList() {
    final allAssigned = <String>{
      ..._compatible,
      ..._withCaution,
      ..._notRecommended,
      ..._notCompatible,
    };
    
    _available = widget.allFishNames
        .where((name) => name != widget.fish.name && !allAssigned.contains(name))
        .toList();
    _available.sort();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _commonNamesController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Edit ${widget.fish.name}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Basic Info'),
                Tab(text: 'Compatibility'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(),
                  _buildCompatibilityTab(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveFish,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Fish Name *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Fish name is required';
              }
              if (value.trim() != widget.fish.name && 
                  widget.allFishNames.contains(value.trim())) {
                return 'Fish with this name already exists';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _commonNamesController,
            decoration: const InputDecoration(
              labelText: 'Common Names (comma separated)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _imageUrlController,
            decoration: const InputDecoration(
              labelText: 'Image URL',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityTab() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available Fish (${_available.length})',
                style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _available.length,
                    itemBuilder: (context, index) {
                      final fishName = _available[index];
                      return ListTile(
                        title: Text(fishName),
                        dense: true,
                        onTap: () => _showCompatibilityOptionsDialog(fishName),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(child: _buildCompatibilityList('Compatible', _compatible, Colors.green)),
              const SizedBox(height: 8),
              Expanded(child: _buildCompatibilityList('With Caution', _withCaution, Colors.orange)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(child: _buildCompatibilityList('Not Recommended', _notRecommended, Colors.red[300]!)),
              const SizedBox(height: 8),
              Expanded(child: _buildCompatibilityList('Not Compatible', _notCompatible, Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompatibilityList(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${items.length})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
              color: color.withOpacity(0.05),
            ),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final fishName = items[index];
                return ListTile(
                  title: Text(fishName, style: const TextStyle(fontSize: 14)),
                  dense: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => _removeFishFromList(items, fishName),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showCompatibilityOptionsDialog(String fishName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set compatibility for $fishName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Compatible'),
              onTap: () {
                _addFishToList(_compatible, fishName);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: const Text('With Caution'),
              onTap: () {
                _addFishToList(_withCaution, fishName);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.priority_high, color: Colors.red[300]),
              title: const Text('Not Recommended'),
              onTap: () {
                _addFishToList(_notRecommended, fishName);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: Colors.red),
              title: const Text('Not Compatible'),
              onTap: () {
                _addFishToList(_notCompatible, fishName);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addFishToList(List<String> list, String fishName) {
    setState(() {
      list.add(fishName);
      list.sort();
      _updateAvailableList();
    });
  }

  void _removeFishFromList(List<String> list, String fishName) {
    setState(() {
      list.remove(fishName);
      _updateAvailableList();
    });
  }

  void _saveFish() {
    if (_formKey.currentState!.validate()) {
      final updatedFish = widget.fish.copyWith(
        name: _nameController.text.trim(),
        commonNames: _commonNamesController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        imageURL: _imageUrlController.text.trim(),
        compatible: _compatible,
        withCaution: _withCaution,
        notRecommended: _notRecommended,
        notCompatible: _notCompatible,
      );
      Navigator.of(context).pop(updatedFish);
    }
  }
}