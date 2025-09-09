import 'package:sentry_flutter/sentry_flutter.dart';

/// Engineering programme options available at LTH
enum Programme {
  architecture,
  automotive,
  automation,
  biomedicalEngineering,
  chemicalEngineering,
  civilEngineering,
  computerScienceEngineering,
  constructionAndArchitecture,
  constructionAndRailwayConstruction,
  roadAndTrafficTechnology,
  electricalEngineering,
  engineeringBiotechnology,
  informationAndCommunicationEngineering,
  engineeringMathematics,
  engineeringNanoscience,
  engineeringPhysics,
  environmentalEngineering,
  fireProtectionEngineering,
  industrialDesign,
  industrialEconomicsAndManagement,
  surveying,
  mechanicalEngineering,
  mechanicalEngineeringWithIndustrialDesign,
  riskSafetyAndCrisisManagement,
}

/// Programme data with display labels and enum values
class ProgrammeData {
  const ProgrammeData({
    required this.label,
    required this.value,
  });

  final String label;
  final Programme value;
}

/// Complete list of available programmes with display labels
const List<ProgrammeData> availableProgrammes = [
  ProgrammeData(label: "Architecture", value: Programme.architecture),
  ProgrammeData(label: "Automotive", value: Programme.automotive),
  ProgrammeData(label: "Automation", value: Programme.automation),
  ProgrammeData(label: "Biomedical Engineering", value: Programme.biomedicalEngineering),
  ProgrammeData(label: "Chemical Engineering", value: Programme.chemicalEngineering),
  ProgrammeData(label: "Civil Engineering", value: Programme.civilEngineering),
  ProgrammeData(
    label: "Computer Science and Engineering",
    value: Programme.computerScienceEngineering,
  ),
  ProgrammeData(
    label: "Construction and Architecture",
    value: Programme.constructionAndArchitecture,
  ),
  ProgrammeData(
    label: "Construction and Railway Construction",
    value: Programme.constructionAndRailwayConstruction,
  ),
  ProgrammeData(label: "Traffic and Road", value: Programme.roadAndTrafficTechnology),
  ProgrammeData(label: "Electrical Engineering", value: Programme.electricalEngineering),
  ProgrammeData(
    label: "Engineering Biotechnology",
    value: Programme.engineeringBiotechnology,
  ),
  ProgrammeData(
    label: "Information and Communication Engineering",
    value: Programme.informationAndCommunicationEngineering,
  ),
  ProgrammeData(
    label: "Engineering Mathematics",
    value: Programme.engineeringMathematics,
  ),
  ProgrammeData(
    label: "Engineering Nanoscience",
    value: Programme.engineeringNanoscience,
  ),
  ProgrammeData(label: "Engineering Physics", value: Programme.engineeringPhysics),
  ProgrammeData(
    label: "Environmental Engineering",
    value: Programme.environmentalEngineering,
  ),
  ProgrammeData(
    label: "Fire Protection Engineering",
    value: Programme.fireProtectionEngineering,
  ),
  ProgrammeData(label: "Industrial Design", value: Programme.industrialDesign),
  ProgrammeData(
    label: "Industrial Engineering and Management",
    value: Programme.industrialEconomicsAndManagement,
  ),
  ProgrammeData(label: "Surveying", value: Programme.surveying),
  ProgrammeData(label: "Mechanical Engineering", value: Programme.mechanicalEngineering),
  ProgrammeData(
    label: "Mechanical Engineering with Technical Design",
    value: Programme.mechanicalEngineeringWithIndustrialDesign,
  ),
  ProgrammeData(
    label: "Risk, Safety and Crisis Management",
    value: Programme.riskSafetyAndCrisisManagement,
  ),
];

/// Utility methods for programme handling
class ProgrammeUtils {
  /// Convert programme enum to display label for API
  static String? programmeToLabel(Programme? programme) {
    if (programme == null) return null;
    
    try {
      return availableProgrammes
          .firstWhere((prog) => prog.value == programme)
          .label;
    } catch (e) {
      Sentry.captureException(e);
      return null;
    }
  }

  /// Convert display label from API to programme enum
  static Programme? labelToProgramme(String? label) {
    if (label == null || label.isEmpty) return null;
    
    try {
      return availableProgrammes
          .firstWhere((prog) => prog.label == label)
          .value;
    } catch (e) {
      Sentry.captureException(e);
      return null;
    }
  }

  /// Get all programme labels for API usage
  static List<String> get allProgrammeLabels =>
      availableProgrammes.map((prog) => prog.label).toList();

  /// Get all programme enum values
  static List<Programme> get allProgrammes =>
      availableProgrammes.map((prog) => prog.value).toList();
}