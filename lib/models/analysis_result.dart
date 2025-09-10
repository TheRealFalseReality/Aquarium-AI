// lib/models/analysis_result.dart

import 'package:flutter/material.dart';

// Represents the overall summary of the water parameter analysis.
class AnalysisSummary {
  final String status;
  final String title;
  final String message;

  AnalysisSummary({required this.status, required this.title, required this.message});

  // Factory constructor to create an AnalysisSummary from a JSON object.
  factory AnalysisSummary.fromJson(Map<String, dynamic> json) {
    return AnalysisSummary(
      status: json['status'] ?? 'Needs Attention',
      title: json['title'] ?? 'Analysis Summary',
      message: json['message'] ?? 'No summary available.',
    );
  }
}

// Represents the analysis of a single water parameter.
class ParameterAnalysis {
  final String name;
  final String value;
  final String idealRange;
  final String status;
  final String advice;

  ParameterAnalysis({
    required this.name,
    required this.value,
    required this.idealRange,
    required this.status,
    required this.advice,
  });

  // Factory constructor to create a ParameterAnalysis from a JSON object.
  factory ParameterAnalysis.fromJson(Map<String, dynamic> json) {
    return ParameterAnalysis(
      name: json['name'] ?? 'Unknown',
      value: json['value'] ?? 'N/A',
      idealRange: json['idealRange'] ?? 'N/A',
      status: json['status'] ?? 'Needs Attention',
      advice: json['advice'] ?? 'No advice available.',
    );
  }
}

// Represents the entire water parameter analysis result.
class WaterAnalysisResult {
  final AnalysisSummary summary;
  final List<ParameterAnalysis> parameters;
  final String howAquaPiHelps;

  WaterAnalysisResult({
    required this.summary,
    required this.parameters,
    required this.howAquaPiHelps,
  });

  // Factory constructor to create a WaterAnalysisResult from a JSON object.
  factory WaterAnalysisResult.fromJson(Map<String, dynamic> json) {
    var summaryData = json['summary'] as Map<String, dynamic>? ?? {};
    var paramsList = json['parameters'] as List<dynamic>? ?? [];
    List<ParameterAnalysis> parameters =
        paramsList.map((p) => ParameterAnalysis.fromJson(p)).toList();

    return WaterAnalysisResult(
      summary: AnalysisSummary.fromJson(summaryData),
      parameters: parameters,
      howAquaPiHelps: json['howAquaPiHelps'] ?? 'AquaPi can help maintain stable water conditions.',
    );
  }
}