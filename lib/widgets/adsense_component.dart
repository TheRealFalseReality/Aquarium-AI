import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Only import web-specific libraries when on web
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Google AdSense banner widget for web platform
class AdSenseBannerWidget extends StatefulWidget {
  const AdSenseBannerWidget({super.key});

  @override
  State<AdSenseBannerWidget> createState() => _AdSenseBannerWidgetState();
}

class _AdSenseBannerWidgetState extends State<AdSenseBannerWidget> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _viewId = 'adsense-banner-${DateTime.now().millisecondsSinceEpoch}';
      _registerAdSenseView();
    }
  }

  void _registerAdSenseView() {
    // Create the AdSense ad element
    final adElement = html.Element.tag('ins')
      ..className = 'adsbygoogle'
      ..style.display = 'block'
      ..setAttribute('data-ad-client', 'ca-pub-5701077439648731')
      ..setAttribute('data-ad-slot', '9994371406')
      ..setAttribute('data-ad-format', 'auto')
      ..setAttribute('data-full-width-responsive', 'true');

    // Create a container div
    final containerDiv = html.DivElement()
      ..id = _viewId
      ..style.width = '100%'
      ..style.height = '90px'
      ..style.textAlign = 'center'
      ..append(adElement);

    // Register the view
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      // Push the ad after a short delay to ensure DOM is ready
      Future.delayed(Duration(milliseconds: 100), () {
        try {
          (html.window as dynamic).adsbygoogle?.push({});
        } catch (e) {
          print('AdSense error: $e');
        }
      });
      return containerDiv;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 90,
      width: double.infinity,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}

/// Google AdSense display ad widget for web platform
class AdSenseDisplayWidget extends StatefulWidget {
  const AdSenseDisplayWidget({super.key});

  @override
  State<AdSenseDisplayWidget> createState() => _AdSenseDisplayWidgetState();
}

class _AdSenseDisplayWidgetState extends State<AdSenseDisplayWidget> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _viewId = 'adsense-display-${DateTime.now().millisecondsSinceEpoch}';
      _registerAdSenseView();
    }
  }

  void _registerAdSenseView() {
    // Create the AdSense ad element
    final adElement = html.Element.tag('ins')
      ..className = 'adsbygoogle'
      ..style.display = 'block'
      ..setAttribute('data-ad-client', 'ca-pub-5701077439648731')
      ..setAttribute('data-ad-slot', '9994371406')
      ..setAttribute('data-ad-format', 'auto')
      ..setAttribute('data-full-width-responsive', 'true');

    // Create a container div
    final containerDiv = html.DivElement()
      ..id = _viewId
      ..style.width = '100%'
      ..style.minHeight = '300px'
      ..style.textAlign = 'center'
      ..append(adElement);

    // Register the view
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      // Push the ad after a short delay to ensure DOM is ready
      Future.delayed(Duration(milliseconds: 100), () {
        try {
          (html.window as dynamic).adsbygoogle?.push({});
        } catch (e) {
          print('AdSense error: $e');
        }
      });
      return containerDiv;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(
        minWidth: 320,
        minHeight: 300,
        maxWidth: 400,
        maxHeight: 400,
      ),
      child: HtmlElementView(viewType: _viewId),
    );
  }
}