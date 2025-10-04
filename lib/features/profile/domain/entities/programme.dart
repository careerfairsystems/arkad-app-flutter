import 'package:collection/collection.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Engineering programme options available at LTH (matching backend exactly)
enum Programme {
  fireProtectionEngineering, // Brandingenjör
  mechanicalEngineeringWithTechnicalDesign, // Maskinteknik_Teknisk_Design
  electricalEngineering, // Elektroteknik
  environmentalEngineering, // Ekosystemteknik
  mechanicalEngineering, // Maskinteknik
  engineeringNanoscience, // Nanoveteknik
  engineeringBiotechnology, // Bioteknik
  industrialDesign, // Industridesign
  architecture, // Arkitekt
  informationAndCommunicationEngineering, // Informations och Kommunikationsteknik
  chemicalEngineering, // Kemiteknik
  constructionAndRailwayConstruction, // Byggteknik med Järnvägsteknik
  roadAndWaterConstruction, // Väg och vatttenbyggnad
  constructionAndArchitecture, // Byggteknik med arkitektur
  industrialEconomicsAndManagement, // Industriell ekonomi
  engineeringMathematics, // Teknisk Matematik
  biomedicalEngineering, // Medicinteknik
  surveying, // Lantmäteri
  computerScienceEngineering, // Datateknik
  engineeringPhysics, // Teknisk Fysik
  roadAndTrafficTechnology, // Byggteknik med väg och trafikteknik
}

/// Programme data with display labels and enum values
class ProgrammeData {
  const ProgrammeData({required this.label, required this.value});

  final String label;
  final Programme value;
}

/// Complete list of available programmes with backend labels (Swedish)
const List<ProgrammeData> availableProgrammes = [
  ProgrammeData(
    label: "Brandingenjör",
    value: Programme.fireProtectionEngineering,
  ),
  ProgrammeData(
    label: "Maskinteknik_Teknisk_Design",
    value: Programme.mechanicalEngineeringWithTechnicalDesign,
  ),
  ProgrammeData(label: "Elektroteknik", value: Programme.electricalEngineering),
  ProgrammeData(
    label: "Ekosystemteknik",
    value: Programme.environmentalEngineering,
  ),
  ProgrammeData(label: "Maskinteknik", value: Programme.mechanicalEngineering),
  ProgrammeData(label: "Nanoveteknik", value: Programme.engineeringNanoscience),
  ProgrammeData(label: "Bioteknik", value: Programme.engineeringBiotechnology),
  ProgrammeData(label: "Industridesign", value: Programme.industrialDesign),
  ProgrammeData(label: "Arkitekt", value: Programme.architecture),
  ProgrammeData(
    label: "Informations och Kommunikationsteknik",
    value: Programme.informationAndCommunicationEngineering,
  ),
  ProgrammeData(label: "Kemiteknik", value: Programme.chemicalEngineering),
  ProgrammeData(
    label: "Byggteknik med Järnvägsteknik",
    value: Programme.constructionAndRailwayConstruction,
  ),
  ProgrammeData(
    label: "Väg och vatttenbyggnad",
    value: Programme.roadAndWaterConstruction,
  ),
  ProgrammeData(
    label: "Byggteknik med arkitektur",
    value: Programme.constructionAndArchitecture,
  ),
  ProgrammeData(
    label: "Industriell ekonomi",
    value: Programme.industrialEconomicsAndManagement,
  ),
  ProgrammeData(
    label: "Teknisk Matematik",
    value: Programme.engineeringMathematics,
  ),
  ProgrammeData(label: "Medicinteknik", value: Programme.biomedicalEngineering),
  ProgrammeData(label: "Lantmäteri", value: Programme.surveying),
  ProgrammeData(
    label: "Datateknik",
    value: Programme.computerScienceEngineering,
  ),
  ProgrammeData(label: "Teknisk Fysik", value: Programme.engineeringPhysics),
  ProgrammeData(
    label: "Byggteknik med väg och trafikteknik",
    value: Programme.roadAndTrafficTechnology,
  ),
];

/// Utility methods for programme handling
class ProgrammeUtils {
  /// Convert programme enum to display label for API
  static String? programmeToLabel(Programme? programme) {
    if (programme == null) return null;

    try {
      // Use where().firstOrNull for safer lookup without throwing
      final programmeData = availableProgrammes
          .where((prog) => prog.value == programme)
          .firstOrNull;

      if (programmeData != null) {
        return programmeData.label;
      }

      // Log unknown programme enum for debugging
      Sentry.captureMessage(
        'Unknown programme enum value: "$programme"',
        level: SentryLevel.warning,
      );
      return null;
    } catch (e) {
      Sentry.captureException(e);
      return null;
    }
  }

  /// Convert display label from API to programme enum
  static Programme? labelToProgramme(String? label) {
    if (label == null || label.isEmpty) return null;

    try {
      // Use where().firstOrNull for safer lookup without throwing
      final programmeData = availableProgrammes
          .where((prog) => prog.label == label)
          .firstOrNull;

      if (programmeData != null) {
        return programmeData.value;
      }

      // Log unknown programme labels for debugging
      Sentry.captureMessage(
        'Unknown programme label received from API: "$label"',
        level: SentryLevel.warning,
      );
      return null;
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
