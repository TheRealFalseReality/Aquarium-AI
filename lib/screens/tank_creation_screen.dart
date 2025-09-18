import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../main_layout.dart';
import '../models/tank.dart';
import '../models/fish.dart';
import '../providers/tank_provider.dart';
import '../widgets/modern_chip.dart';
import '../widgets/ad_component.dart';

class TankCreationScreen extends ConsumerStatefulWidget {
  final Tank? existingTank; // For editing existing tanks

  const TankCreationScreen({super.key, this.existingTank});

  @override
  TankCreationScreenState createState() => TankCreationScreenState();
}

class TankCreationScreenState extends ConsumerState<TankCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tankNameController = TextEditingController();
  final _sizeGallonsController = TextEditingController();
  final _sizeLitersController = TextEditingController();
  
  String _selectedCategory = 'freshwater';
  List<TankInhabitant> _inhabitants = [];
  List<Fish> _availableFish = [];
  bool _isLoadingFish = true;
  DateTime _creationDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadFishData();
    
    if (widget.existingTank != null) {
      _tankNameController.text = widget.existingTank!.name;
      _selectedCategory = widget.existingTank!.type;
      _inhabitants = List.from(widget.existingTank!.inhabitants);
      _creationDate = widget.existingTank!.createdAt;
      if (widget.existingTank!.sizeGallons != null) {
        _sizeGallonsController.text = widget.existingTank!.sizeGallons!.toString();
      }
      if (widget.existingTank!.sizeLiters != null) {
        _sizeLitersController.text = widget.existingTank!.sizeLiters!.toString();
      }
    }
  }

  @override
  void dispose() {
    _tankNameController.dispose();
    _sizeGallonsController.dispose();
    _sizeLitersController.dispose();
    super.dispose();
  }

  Future<void> _loadFishData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/fishcompat.json');
      final jsonResponse = json.decode(jsonString) as Map<String, dynamic>;
      final fishList = (jsonResponse[_selectedCategory] as List)
          .map((f) => Fish.fromJson(f))
          .toList();
      
      setState(() {
        _availableFish = fishList;
        _isLoadingFish = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFish = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load fish data: $e')),
        );
      }
    }
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _isLoadingFish = true;
      _inhabitants.clear(); // Clear inhabitants when changing category
    });
    _loadFishData();
  }

  void _addInhabitant() {
    showDialog(
      context: context,
      builder: (context) => _InhabitantDialog(
        availableFish: _availableFish,
        onAdd: (inhabitant) {
          setState(() {
            _inhabitants.add(inhabitant);
          });
        },
      ),
    );
  }

  void _editInhabitant(int index) {
    showDialog(
      context: context,
      builder: (context) => _InhabitantDialog(
        availableFish: _availableFish,
        existingInhabitant: _inhabitants[index],
        onAdd: (inhabitant) {
          setState(() {
            _inhabitants[index] = inhabitant;
          });
        },
      ),
    );
  }

  void _removeInhabitant(int index) {
    setState(() {
      _inhabitants.removeAt(index);
    });
  }

  void _duplicateInhabitant(int index) {
    final originalInhabitant = _inhabitants[index];
    final duplicatedInhabitant = TankInhabitant(
      id: const Uuid().v4(),
      customName: '${originalInhabitant.customName} (Copy)',
      fishUnit: originalInhabitant.fishUnit,
      quantity: originalInhabitant.quantity,
    );
    
    setState(() {
      _inhabitants.insert(index + 1, duplicatedInhabitant);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplicated "${originalInhabitant.customName}"')),
    );
  }

  Future<void> _saveTank() async {
    if (_formKey.currentState!.validate()) {
      try {
        final sizeGallons = _sizeGallonsController.text.trim().isNotEmpty 
          ? double.tryParse(_sizeGallonsController.text.trim()) 
          : null;
        final sizeLiters = _sizeLitersController.text.trim().isNotEmpty 
          ? double.tryParse(_sizeLitersController.text.trim()) 
          : null;

        final tank = widget.existingTank != null
            ? widget.existingTank!.copyWith(
                name: _tankNameController.text.trim(),
                type: _selectedCategory,
                inhabitants: _inhabitants,
                sizeGallons: sizeGallons,
                sizeLiters: sizeLiters,
                createdAt: _creationDate,
              )
            : Tank.create(
                name: _tankNameController.text.trim(),
                type: _selectedCategory,
                inhabitants: _inhabitants,
                sizeGallons: sizeGallons,
                sizeLiters: sizeLiters,
                createdAt: _creationDate,
              );

        if (widget.existingTank != null) {
          await ref.read(tankProvider.notifier).updateTank(tank);
        } else {
          await ref.read(tankProvider.notifier).addTank(tank);
        }

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.existingTank != null 
                  ? 'Tank updated successfully!' 
                  : 'Tank created successfully!'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save tank: $e')),
          );
        }
      }
    }
  }

  void _cancelAndReturn() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tankState = ref.watch(tankProvider);

    // Move the X from the AppBar to the page's header
    return Scaffold(
      // Remove the AppBar completely
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Custom Page Header with X Button
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 50, 
                      bottom: 16
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Centered Title
                        Column(
                          children: [
                            Text(
                              widget.existingTank != null
                                  ? 'Edit Your Tank'
                                  : 'Create Your Tank',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Design and save your custom aquarium with inhabitants.',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        // X Button on the right
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _cancelAndReturn,
                            tooltip: 'Close',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tank Name
                  TextFormField(
                    controller: _tankNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tank Name',
                      hintText: 'My Community Tank',
                      border: OutlineInputBorder(),
                    ),
                    textAlign: TextAlign.center,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a tank name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Tank Size Section
                  Text(
                    'Tank Size (Optional)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sizeGallonsController,
                          decoration: const InputDecoration(
                            labelText: 'Gallons',
                            hintText: '55',
                            border: OutlineInputBorder(),
                            suffixText: 'gal',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          onChanged: (value) {
                            // Auto-convert gallons to liters
                            if (value.isNotEmpty) {
                              final gallons = double.tryParse(value);
                              if (gallons != null) {
                                final liters = gallons * 3.78541;
                                _sizeLitersController.text = liters.toStringAsFixed(1);
                              }
                            } else {
                              _sizeLitersController.clear();
                            }
                          },
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final size = double.tryParse(value);
                              if (size == null || size <= 0) {
                                return 'Please enter a valid size';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _sizeLitersController,
                          decoration: const InputDecoration(
                            labelText: 'Liters',
                            hintText: '208',
                            border: OutlineInputBorder(),
                            suffixText: 'L',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          onChanged: (value) {
                            // Auto-convert liters to gallons
                            if (value.isNotEmpty) {
                              final liters = double.tryParse(value);
                              if (liters != null) {
                                final gallons = liters / 3.78541;
                                _sizeGallonsController.text = gallons.toStringAsFixed(1);
                              }
                            } else {
                              _sizeGallonsController.clear();
                            }
                          },
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final size = double.tryParse(value);
                              if (size == null || size <= 0) {
                                return 'Please enter a valid size';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Creation Date Selection
                  Text(
                    'Creation Date',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: _creationDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (selectedDate != null) {
                        setState(() {
                          _creationDate = selectedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selected Date',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Row(
                            children: [
                              Text(
                                '${_creationDate.month}/${_creationDate.day}/${_creationDate.year}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tank Type Selection
                  Text(
                    'Tank Type',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    children: [
                      ModernSelectableChip(
                        label: 'Freshwater',
                        emoji: '🐟',
                        selected: _selectedCategory == 'freshwater',
                        onTap: () => _onCategoryChanged('freshwater'),
                      ),
                      ModernSelectableChip(
                        label: 'Saltwater',
                        emoji: '🐠',
                        selected: _selectedCategory == 'marine',
                        onTap: () => _onCategoryChanged('marine'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Inhabitants Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Inhabitants',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isLoadingFish ? null : _addInhabitant,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Fish'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_inhabitants.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pets,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No inhabitants added yet',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "Add Fish" to start building your tank community',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._inhabitants.asMap().entries.map((entry) {
                      final index = entry.key;
                      final inhabitant = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: _getFishImageUrl(inhabitant.fishUnit) != null
                                  ? NetworkImage(_getFishImageUrl(inhabitant.fishUnit)!)
                                  : null,
                                backgroundColor: _getFishImageUrl(inhabitant.fishUnit) == null
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : null,
                                child: _getFishImageUrl(inhabitant.fishUnit) == null
                                  ? Icon(
                                      Icons.pets,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      size: 24,
                                    )
                                  : null,
                              ),
                              if (inhabitant.quantity > 1)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      '${inhabitant.quantity}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(inhabitant.customName),
                          subtitle: Text('Fish Type: ${inhabitant.fishUnit}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () => _duplicateInhabitant(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editInhabitant(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeInhabitant(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 32),
                  // Save Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: tankState.isLoading ? null : _saveTank,
                      icon: tankState.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        widget.existingTank != null ? 'Update Tank' : 'Save Tank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Cancel Button
                  OutlinedButton.icon(
                    onPressed: tankState.isLoading ? null : _cancelAndReturn,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AdBanner(),
    );
  }

  String? _getFishImageUrl(String fishName) {
    try {
      final fish = _availableFish.firstWhere((f) => f.name == fishName);
      return fish.imageURL.isNotEmpty ? fish.imageURL : null;
    } catch (e) {
      return null;
    }
  }
}

class _InhabitantDialog extends StatefulWidget {
  final List<Fish> availableFish;
  final TankInhabitant? existingInhabitant;
  final Function(TankInhabitant) onAdd;

  const _InhabitantDialog({
    required this.availableFish,
    required this.onAdd,
    this.existingInhabitant,
  });

  @override
  _InhabitantDialogState createState() => _InhabitantDialogState();
}

class _InhabitantDialogState extends State<_InhabitantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _searchController = TextEditingController();
  
  String? _selectedFishUnit;
  List<Fish> _filteredFish = [];

  @override
  void initState() {
    super.initState();
    _filteredFish = widget.availableFish;
    _searchController.addListener(_filterFish);
    if (widget.existingInhabitant != null) {
      _customNameController.text = widget.existingInhabitant!.customName;
      _quantityController.text = widget.existingInhabitant!.quantity.toString();
      _selectedFishUnit = widget.existingInhabitant!.fishUnit;
    } else {
      _quantityController.text = '1';
    }
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _quantityController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterFish() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFish = widget.availableFish.where((fish) {
        return fish.name.toLowerCase().contains(query) ||
               fish.commonNames.any((name) => name.toLowerCase().contains(query));
      }).toList();
    });
  }

  void _save() {
    if (_formKey.currentState!.validate() && _selectedFishUnit != null) {
      final inhabitant = TankInhabitant(
        id: widget.existingInhabitant?.id ?? const Uuid().v4(),
        customName: _customNameController.text.trim(),
        fishUnit: _selectedFishUnit!,
        quantity: int.parse(_quantityController.text),
      );
      
      widget.onAdd(inhabitant);
      Navigator.of(context).pop();
    } else if (_selectedFishUnit == null) {
      // Show snackbar if no fish type selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a fish type')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Title
              Text(
                widget.existingInhabitant != null ? 'Edit Inhabitant' : 'Add Inhabitant',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _customNameController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Name',
                      hintText: 'My Angelfish',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter quantity';
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null || quantity < 1) {
                        return 'Please enter a valid quantity';
                      }
                      return null;
                    },
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Fish Type Selection with Images
            Text(
              'Fish Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Search Field
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Fish',
                hintText: 'Search by name...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 450),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _filteredFish.map((fish) {
                    final isSelected = _selectedFishUnit == fish.name;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFishUnit = fish.name;
                          // Prefill custom name when fish is selected (update if new inhabitant)
                          if (widget.existingInhabitant == null) {
                            _customNameController.text = 'My ${fish.name}';
                          }
                        });
                      },
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.outline,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected 
                            ? Theme.of(context).colorScheme.primaryContainer 
                            : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                fish.imageURL,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.pets,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fish.name,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected 
                                  ? Theme.of(context).colorScheme.onPrimaryContainer 
                                  : null,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (_selectedFishUnit == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Please select a fish type',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      child: Text(widget.existingInhabitant != null ? 'Update' : 'Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}