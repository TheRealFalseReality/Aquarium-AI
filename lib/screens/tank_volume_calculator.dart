// lib/screens/tank_volume_calculator.dart

import 'package:flutter/material.dart';
import 'dart:math';
import '../main_layout.dart';

class TankVolumeCalculator extends StatefulWidget {
  @override
  _TankVolumeCalculatorState createState() => _TankVolumeCalculatorState();
}

class _TankVolumeCalculatorState extends State<TankVolumeCalculator> {
  // State variables matching the React component
  String _shape = 'Rectangle';
  String _units = 'Inches';
  String _cylinderType = 'Full';

  // Controllers for all possible inputs
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _diameterController = TextEditingController();
  final _edgeController = TextEditingController(); // For Hexagonal
  final _fullWidthController = TextEditingController(); // For BowFront

  // Results
  String _gallons = '';
  String _liters = '';
  String _pounds = '';

  // Map of shapes to icons
  final Map<String, IconData> shapeIcons = {
    'Rectangle': Icons.check_box_outline_blank,
    'Cube': Icons.check_box_outline_blank,
    'Cylinder': Icons.circle_outlined,
    'Hexagonal': Icons.hexagon_outlined,
    'BowFront': Icons.front_loader,
  };

  @override
  void dispose() {
    // Dispose all controllers
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _diameterController.dispose();
    _edgeController.dispose();
    _fullWidthController.dispose();
    super.dispose();
  }

  void _calculateVolume() {
    // Parse all dimensions, defaulting to 0
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    final diameter = double.tryParse(_diameterController.text) ?? 0;
    final edge = double.tryParse(_edgeController.text) ?? 0;
    final fullWidth = double.tryParse(_fullWidthController.text) ?? 0;

    double volume = 0;
    final radius = diameter / 2.0;

    // Volume calculations based on shape
    switch (_shape) {
      case 'Cube':
        volume = pow(length, 3).toDouble();
        break;
      case 'Cylinder':
        final fullCylinderVolume = pi * pow(radius, 2) * height;
        switch (_cylinderType) {
          case 'Half':
            volume = fullCylinderVolume / 2;
            break;
          case 'Corner':
            volume = fullCylinderVolume / 4;
            break;
          default: // Full
            volume = fullCylinderVolume;
        }
        break;
      case 'Hexagonal':
        volume = (3 * sqrt(3.0) / 2) * pow(edge, 2) * height;
        break;
      case 'BowFront':
        // This formula seems complex and might need verification for accuracy.
        // It appears to be an approximation. A more accurate calculation would involve calculus.
        // We will implement the provided formula.
        // Rectangular part: length * width * height
        // Bow part: Area of bow * height
        // Area of bow = Area of segment of a circle.
        // Let's use the React formula directly.
        double bowDepth = fullWidth - width;
        double r = (pow(length / 2, 2) + pow(bowDepth, 2)) / (2 * bowDepth);
        double theta = 2 * asin((length/2)/r);
        double segmentArea = pow(r,2)/2 * (theta - sin(theta));
        volume = (length * width * height) + (segmentArea * height);
        break;
      case 'Rectangle':
      default:
        volume = length * width * height;
        break;
    }

    // Unit conversions
    double conversionGallons = 0;
    double conversionLiters = 0;
    switch (_units) {
      case 'Inches':
        conversionGallons = 0.004329;
        conversionLiters = 0.0163871;
        break;
      case 'Feet':
        conversionGallons = 7.48052;
        conversionLiters = 28.3168;
        break;
      case 'cm':
        conversionGallons = 0.000264172;
        conversionLiters = 0.001;
        break;
      case 'Meters':
        conversionGallons = 264.172;
        conversionLiters = 1000;
        break;
    }

    final double gallonsResult = volume * conversionGallons;
    final double litersResult = volume * conversionLiters;
    final double poundsResult = gallonsResult * 8.34; // Water weight constant

    setState(() {
      _gallons = gallonsResult.toStringAsFixed(2);
      _liters = litersResult.toStringAsFixed(2);
      _pounds = poundsResult.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Tank Volume Calculator',
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- SHAPE SELECTOR ---
          _buildSectionTitle(context, 'Shape'),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.0,
            runSpacing: 8.0,
            children: shapeIcons.keys.map((shapeName) {
              return _buildShapeSelector(shapeName, shapeIcons[shapeName]!);
            }).toList(),
          ),
          const SizedBox(height: 16),

          // --- CYLINDER TYPE (Conditional) ---
          if (_shape == 'Cylinder') _buildCylinderTypeSelector(),

          // --- UNIT SELECTOR ---
          _buildSectionTitle(context, 'Units'),
          _buildUnitSelector(),
          const SizedBox(height: 16),

          // --- DIMENSION INPUTS ---
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _renderInputs(),
            ),
          ),
          const SizedBox(height: 16),

          // --- CALCULATE BUTTON ---
          ElevatedButton(
            onPressed: _calculateVolume,
            child: Text('Calculate'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),

          // --- RESULTS CARD ---
          if (_gallons.isNotEmpty) _buildResultsCard(),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildShapeSelector(String shapeName, IconData icon) {
    final bool isSelected = _shape == shapeName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _shape = shapeName;
          // Reset cylinder type if shape changes away from Cylinder
          if (shapeName != 'Cylinder') {
            _cylinderType = 'Full';
          }
        });
      },
      child: Chip(
        avatar: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.onPrimary : null),
        label: Text(shapeName),
        backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
  
  Widget _buildCylinderTypeSelector() {
    return Column(
      children: [
        _buildSectionTitle(context, 'Cylinder Type'),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Full', label: Text('Full')),
            ButtonSegment(value: 'Half', label: Text('Half')),
            ButtonSegment(value: 'Corner', label: Text('Corner')),
          ],
          selected: {_cylinderType},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _cylinderType = newSelection.first;
            });
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildUnitSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'Inches', label: Text('Inches')),
        ButtonSegment(value: 'Feet', label: Text('Feet')),
        ButtonSegment(value: 'cm', label: Text('cm')),
        ButtonSegment(value: 'Meters', label: Text('Meters')),
      ],
      selected: {_units},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _units = newSelection.first;
        });
      },
    );
  }

  Widget _renderInputs() {
    switch (_shape) {
      case 'Cube':
        return _buildTextField(_lengthController, 'Side Length');
      case 'Cylinder':
        return Column(children: [
          _buildTextField(_diameterController, 'Diameter'),
          _buildTextField(_heightController, 'Height'),
        ]);
      case 'Hexagonal':
        return Column(children: [
          _buildTextField(_edgeController, 'Edge Length'),
          _buildTextField(_heightController, 'Height'),
        ]);
      case 'BowFront':
        return Column(children: [
          _buildTextField(_lengthController, 'Length (Back)'),
          _buildTextField(_widthController, 'Width (Side)'),
          _buildTextField(_fullWidthController, 'Full Width (Front to Back)'),
          _buildTextField(_heightController, 'Height'),
        ]);
      case 'Rectangle':
      default:
        return Column(children: [
          _buildTextField(_lengthController, 'Length'),
          _buildTextField(_widthController, 'Width'),
          _buildTextField(_heightController, 'Height'),
        ]);
    }
  }
  
  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildResultColumn('Gallons', _gallons, Theme.of(context).colorScheme.primary),
            _buildResultColumn('Liters', _liters, Theme.of(context).colorScheme.secondary),
            _buildResultColumn('Pounds', _pounds, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildResultColumn(String label, String value, Color color) {
    return Flexible(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}