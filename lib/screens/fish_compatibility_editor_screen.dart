import 'dart:convert';
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
  bool _hasUnsavedChanges = false;
  
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
        _hasUnsavedChanges = true; // Mark that changes have been made
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
        _hasUnsavedChanges = true; // Mark that changes have been made
        final fishList = _currentCategory == 'freshwater' ? _freshwaterFish : _marineFish;
        
        // Find fish by ID instead of name to handle name changes properly
        final index = fishList.indexWhere((f) => f.id == fish.id);
        if (index != -1) {
          final oldFish = fishList[index];
          fishList[index] = result;
          
          // If the fish name changed, update all references in other fish
          if (oldFish.name != result.name) {
            _updateAllFishReferences(oldFish.name, result.name, fishList);
          }
          
          // Update bidirectional compatibility relationships
          _updateBidirectionalCompatibility(oldFish, result, fishList);
        }
        _filterFish();
      });
    }
  }

  void _updateAllFishReferences(String oldName, String newName, List<Fish> fishList) {
    // Update all other fish that reference this fish in their compatibility lists
    for (int i = 0; i < fishList.length; i++) {
      final fish = fishList[i];
      bool updated = false;
      
      final updatedCompatible = fish.compatible.map((name) => name == oldName ? newName : name).toList();
      final updatedWithCaution = fish.withCaution.map((name) => name == oldName ? newName : name).toList();
      final updatedNotRecommended = fish.notRecommended.map((name) => name == oldName ? newName : name).toList();
      final updatedNotCompatible = fish.notCompatible.map((name) => name == oldName ? newName : name).toList();
      
      if (!_listsEqual(fish.compatible, updatedCompatible) ||
          !_listsEqual(fish.withCaution, updatedWithCaution) ||
          !_listsEqual(fish.notRecommended, updatedNotRecommended) ||
          !_listsEqual(fish.notCompatible, updatedNotCompatible)) {
        updated = true;
      }
      
      if (updated) {
        fishList[i] = fish.copyWith(
          compatible: updatedCompatible,
          withCaution: updatedWithCaution,
          notRecommended: updatedNotRecommended,
          notCompatible: updatedNotCompatible,
        );
      }
    }
  }
  
  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _updateBidirectionalCompatibility(Fish oldFish, Fish newFish, List<Fish> fishList) {
    // Find fish that were added or removed from compatibility lists
    final addedToCompatible = newFish.compatible.where((name) => !oldFish.compatible.contains(name)).toList();
    final removedFromCompatible = oldFish.compatible.where((name) => !newFish.compatible.contains(name)).toList();
    
    final addedToCaution = newFish.withCaution.where((name) => !oldFish.withCaution.contains(name)).toList();
    final removedFromCaution = oldFish.withCaution.where((name) => !newFish.withCaution.contains(name)).toList();
    
    final addedToNotRecommended = newFish.notRecommended.where((name) => !oldFish.notRecommended.contains(name)).toList();
    final removedFromNotRecommended = oldFish.notRecommended.where((name) => !newFish.notRecommended.contains(name)).toList();
    
    final addedToNotCompatible = newFish.notCompatible.where((name) => !oldFish.notCompatible.contains(name)).toList();
    final removedFromNotCompatible = oldFish.notCompatible.where((name) => !newFish.notCompatible.contains(name)).toList();

    // Update all affected fish
    for (int i = 0; i < fishList.length; i++) {
      final fish = fishList[i];
      if (fish.name == newFish.name) continue; // Skip the fish being edited
      
      bool needsUpdate = false;
      List<String> newCompatible = List.from(fish.compatible);
      List<String> newWithCaution = List.from(fish.withCaution);
      List<String> newNotRecommended = List.from(fish.notRecommended);
      List<String> newNotCompatible = List.from(fish.notCompatible);
      
      // Handle additions - when fishName matches this fish, add newFish to the corresponding list
      for (String fishName in addedToCompatible) {
        if (fishName == fish.name) {
          // Remove newFish from other lists first
          newWithCaution.remove(newFish.name);
          newNotRecommended.remove(newFish.name);
          newNotCompatible.remove(newFish.name);
          // Add newFish to compatible if not already there
          if (!newCompatible.contains(newFish.name)) {
            newCompatible.add(newFish.name);
            needsUpdate = true;
          }
        }
      }
      
      for (String fishName in addedToCaution) {
        if (fishName == fish.name) {
          // Remove newFish from other lists first
          newCompatible.remove(newFish.name);
          newNotRecommended.remove(newFish.name);
          newNotCompatible.remove(newFish.name);
          // Add newFish to caution if not already there
          if (!newWithCaution.contains(newFish.name)) {
            newWithCaution.add(newFish.name);
            needsUpdate = true;
          }
        }
      }
      
      for (String fishName in addedToNotRecommended) {
        if (fishName == fish.name) {
          // Remove newFish from other lists first
          newCompatible.remove(newFish.name);
          newWithCaution.remove(newFish.name);
          newNotCompatible.remove(newFish.name);
          // Add newFish to not recommended if not already there
          if (!newNotRecommended.contains(newFish.name)) {
            newNotRecommended.add(newFish.name);
            needsUpdate = true;
          }
        }
      }
      
      for (String fishName in addedToNotCompatible) {
        if (fishName == fish.name) {
          // Remove newFish from other lists first
          newCompatible.remove(newFish.name);
          newWithCaution.remove(newFish.name);
          newNotRecommended.remove(newFish.name);
          // Add newFish to not compatible if not already there
          if (!newNotCompatible.contains(newFish.name)) {
            newNotCompatible.add(newFish.name);
            needsUpdate = true;
          }
        }
      }
      
      // Handle removals - remove from all lists (they will be available for assignment)
      for (String fishName in [...removedFromCompatible, ...removedFromCaution, ...removedFromNotRecommended, ...removedFromNotCompatible]) {
        if (fishName == fish.name) {
          if (newCompatible.remove(newFish.name)) needsUpdate = true;
          if (newWithCaution.remove(newFish.name)) needsUpdate = true;
          if (newNotRecommended.remove(newFish.name)) needsUpdate = true;
          if (newNotCompatible.remove(newFish.name)) needsUpdate = true;
        }
      }
      
      if (needsUpdate) {
        // Sort the lists to maintain consistency
        newCompatible.sort();
        newWithCaution.sort();
        newNotRecommended.sort();
        newNotCompatible.sort();
        
        fishList[i] = fish.copyWith(
          compatible: newCompatible,
          withCaution: newWithCaution,
          notRecommended: newNotRecommended,
          notCompatible: newNotCompatible,
        );
      }
    }
  }

  Future<void> _duplicateFish(Fish fish) async {
    final result = await showDialog<Fish>(
      context: context,
      builder: (context) => DuplicateFishDialog(
        originalFish: fish,
        existingNames: _currentCategory == 'freshwater'
            ? _freshwaterFish.map((f) => f.name).toList()
            : _marineFish.map((f) => f.name).toList(),
      ),
    );

    if (result != null) {
      setState(() {
        _hasUnsavedChanges = true; // Mark that changes have been made
        if (_currentCategory == 'freshwater') {
          _freshwaterFish.add(result);
        } else {
          _marineFish.add(result);
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
        _hasUnsavedChanges = true; // Mark that changes have been made
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
        
        _showJsonPreviewDialog(jsonString);
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

  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Default'),
        content: const Text(
          'This will reset all data to the original fishcompat.json file. '
          'All changes will be lost. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _loadFishData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data reset to default successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showStatsDialog() {
    final totalFreshwater = _freshwaterFish.length;
    final totalMarine = _marineFish.length;
    final totalFish = totalFreshwater + totalMarine;
    
    // Calculate average compatibility numbers
    double avgCompatible = 0;
    double avgCaution = 0;
    double avgNotRecommended = 0;
    double avgNotCompatible = 0;
    
    if (totalFish > 0) {
      final allFish = [..._freshwaterFish, ..._marineFish];
      if (allFish.isNotEmpty) {
        avgCompatible = allFish.map((f) => f.compatible.length).reduce((a, b) => a + b) / totalFish;
        avgCaution = allFish.map((f) => f.withCaution.length).reduce((a, b) => a + b) / totalFish;
        avgNotRecommended = allFish.map((f) => f.notRecommended.length).reduce((a, b) => a + b) / totalFish;
        avgNotCompatible = allFish.map((f) => f.notCompatible.length).reduce((a, b) => a + b) / totalFish;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Database Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Fish: $totalFish'),
            Text('• Freshwater: $totalFreshwater'),
            Text('• Marine: $totalMarine'),
            const SizedBox(height: 16),
            const Text('Average Compatibility Entries:', 
              style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Compatible: ${avgCompatible.toStringAsFixed(1)}'),
            Text('• With Caution: ${avgCaution.toStringAsFixed(1)}'),
            Text('• Not Recommended: ${avgNotRecommended.toStringAsFixed(1)}'),
            Text('• Not Compatible: ${avgNotCompatible.toStringAsFixed(1)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _performFileValidation() {
    List<String> allErrors = [];
    
    // Validate freshwater fish
    for (final fish in _freshwaterFish) {
      final errors = _validateIndividualFish(fish, _freshwaterFish);
      if (errors.isNotEmpty) {
        allErrors.add('${fish.name}: ${errors.join(', ')}');
      }
    }
    
    // Check for unassigned freshwater fish
    _checkForUnassignedFish(_freshwaterFish, allErrors, 'Freshwater');
    
    // Validate marine fish
    for (final fish in _marineFish) {
      final errors = _validateIndividualFish(fish, _marineFish);
      if (errors.isNotEmpty) {
        allErrors.add('${fish.name}: ${errors.join(', ')}');
      }
    }
    
    // Check for unassigned marine fish
    _checkForUnassignedFish(_marineFish, allErrors, 'Marine');
    
    // Reset changes indicator after validation
    setState(() {
      _hasUnsavedChanges = false;
    });
    
    // Show results
    if (allErrors.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Validation Passed'),
            ],
          ),
          content: const Text(
            'All fish data is valid! No integrity issues found.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Validation Errors'),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.5,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Found ${allErrors.length} validation errors:'),
                  const SizedBox(height: 16),
                  ...allErrors.map((error) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '• $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  List<String> _validateIndividualFish(Fish fish, List<Fish> fishInCategory) {
    List<String> errors = [];
    final allFishNames = fishInCategory.map((f) => f.name).toSet();
    
    // Get all fish names mentioned in compatibility lists
    final allMentioned = {
      ...fish.compatible,
      ...fish.withCaution,
      ...fish.notRecommended,
      ...fish.notCompatible,
    };
    
    // Check if fish includes itself in some compatibility list (not just available)
    final fishIncludesItself = fish.compatible.contains(fish.name) ||
                              fish.withCaution.contains(fish.name) ||
                              fish.notRecommended.contains(fish.name) ||
                              fish.notCompatible.contains(fish.name);
    
    if (!fishIncludesItself) {
      errors.add('${fish.name}: Fish must include itself in at least one compatibility category');
    }
    
    // Check for duplicates across lists
    final Map<String, List<String>> fishLists = {
      'compatible': fish.compatible,
      'withCaution': fish.withCaution,
      'notRecommended': fish.notRecommended,
      'notCompatible': fish.notCompatible,
    };
    
    for (final fishName in allMentioned) {
      final foundInLists = <String>[];
      fishLists.forEach((listName, list) {
        if (list.contains(fishName)) {
          foundInLists.add(listName);
        }
      });
      
      if (foundInLists.length > 1) {
        errors.add('${fish.name}: $fishName appears in multiple lists: ${foundInLists.join(', ')}');
      }
    }
    
    // Check for fish mentioned that don't exist in the category
    for (final mentionedFish in allMentioned) {
      if (!allFishNames.contains(mentionedFish)) {
        errors.add('${fish.name}: References non-existent fish: $mentionedFish');
      }
    }
    
    // Check for contradictions with other fish
    for (final otherFish in fishInCategory) {
      if (otherFish.name == fish.name) continue;
      
      _checkCompatibilityContradictions(fish, otherFish, errors);
    }
    
    return errors;
  }

  void _checkForUnassignedFish(List<Fish> fishList, List<String> allErrors, String categoryName) {
    final allFishNames = fishList.map((f) => f.name).toSet();
    
    for (final fish in fishList) {
      // Get all fish mentioned in this fish's compatibility lists
      final mentionedFish = {
        ...fish.compatible,
        ...fish.withCaution,
        ...fish.notRecommended,
        ...fish.notCompatible,
      };
      
      // Find fish that exist in the category but are not mentioned in any compatibility list
      final unassignedFish = allFishNames.difference(mentionedFish);
      
      if (unassignedFish.isNotEmpty) {
        for (final unassigned in unassignedFish) {
          if (unassigned != fish.name) { // Don't report the fish itself as unassigned
            allErrors.add('${fish.name}: Fish "$unassigned" in $categoryName is not assigned to any compatibility category (should be in Compatible, With Caution, Not Recommended, or Not Compatible)');
          }
        }
      }
      
      // Check if this fish includes itself in at least one compatibility category (not just available)
      final fishIncludesItself = fish.compatible.contains(fish.name) ||
                                fish.withCaution.contains(fish.name) ||
                                fish.notRecommended.contains(fish.name) ||
                                fish.notCompatible.contains(fish.name);
      
      if (!fishIncludesItself) {
        allErrors.add('${fish.name}: Fish should include itself in at least one compatibility category (Compatible, With Caution, Not Recommended, or Not Compatible)');
      }
    }
  }
  
  void _checkCompatibilityContradictions(Fish fish1, Fish fish2, List<String> errors) {
    // Check if fish1 lists fish2 as compatible, but fish2 doesn't have any relationship with fish1
    if (fish1.compatible.contains(fish2.name)) {
      final fish2HasRelationshipWithFish1 = fish2.compatible.contains(fish1.name) ||
                                           fish2.withCaution.contains(fish1.name) ||
                                           fish2.notRecommended.contains(fish1.name) ||
                                           fish2.notCompatible.contains(fish1.name);
      
      if (!fish2HasRelationshipWithFish1) {
        errors.add('Contradiction: ${fish1.name} lists ${fish2.name} as compatible, but ${fish2.name} has no relationship with ${fish1.name}');
      }
    }
    
    // Check for direct contradictions (fish1 says fish2 is compatible, but fish2 says fish1 is not compatible)
    if (fish1.compatible.contains(fish2.name) && fish2.notCompatible.contains(fish1.name)) {
      errors.add('Contradiction: ${fish1.name} lists ${fish2.name} as compatible, but ${fish2.name} lists ${fish1.name} as not compatible');
    }
    
    // Check other contradiction patterns
    if (fish1.notCompatible.contains(fish2.name) && fish2.compatible.contains(fish1.name)) {
      errors.add('Contradiction: ${fish1.name} lists ${fish2.name} as not compatible, but ${fish2.name} lists ${fish1.name} as compatible');
    }
  }

  void _showJsonPreviewDialog(String jsonString) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exported JSON Data'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonString,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              Navigator.of(context).pop();
            },
            child: const Text('Copy Again'),
          ),
        ],
      ),
    );
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
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'validate':
                            _performFileValidation();
                            break;
                          case 'reset':
                            _resetToDefault();
                            break;
                          case 'stats':
                            _showStatsDialog();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'validate',
                          child: ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.green),
                                if (_hasUnsavedChanges) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            title: Text(_hasUnsavedChanges 
                                ? 'Validate Database (Changes Detected)'
                                : 'Validate Database'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'stats',
                          child: ListTile(
                            leading: Icon(Icons.bar_chart),
                            title: Text('Statistics'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'reset',
                          child: ListTile(
                            leading: Icon(Icons.refresh, color: Colors.red),
                            title: Text('Reset to Default'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
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
          onDuplicate: () => _duplicateFish(fish),
          onDelete: () => _deleteFish(fish),
        );
      },
    );
  }
}

class FishCard extends StatelessWidget {
  final Fish fish;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const FishCard({
    super.key,
    required this.fish,
    required this.onEdit,
    required this.onDuplicate,
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
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.pets,
                      color: Theme.of(context).colorScheme.primary,
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
                  onPressed: onDuplicate,
                  icon: const Icon(Icons.copy),
                  tooltip: 'Duplicate',
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

class DuplicateFishDialog extends StatefulWidget {
  final Fish originalFish;
  final List<String> existingNames;

  const DuplicateFishDialog({
    super.key,
    required this.originalFish,
    required this.existingNames,
  });

  @override
  State<DuplicateFishDialog> createState() => _DuplicateFishDialogState();
}

class _DuplicateFishDialogState extends State<DuplicateFishDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: '${widget.originalFish.name} (Copy)');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Duplicate ${widget.originalFish.name}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'New Fish Name *',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Fish name is required';
            }
            if (widget.existingNames.contains(value.trim())) {
              return 'Fish with this name already exists';
            }
            return null;
          },
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
              final duplicatedFish = widget.originalFish.copyWith(
                name: _nameController.text.trim(),
              );
              Navigator.of(context).pop(duplicatedFish);
            }
          },
          child: const Text('Duplicate'),
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
  
  // Original values for undo functionality
  late String _originalName;
  late String _originalCommonNames;
  late String _originalImageURL;
  late List<String> _originalCompatible;
  late List<String> _originalWithCaution;
  late List<String> _originalNotRecommended;
  late List<String> _originalNotCompatible;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameController = TextEditingController(text: widget.fish.name);
    _commonNamesController = TextEditingController(text: widget.fish.commonNames.join(', '));
    _imageUrlController = TextEditingController(text: widget.fish.imageURL);
    
    // Store original values for undo functionality
    _originalName = widget.fish.name;
    _originalCommonNames = widget.fish.commonNames.join(', ');
    _originalImageURL = widget.fish.imageURL;
    _originalCompatible = List.from(widget.fish.compatible);
    _originalWithCaution = List.from(widget.fish.withCaution);
    _originalNotRecommended = List.from(widget.fish.notRecommended);
    _originalNotCompatible = List.from(widget.fish.notCompatible);
    
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
    
    // Include all fish from the same category, including the current fish being edited
    _available = widget.allFishNames
        .where((name) => !allAssigned.contains(name))
        .toList();
    _available.sort();
  }

  void _undoChanges() {
    setState(() {
      _nameController.text = _originalName;
      _commonNamesController.text = _originalCommonNames;
      _imageUrlController.text = _originalImageURL;
      _compatible = List.from(_originalCompatible);
      _withCaution = List.from(_originalWithCaution);
      _notRecommended = List.from(_originalNotRecommended);
      _notCompatible = List.from(_originalNotCompatible);
      _updateAvailableList();
    });
  }

  void _resetToDefaults() {
    // Reset this fish to its original data from the JSON file
    setState(() {
      _nameController.text = widget.fish.name;
      _commonNamesController.text = widget.fish.commonNames.join(', ');
      _imageUrlController.text = widget.fish.imageURL;
      _compatible = List.from(widget.fish.compatible);
      _withCaution = List.from(widget.fish.withCaution);
      _notRecommended = List.from(widget.fish.notRecommended);
      _notCompatible = List.from(widget.fish.notCompatible);
      _updateAvailableList();
    });
  }

  void _clearAllCategories() {
    setState(() {
      _compatible.clear();
      _withCaution.clear();
      _notRecommended.clear();
      _notCompatible.clear();
      _updateAvailableList();
    });
  }

  List<String> _validateFishData() {
    final errors = <String>[];
    final currentFishName = _nameController.text.trim();
    
    // Check for duplicates across all lists
    final allAssigned = <String>[];
    allAssigned.addAll(_compatible);
    allAssigned.addAll(_withCaution);
    allAssigned.addAll(_notRecommended);
    allAssigned.addAll(_notCompatible);
    
    final duplicates = <String>{};
    final seen = <String>{};
    for (final fish in allAssigned) {
      if (seen.contains(fish)) {
        duplicates.add(fish);
      }
      seen.add(fish);
    }
    
    if (duplicates.isNotEmpty) {
      errors.add('Duplicate fish found in compatibility lists: ${duplicates.join(', ')}');
    }
    
    // Check if the current fish includes itself in some compatibility list (not just available)
    final currentFishInLists = _compatible.contains(currentFishName) ||
                              _withCaution.contains(currentFishName) ||
                              _notRecommended.contains(currentFishName) ||
                              _notCompatible.contains(currentFishName);
    
    if (!currentFishInLists) {
      errors.add('Fish "$currentFishName" must include itself in at least one compatibility category');
    }
    
    // Get current fish names for validation (excluding the renamed fish)
    final validFishNames = Set<String>.from(widget.allFishNames);
    
    // If the fish name was changed, remove old name and add new name to valid set
    if (currentFishName != widget.fish.name) {
      validFishNames.remove(widget.fish.name);
      validFishNames.add(currentFishName);
    }
    
    // Check if all fish from the category are included somewhere
    final assignedSet = Set<String>.from(allAssigned);
    assignedSet.addAll(_available);
    
    final missingFish = validFishNames.difference(assignedSet);
    if (missingFish.isNotEmpty) {
      errors.add('Fish not assigned to any category: ${missingFish.join(', ')}');
    }
    
    // Check for extra fish not in the category
    final extraFish = assignedSet.difference(validFishNames);
    if (extraFish.isNotEmpty) {
      errors.add('Unknown fish in lists: ${extraFish.join(', ')}');
    }
    
    return errors;
  }

  void _updateFishNameInLists(String oldName, String newName) {
    if (oldName == newName) return;
    
    setState(() {
      // Update in all compatibility lists
      final index = _compatible.indexOf(oldName);
      if (index != -1) {
        _compatible[index] = newName;
      }
      
      final indexCaution = _withCaution.indexOf(oldName);
      if (indexCaution != -1) {
        _withCaution[indexCaution] = newName;
      }
      
      final indexNotRec = _notRecommended.indexOf(oldName);
      if (indexNotRec != -1) {
        _notRecommended[indexNotRec] = newName;
      }
      
      final indexNotComp = _notCompatible.indexOf(oldName);
      if (indexNotComp != -1) {
        _notCompatible[indexNotComp] = newName;
      }
      
      // Update available list to include new name if it was there
      final availableIndex = _available.indexOf(oldName);
      if (availableIndex != -1) {
        _available[availableIndex] = newName;
      }
      
      // Sort lists after update
      _compatible.sort();
      _withCaution.sort();
      _notRecommended.sort();
      _notCompatible.sort();
      _available.sort();
    });
  }

  void _showValidationErrors(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validation Errors'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The following issues were found:'),
            const SizedBox(height: 8),
            ...errors.map((error) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $error', style: const TextStyle(color: Colors.red)),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Dialog(
      insetPadding: isSmallScreen 
          ? const EdgeInsets.all(16) 
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: isSmallScreen 
            ? double.infinity 
            : MediaQuery.of(context).size.width * 0.9,
        height: isSmallScreen 
            ? MediaQuery.of(context).size.height * 0.95
            : MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Edit ${widget.fish.name}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSmallScreen)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
              ],
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
                if (!isSmallScreen) ...[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveFish,
                    child: const Text('Save'),
                  ),
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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    if (isSmallScreen) {
      return SingleChildScrollView(
        child: Column(
          children: [
            // Action buttons for mobile
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _undoChanges,
                    icon: const Icon(Icons.undo, size: 16),
                    label: const Text('Undo', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetToDefaults,
                    icon: const Icon(Icons.restore, size: 16),
                    label: const Text('Reset', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearAllCategories,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Available Fish Section
            _buildMobileCompatibilitySection('Available Fish', _available, Colors.grey, true),
            const SizedBox(height: 16),
            // Compatibility Sections in 2x2 grid
            Row(
              children: [
                Expanded(child: _buildMobileCompatibilitySection('Compatible', _compatible, Colors.green, false)),
                const SizedBox(width: 8),
                Expanded(child: _buildMobileCompatibilitySection('With Caution', _withCaution, Colors.orange, false)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildMobileCompatibilitySection('Not Recommended', _notRecommended, Colors.red[300]!, false)),
                const SizedBox(width: 8),
                Expanded(child: _buildMobileCompatibilitySection('Not Compatible', _notCompatible, Colors.red, false)),
              ],
            ),
          ],
        ),
      );
    }
    
    // Original desktop layout
    return Column(
      children: [
        // Action buttons for desktop
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _undoChanges,
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Undo Changes'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: _resetToDefaults,
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('Reset to Defaults'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: _clearAllCategories,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear All'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
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
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCompatibilitySection(String title, List<String> items, Color color, bool isAvailable) {
    return Container(
      height: isAvailable ? 250 : 180,
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              '$title (${items.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(4),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final fishName = items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    title: Text(
                      fishName,
                      style: const TextStyle(fontSize: 12),
                    ),
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    onTap: isAvailable 
                        ? () => _showCompatibilityOptionsDialog(fishName)
                        : () => _removeFishFromList(items, fishName),
                    trailing: isAvailable 
                        ? const Icon(Icons.add, size: 16)
                        : const Icon(Icons.close, size: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
              leading: Icon(Icons.priority_high, color: Colors.red[300]!),
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
      // Remove from other lists first to prevent duplicates
      _compatible.remove(fishName);
      _withCaution.remove(fishName);
      _notRecommended.remove(fishName);
      _notCompatible.remove(fishName);
      
      // Add to the target list
      if (!list.contains(fishName)) {
        list.add(fishName);
        list.sort();
      }
      _updateAvailableList();
      
      // Update the relationship in the other fish's compatibility lists
      _updateFishCrossReferences(fishName);
    });
  }
  
  void _updateFishCrossReferences(String fishName) {
    // This would require access to all fish data to update cross-references
    // For now, we'll handle this validation during save
    // The main validation will catch any inconsistencies
  }

  void _removeFishFromList(List<String> list, String fishName) {
    setState(() {
      list.remove(fishName);
      _updateAvailableList();
    });
  }

  void _saveFish() {
    // Check if form state exists and validate only if it's available
    final formState = _formKey.currentState;
    if (formState != null && !formState.validate()) {
      return;
    }
    
    // Handle fish name changes in compatibility lists
    final newName = _nameController.text.trim();
    final oldName = widget.fish.name;
    if (oldName != newName) {
      _updateFishNameInLists(oldName, newName);
    }
    
    // Validate data before saving
    final errors = _validateFishData();
    if (errors.isNotEmpty) {
      _showValidationErrors(errors);
      return;
    }
    
    final updatedFish = widget.fish.copyWith(
      name: newName,
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