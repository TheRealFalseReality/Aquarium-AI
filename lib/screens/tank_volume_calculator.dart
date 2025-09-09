// lib/screens/tank_volume_calculator.dart

import 'package:flutter/material.dart';
import 'dart:math';
import '../main_layout.dart';

class TankVolumeCalculator extends StatefulWidget {
  @override
  _TankVolumeCalculatorState createState() => _TankVolumeCalculatorState();
}

class _TankVolumeCalculatorState extends State<TankVolumeCalculator> {
  // State variables
  String _shape = 'Rectangle';
  String _units = 'Inches';
  String _cylinderType = 'Full';

  // Controllers for all possible inputs
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _diameterController = TextEditingController();
  final _edgeController = TextEditingController();
  final _fullWidthController = TextEditingController();

  // Results
  String _gallons = '';
  String _liters = '';
  String _pounds = '';
  String _kilograms = '';

  final Map<String, IconData> shapeIcons = {
    'Rectangle': Icons.check_box_outline_blank,
    'Cube': Icons.check_box_outline_blank,
    'Cylinder': Icons.circle_outlined,
    'Hexagonal': Icons.hexagon_outlined,
    'BowFront': Icons.front_loader,
  };

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _diameterController.dispose();
    _edgeController.dispose();
    _fullWidthController.dispose();
    super.dispose();
  }

  void _calculateVolume() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    final diameter = double.tryParse(_diameterController.text) ?? 0;
    final edge = double.tryParse(_edgeController.text) ?? 0;
    final fullWidth = double.tryParse(_fullWidthController.text) ?? 0;

    double volume = 0;
    final radius = diameter / 2.0;

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
          default:
            volume = fullCylinderVolume;
        }
        break;
      case 'Hexagonal':
        volume = (3 * sqrt(3.0) / 2) * pow(edge, 2) * height;
        break;
      case 'BowFront':
        double bowDepth = fullWidth - width;
        if (bowDepth <= 0) {
          volume = length * width * height;
        } else {
          double r = (pow(length / 2, 2) + pow(bowDepth, 2)) / (2 * bowDepth);
          double theta = 2 * asin((length / 2) / r);
          double segmentArea = pow(r, 2) / 2 * (theta - sin(theta));
          volume = (length * width * height) + (segmentArea * height);
        }
        break;
      case 'Rectangle':
      default:
        volume = length * width * height;
        break;
    }

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
    final double poundsResult = gallonsResult * 8.34;
    final double kilogramsResult = litersResult;

    setState(() {
      _gallons = gallonsResult.toStringAsFixed(2);
      _liters = litersResult.toStringAsFixed(2);
      _pounds = poundsResult.toStringAsFixed(2);
      _kilograms = kilogramsResult.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Tank Volume Calculator',
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Tank Volume Calculator',
            style: Theme.of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
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
          if (_shape == 'Cylinder') _buildCylinderTypeSelector(),
          _buildSectionTitle(context, 'Units'),
          _buildUnitSelector(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _renderInputs(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _calculateVolume,
            child: Text('Calculate'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          if (_gallons.isNotEmpty) _buildResultsCard(),
        ],
      ),
    );
  }

  Widget _buildShapeSelector(String shapeName, IconData icon) {
    final bool isSelected = _shape == shapeName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _shape = shapeName;
          if (shapeName != 'Cylinder') {
            _cylinderType = 'Full';
          }
        });
      },
      child: Chip(
        avatar: Icon(icon,
            color:
                isSelected ? Theme.of(context).colorScheme.onPrimary : null),
        label: Text(shapeName),
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        labelStyle: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  // UPDATED CYLINDER TYPE SELECTOR
  Widget _buildCylinderTypeSelector() {
    const List<String> types = ['Full', 'Half', 'Corner'];
    return Column(
      children: [
        _buildSectionTitle(context, 'Cylinder Type'),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8.0,
          runSpacing: 8.0,
          children: types.map((typeName) {
            final bool isSelected = _cylinderType == typeName;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _cylinderType = typeName;
                });
              },
              child: Chip(
                label: Text(typeName),
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildUnitSelector() {
    const List<String> units = ['Inches', 'Feet', 'cm', 'Meters'];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8.0,
      runSpacing: 8.0,
      children: units.map((unitName) {
        final bool isSelected = _units == unitName;
        return GestureDetector(
          onTap: () {
            setState(() {
              _units = unitName;
            });
          },
          child: Chip(
            label: Text(unitName),
            backgroundColor: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            labelStyle: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
      }).toList(),
    );
  }

  // UPDATED RENDER INPUTS WIDGET
  Widget _renderInputs() {
    List<Widget> fields;
    switch (_shape) {
      case 'Cube':
        fields = [_buildTextField(_lengthController, 'Side Length')];
        break;
      case 'Cylinder':
        fields = [
          _buildTextField(_diameterController, 'Diameter'),
          _buildTextField(_heightController, 'Height'),
        ];
        break;
      case 'Hexagonal':
        fields = [
          _buildTextField(_edgeController, 'Edge Length'),
          _buildTextField(_heightController, 'Height'),
        ];
        break;
      case 'BowFront':
        fields = [
          _buildTextField(_lengthController, 'Length (Back)'),
          _buildTextField(_widthController, 'Width (Side)'),
          _buildTextField(_fullWidthController, 'Full Width'),
          _buildTextField(_heightController, 'Height'),
        ];
        break;
      case 'Rectangle':
      default:
        fields = [
          _buildTextField(_lengthController, 'Length'),
          _buildTextField(_widthController, 'Width'),
          _buildTextField(_heightController, 'Height'),
        ];
    }

    // Use a Wrap widget for a responsive, centered grid pattern
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: fields.map((field) {
        return SizedBox(
          width: 200, // Set a consistent width for fields
          child: field,
        );
      }).toList(),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
            _buildResultColumn(
              'Volume',
              '$_gallons gal',
              '$_liters L',
              Theme.of(context).colorScheme.primary,
            ),
            _buildResultColumn(
              'Weight',
              '$_pounds lbs',
              '$_kilograms kg',
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultColumn(
      String label, String value1, String value2, Color color) {
    return Flexible(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            value1,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value2,
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