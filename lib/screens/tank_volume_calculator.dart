import 'package:flutter/material.dart';
import 'dart:math';
import '../main_layout.dart';
import '../widgets/ad_component.dart';
import '../widgets/modern_chip.dart';

class TankVolumeCalculator extends StatefulWidget {
  const TankVolumeCalculator({super.key});

  @override
  TankVolumeCalculatorState createState() => TankVolumeCalculatorState();
}

class TankVolumeCalculatorState extends State<TankVolumeCalculator> {
  String _shape = 'Rectangle';
  String _units = 'Inches';
  String _cylinderType = 'Full';

  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _diameterController = TextEditingController();
  final _edgeController = TextEditingController();
  final _fullWidthController = TextEditingController();

  String _gallons = '';
  String _liters = '';
  String _pounds = '';
  String _kilograms = '';

  final Map<String, IconData> shapeIcons = {
    'Rectangle': Icons.check_box_outline_blank,
    'Cube': Icons.check_box_outline_blank,
    'Cylinder': Icons.circle_outlined,
    'Hexagonal': Icons.hexagon_outlined,
    'BowFront': Icons.architecture_outlined,
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
      bottomNavigationBar: const AdBanner(),
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const NetworkImage(
                'https://i.pinimg.com/originals/a1/26/b3/a126b3605cb42a7ae2595015b6a7a1f0.jpg'), // Placeholder background
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.darken,
            ),
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const NativeAdWidget(),
            Text(
              'Tank Volume Calculator',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
              textAlign: TextAlign.center,
            ),
            _buildSectionTitle(context, 'Shape'),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14.0,
              runSpacing: 12.0,
              children: shapeIcons.keys.map((shapeName) {
                final selected = _shape == shapeName;
                return ModernSelectableChip(
                  label: shapeName,
                  icon: shapeIcons[shapeName],
                  selected: selected,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  selectedTextColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  onTap: () {
                    setState(() {
                      _shape = shapeName;
                      if (shapeName != 'Cylinder') {
                        _cylinderType = 'Full';
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (_shape == 'Cylinder') ...[
              const SizedBox(height: 16),
              _buildSectionTitle(context, 'Cylinder Type'),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12.0,
                runSpacing: 10.0,
                children: ['Full', 'Half', 'Corner'].map((typeName) {
                  final selected = _cylinderType == typeName;
                  return ModernSelectableChip(
                    label: typeName,
                    selected: selected,
                    dense: true,
                    selectedColor: Theme.of(context).colorScheme.secondaryContainer,
                    selectedTextColor: Theme.of(context).colorScheme.onSecondaryContainer,
                    onTap: () {
                      setState(() {
                        _cylinderType = typeName;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            _buildSectionTitle(context, 'Units'),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12.0,
              runSpacing: 10.0,
              children: ['Inches', 'Feet', 'cm', 'Meters'].map((unitName) {
                final selected = _units == unitName;
                return ModernSelectableChip(
                  label: unitName,
                  selected: selected,
                  dense: true,
                  selectedColor: Theme.of(context).colorScheme.tertiaryContainer,
                  selectedTextColor: Theme.of(context).colorScheme.onTertiaryContainer,
                  onTap: () {
                    setState(() {
                      _units = unitName;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 22.0),
                child: _renderInputs(),
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _calculateVolume,
              icon: const Icon(Icons.calculate_outlined),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
                textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              label: const Text('Calculate'),
            ),
            const SizedBox(height: 22),
            if (_gallons.isNotEmpty) _buildResultsCard(),
          ],
        ),
      ),
    );
  }

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

    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      alignment: WrapAlignment.center,
      children: fields.map((field) {
        return SizedBox(
          width: 190,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18.0, bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 24.0),
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
          Text(label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: 8),
          Text(
            value1,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value2,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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