import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/tank.dart';
import '../models/water_parameter.dart';
import '../providers/tank_provider.dart';
import '../main_layout.dart';

class ParameterLoggerScreen extends ConsumerStatefulWidget {
  final Tank tank;

  const ParameterLoggerScreen({super.key, required this.tank});

  @override
  ParameterLoggerScreenState createState() => ParameterLoggerScreenState();
}

class ParameterLoggerScreenState extends ConsumerState<ParameterLoggerScreen> {
  String? _expandedParameter;

  Tank _getCurrentTank() {
    // Get the latest tank state from the provider
    final tanks = ref.watch(tankProvider).tanks;
    return tanks.firstWhere(
      (t) => t.id == widget.tank.id,
      orElse: () => widget.tank,
    );
  }

  void _addParameter(BuildContext context) {
    final currentTank = _getCurrentTank();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddParameterSheet(tank: currentTank),
    );
  }

  void _editParameter(BuildContext context, WaterParameter parameter) {
    final currentTank = _getCurrentTank();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddParameterSheet(
        tank: currentTank,
        existingParameter: parameter,
      ),
    );
  }

  void _deleteParameter(WaterParameter parameter) {
    final currentTank = _getCurrentTank();
    final updatedParameters = currentTank.waterParameters
        .where((p) => p.id != parameter.id)
        .toList();
    final updatedTank = currentTank.copyWith(
      waterParameters: updatedParameters,
      updatedAt: DateTime.now(),
    );
    ref.read(tankProvider.notifier).updateTank(updatedTank);
  }

  Map<String, List<WaterParameter>> _groupParametersByType(Tank tank) {
    final grouped = <String, List<WaterParameter>>{};
    for (var param in tank.waterParameters) {
      if (!grouped.containsKey(param.parameterType)) {
        grouped[param.parameterType] = [];
      }
      grouped[param.parameterType]!.add(param);
    }
    // Sort each group by date (newest first)
    grouped.forEach((key, value) {
      value.sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
    });
    return grouped;
  }

  String _getParameterLabel(String parameterType) {
    switch (parameterType) {
      case 'ammonia':
        return 'Ammonia';
      case 'nitrite':
        return 'Nitrite';
      case 'nitrate':
        return 'Nitrate';
      case 'phosphate':
        return 'Phosphate';
      case 'salinity':
        return 'Salinity';
      default:
        return parameterType;
    }
  }

  IconData _getParameterIcon(String parameterType) {
    switch (parameterType) {
      case 'ammonia':
        return Icons.warning;
      case 'nitrite':
        return Icons.science;
      case 'nitrate':
        return Icons.analytics;
      case 'phosphate':
        return Icons.bubble_chart;
      case 'salinity':
        return Icons.water;
      default:
        return Icons.water_drop;
    }
  }

  Color _getParameterColor(String parameterType) {
    switch (parameterType) {
      case 'ammonia':
        return Colors.amber;
      case 'nitrite':
        return Colors.orange;
      case 'nitrate':
        return Colors.red;
      case 'phosphate':
        return Colors.purple;
      case 'salinity':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getThresholdColor(String parameterType, double value) {
    switch (parameterType) {
      case 'ammonia':
        if (value == 0) return Colors.green;
        if (value <= 1) return Colors.yellow.shade700;
        if (value < 4) return Colors.orange;
        return Colors.red;
      
      case 'nitrite':
        if (value == 0) return Colors.green;
        if (value <= 1) return Colors.yellow.shade700;
        if (value < 2) return Colors.orange;
        return Colors.red;
      
      case 'nitrate':
        if (value == 0) return Colors.green;
        if (value <= 5) return Colors.green.shade300;
        if (value <= 40) return Colors.blue.shade400;
        return Colors.blue.shade900;
      
      case 'phosphate':
        if (value == 0) return Colors.green;
        if (value < 1) return Colors.yellow.shade700;
        if (value < 5) return Colors.orange;
        return Colors.red;
      
      case 'salinity':
        return Colors.blue;
      
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentTank = _getCurrentTank();
    final groupedParameters = _groupParametersByType(currentTank);
    final parameterTypes = ['ammonia', 'nitrite', 'nitrate', 'phosphate', 'salinity'];

    return MainLayout(
      title: '${currentTank.name} - Parameters',
      child: Scaffold(
        appBar: AppBar(
          title: Text('${currentTank.name}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addParameter(context),
              tooltip: 'Add Parameter',
            ),
          ],
        ),
        body: currentTank.waterParameters.isEmpty
            ? _buildEmptyState(context)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Water Parameter History',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your aquarium\'s water quality over time',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 24),
                  ...parameterTypes.map((paramType) {
                    final parameters = groupedParameters[paramType] ?? [];
                    if (parameters.isEmpty) return const SizedBox.shrink();

                    final isExpanded = _expandedParameter == paramType;
                    final color = _getParameterColor(paramType);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getParameterIcon(paramType),
                                color: color,
                              ),
                            ),
                            title: Text(
                              _getParameterLabel(paramType),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${parameters.length} readings'),
                            trailing: Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                            ),
                            onTap: () {
                              setState(() {
                                _expandedParameter =
                                    isExpanded ? null : paramType;
                              });
                            },
                          ),
                          if (isExpanded) ...[
                            const Divider(height: 1),
                            ...parameters.map((param) => _buildParameterItem(
                                  context,
                                  param,
                                )),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addParameter(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Reading'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 80,
              color: cs.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Parameters Logged Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start tracking your water parameters to monitor your aquarium\'s health over time.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: cs.onSurface.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _addParameter(context),
              icon: const Icon(Icons.add),
              label: const Text('Add First Reading'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterItem(
    BuildContext context,
    WaterParameter parameter,
  ) {
    final cs = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');
    final thresholdColor = _getThresholdColor(parameter.parameterType, parameter.value);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: thresholdColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${parameter.value}${parameter.unit ?? ''}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: thresholdColor,
          ),
        ),
      ),
      title: Text(
        dateFormat.format(parameter.dateRecorded),
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: parameter.notes != null
          ? Text(
              parameter.notes!,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.6),
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            color: cs.primary,
            onPressed: () => _editParameter(context, parameter),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            color: Colors.red,
            onPressed: () => _showDeleteDialog(context, parameter),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WaterParameter parameter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reading'),
        content: const Text('Are you sure you want to delete this parameter reading?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteParameter(parameter);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AddParameterSheet extends ConsumerStatefulWidget {
  final Tank tank;
  final WaterParameter? existingParameter;

  const _AddParameterSheet({
    required this.tank,
    this.existingParameter,
  });

  @override
  _AddParameterSheetState createState() => _AddParameterSheetState();
}

class _AddParameterSheetState extends ConsumerState<_AddParameterSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedParameter;
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _selectedDate;
  late String _selectedUnit;

  final Map<String, List<String>> _unitOptions = {
    'ammonia': ['ppm', 'mg/L'],
    'nitrite': ['ppm', 'mg/L'],
    'nitrate': ['ppm', 'mg/L'],
    'phosphate': ['ppm', 'mg/L'],
    'salinity': ['ppt', 'SG'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingParameter != null) {
      // Initialize with existing parameter data
      _selectedParameter = widget.existingParameter!.parameterType;
      _valueController.text = widget.existingParameter!.value.toString();
      _notesController.text = widget.existingParameter!.notes ?? '';
      _selectedDate = widget.existingParameter!.dateRecorded;
      _selectedUnit = widget.existingParameter!.unit ?? 'ppm';
    } else {
      // Initialize with default values for new parameter
      _selectedParameter = 'ammonia';
      _selectedDate = DateTime.now();
      _selectedUnit = 'ppm';
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _saveParameter() {
    if (_formKey.currentState!.validate()) {
      final WaterParameter parameter;
      
      if (widget.existingParameter != null) {
        // Update existing parameter
        parameter = widget.existingParameter!.copyWith(
          parameterType: _selectedParameter,
          value: double.parse(_valueController.text),
          unit: _selectedUnit,
          dateRecorded: _selectedDate,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );
        
        // Replace the existing parameter in the list
        final updatedParameters = widget.tank.waterParameters.map((p) {
          return p.id == parameter.id ? parameter : p;
        }).toList();
        
        final updatedTank = widget.tank.copyWith(
          waterParameters: updatedParameters,
          updatedAt: DateTime.now(),
        );
        
        ref.read(tankProvider.notifier).updateTank(updatedTank);
      } else {
        // Create new parameter
        parameter = WaterParameter.create(
          parameterType: _selectedParameter,
          value: double.parse(_valueController.text),
          unit: _selectedUnit,
          dateRecorded: _selectedDate,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

        final updatedParameters = [...widget.tank.waterParameters, parameter];
        final updatedTank = widget.tank.copyWith(
          waterParameters: updatedParameters,
          updatedAt: DateTime.now(),
        );

        ref.read(tankProvider.notifier).updateTank(updatedTank);
      }
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.existingParameter != null 
                        ? 'Edit Parameter Reading'
                        : 'Add Parameter Reading',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedParameter,
                decoration: const InputDecoration(
                  labelText: 'Parameter Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ammonia', child: Text('Ammonia')),
                  DropdownMenuItem(value: 'nitrite', child: Text('Nitrite')),
                  DropdownMenuItem(value: 'nitrate', child: Text('Nitrate')),
                  DropdownMenuItem(value: 'phosphate', child: Text('Phosphate')),
                  DropdownMenuItem(value: 'salinity', child: Text('Salinity')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedParameter = value!;
                    _selectedUnit = _unitOptions[value]!.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _valueController,
                      decoration: const InputDecoration(
                        labelText: 'Value',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a value';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: _unitOptions[_selectedParameter]!
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date & Time',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormat.format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveParameter,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.existingParameter != null 
                        ? 'Update Reading'
                        : 'Save Reading'
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
