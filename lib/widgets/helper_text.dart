import 'package:flutter/material.dart';

/// A collection of common text components used throughout the app
/// to maintain consistency in helper text, tips, and disclaimers.

/// Standard tip text with consistent styling
class TipText extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry? padding;
  final TextAlign? textAlign;
  final double? opacity;

  const TipText({
    super.key,
    required this.text,
    this.padding,
    this.textAlign,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: cs.onSurface.withOpacity(opacity ?? 0.65),
        ),
        textAlign: textAlign ?? TextAlign.center,
      ),
    );
  }
}

/// Standard disclaimer text with consistent styling
class DisclaimerText extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry? padding;
  final TextAlign? textAlign;
  final double? opacity;

  const DisclaimerText({
    super.key,
    required this.text,
    this.padding,
    this.textAlign,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: cs.onSurface.withOpacity(opacity ?? 0.7),
        ),
        textAlign: textAlign ?? TextAlign.center,
      ),
    );
  }
}

/// Standard instruction text for interactive elements
class InstructionText extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry? padding;
  final TextAlign? textAlign;

  const InstructionText({
    super.key,
    required this.text,
    this.padding,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
        ),
        textAlign: textAlign ?? TextAlign.center,
      ),
    );
  }
}

/// Section title with consistent styling
class SectionTitle extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry? padding;
  final TextAlign? textAlign;
  final FontWeight? fontWeight;

  const SectionTitle({
    super.key,
    required this.title,
    this.padding,
    this.textAlign,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: fontWeight ?? FontWeight.bold,
        ),
        textAlign: textAlign,
      ),
    );
  }
}