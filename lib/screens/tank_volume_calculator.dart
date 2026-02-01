import 'package:flutter/material.dart';
import 'dart:math';
import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../widgets/ad_component.dart';
import '../widgets/modern_chip.dart';
import '../services/analytics_service.dart';

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
    'Rectangle': Icons.rectangle_outlined,
    'Cube': Icons.square_outlined,
    'Cylinder': Icons.circle_outlined,
    'Hexagonal': Icons.hexagon_outlined,
    'BowFront': Icons.architecture_outlined,
  };

  final Map<String, String> shapeDimensionImages = {
    'Rectangle': 'assets/rectangle_calc.webp',
    'Cube': 'assets/cube_calc.webp',
    'Cylinder': 'assets/cylinder_calc.webp',
    'Hexagonal': 'assets/hexagonal_prism.webp',
    'BowFront': 'assets/bowfront_calc.webp',
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

  void _showDimensionImage(BuildContext context, String imagePath) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkTheme 
        ? Colors.black.withOpacity(0.95)
        : Colors.white.withOpacity(0.95);
    final iconColor = isDarkTheme ? Colors.white : Colors.black;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Scaffold(
            backgroundColor: backgroundColor,
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      maxScale: 5,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDarkTheme 
                                ? Colors.white.withOpacity(0.9)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 300,
                                height: 300,
                                decoration: BoxDecoration(
                                  color: isDarkTheme ? Colors.grey[800] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image_outlined,
                                      size: 64,
                                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Image not available',
                                      style: TextStyle(
                                        color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Path: $imagePath',
                                      style: TextStyle(
                                        color: isDarkTheme ? Colors.grey[600] : Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close, color: iconColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _calculateVolume() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    final diameter = double.tryParse(_diameterController.text) ?? 0;
    final edge = double.tryParse(_edgeController.text) ?? 0;
    final fullWidth = double.tryParse(_fullWidthController.text) ?? 0;

    // Log calculator usage
    AnalyticsService.logCalculatorUsed(
      calculatorType: 'tank_volume',
      inputData: {
        'shape': _shape,
        'units': _units,
        'cylinder_type': _cylinderType,
        'has_dimensions': (length > 0 || width > 0 || height > 0 || diameter > 0 || edge > 0) ? 'true' : 'false',
      },
    );

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
    final l10n = AppLocalizations.of(context)!;
    return MainLayout(
      title: 'Tank Volume Calculator',
      bottomNavigationBar: const AdBanner(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const NativeAdWidget(),
          Text(
            'Tank Volume Calculator',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
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
                  selectedColor: Theme.of(context).colorScheme.tertiary,
                  selectedTextColor: Theme.of(context).colorScheme.onTertiary,
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
                selectedColor: Theme.of(context).colorScheme.secondary,
                selectedTextColor: Theme.of(context).colorScheme.onSecondary,
                onTap: () {
                  setState(() {
                    _units = unitName;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const BannerAdWidget(),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 22.0),
              child: _renderInputs(),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                label: Text(l10n.calculate),
              ),
              if (shapeDimensionImages.containsKey(_shape)) ...[
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _showDimensionImage(context, shapeDimensionImages[_shape]!),
                  child: Tooltip(
                    message: 'View $_shape dimensions',
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.9)
                                : Colors.grey[100],
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: Image.asset(
                                  shapeDimensionImages[_shape]!,
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.image_outlined,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        size: 20,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.zoom_in,
                                    size: 12,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          if (_gallons.isNotEmpty) _buildResultsCard(),
        ],
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
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
