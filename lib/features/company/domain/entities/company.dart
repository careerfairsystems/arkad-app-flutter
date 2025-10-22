import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../shared/infrastructure/asset_utils.dart';

/// Domain entity representing a company in the career fair
class Company {
  const Company({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.websiteUrl,
    required this.industries,
    required this.desiredProgrammes,
    required this.desiredDegrees,
    required this.positions,
    required this.desiredCompetences,
    required this.jobs,
    required this.hasStudentSession,
    required this.studentSessionMotivation,
    required this.urlLinkedin,
    required this.urlInstagram,
    required this.urlFacebook,
    required this.urlTwitter,
    required this.urlYoutube,
    required this.visibleInCompanyList,
  });

  final int id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? websiteUrl;
  final List<String> industries;
  final List<String> desiredProgrammes;
  final List<String> desiredDegrees;
  final List<String> positions;
  final List<String> desiredCompetences;
  final List<CompanyJob> jobs;
  final bool hasStudentSession;
  final String? studentSessionMotivation;
  final String? urlLinkedin;
  final String? urlInstagram;
  final String? urlFacebook;
  final String? urlTwitter;
  final String? urlYoutube;
  final bool visibleInCompanyList;

  /// Get full logo URL (for now just returns logoUrl, but could add base URL logic)
  String? get fullLogoUrl => logoUrl;

  /// Check if company matches search query
  bool matchesSearchQuery(String query) {
    if (query.isEmpty) return true;

    final queryLower = query.toLowerCase();

    // Search in name
    if (name.toLowerCase().contains(queryLower)) return true;

    // Search in description
    if (description != null &&
        description!.toLowerCase().contains(queryLower)) {
      return true;
    }

    // Search in industries
    if (industries.any(
      (industry) => industry.toLowerCase().contains(queryLower),
    )) {
      return true;
    }

    return false;
  }

  /// Check if company matches filter criteria
  bool matchesFilter(CompanyFilter filter) {
    // Filter by industries
    if (filter.industries.isNotEmpty) {
      if (!industries.any((industry) => filter.industries.contains(industry))) {
        return false;
      }
    }

    // Filter by programmes
    if (filter.programmes.isNotEmpty) {
      if (!desiredProgrammes.any(
        (programme) => filter.programmes.contains(programme),
      )) {
        return false;
      }
    }

    // Filter by degrees
    if (filter.degrees.isNotEmpty) {
      if (!desiredDegrees.any((degree) => filter.degrees.contains(degree))) {
        return false;
      }
    }

    // Filter by positions
    if (filter.positions.isNotEmpty) {
      if (!positions.any((position) => filter.positions.contains(position))) {
        return false;
      }
    }

    // Filter by competences
    if (filter.competences.isNotEmpty) {
      if (!desiredCompetences.any(
        (competence) => filter.competences.contains(competence),
      )) {
        return false;
      }
    }

    // Filter by student sessions availability
    if (filter.hasStudentSessions && !hasStudentSession) {
      return false;
    }

    return true;
  }

  String getCompanyLogoPath({bool circular = false}) {
    // Create filename from company name: lowercase with underscores
    final sanitizedName = name
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');

    if (circular) {
      return "assets/images/companies/${sanitizedName}_circle.png";
    }

    return "assets/images/companies/$sanitizedName.png";
  }

  /// Get map marker icon for this company
  ///
  /// Returns a BitmapDescriptor for use in Google Maps markers if the logo asset exists.
  /// Returns null if no logo URL is available or if the asset doesn't exist.
  ///
  /// [checkAssetExists] - Optional function to check if an asset path exists.
  /// Defaults to [AssetUtils.assetExists] for production use.
  /// Can be overridden for testing purposes.
  Future<BitmapDescriptor?> getCompanyLogo({circular = false}) async {
    if (logoUrl == null) {
      return null;
    }

    try {
      // Create filename from company name: lowercase with underscores

      // Check if asset exists before attempting to load it
      final assetPath = getCompanyLogoPath(circular: circular);
      final assetExists = await AssetUtils.assetExists(assetPath);

      if (assetExists) {
        return await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(48, 48)),
          assetPath,
        );
      } else {
        // Return null if asset doesn't exist - let caller handle fallback
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Company &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'Company(id: $id, name: $name)';
}

/// Domain entity representing a job position at a company
class CompanyJob {
  const CompanyJob({
    required this.id,
    required this.title,
    required this.locations,
    required this.jobTypes,
    this.description,
    this.link,
  });

  final int id;
  final String title;
  final List<String> locations;
  final List<String> jobTypes;
  final String? description;
  final String? link;

  /// Check if job has application link
  bool get hasLink => link != null && link!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyJob && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CompanyJob(id: $id, title: $title)';
}

/// Filter criteria for companies
class CompanyFilter {
  const CompanyFilter({
    this.industries = const [],
    this.programmes = const [],
    this.degrees = const [],
    this.positions = const [],
    this.competences = const [],
    this.hasStudentSessions = false,
  });

  final List<String> industries;
  final List<String> programmes;
  final List<String> degrees;
  final List<String> positions;
  final List<String> competences;
  final bool hasStudentSessions;

  /// Check if filter has any active criteria
  bool get hasActiveFilters =>
      industries.isNotEmpty ||
      programmes.isNotEmpty ||
      degrees.isNotEmpty ||
      positions.isNotEmpty ||
      competences.isNotEmpty ||
      hasStudentSessions;

  /// Create a copy with updated values
  CompanyFilter copyWith({
    List<String>? industries,
    List<String>? programmes,
    List<String>? degrees,
    List<String>? positions,
    List<String>? competences,
    bool? hasStudentSessions,
  }) {
    return CompanyFilter(
      industries: industries ?? this.industries,
      programmes: programmes ?? this.programmes,
      degrees: degrees ?? this.degrees,
      positions: positions ?? this.positions,
      competences: competences ?? this.competences,
      hasStudentSessions: hasStudentSessions ?? this.hasStudentSessions,
    );
  }

  /// Clear all filters
  CompanyFilter clear() {
    return const CompanyFilter();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyFilter &&
          runtimeType == other.runtimeType &&
          industries == other.industries &&
          programmes == other.programmes &&
          degrees == other.degrees &&
          positions == other.positions &&
          competences == other.competences &&
          hasStudentSessions == other.hasStudentSessions;

  @override
  int get hashCode => Object.hash(
    industries,
    programmes,
    degrees,
    positions,
    competences,
    hasStudentSessions,
  );

  @override
  String toString() => 'CompanyFilter(active: $hasActiveFilters)';
}

/// Value object for active filter items in UI
/// Provides structured filter matching that supports localization
class ActiveFilter {
  const ActiveFilter({required this.key, required this.label});

  /// Unique identifier for the filter (used for logic and comparison)
  final String key;

  /// Display label for the filter (can be localized)
  final String label;

  /// Predefined active filters for consistent usage
  static const ActiveFilter studentSessions = ActiveFilter(
    key: 'student_sessions',
    label: 'Student Sessions',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveFilter &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'ActiveFilter(key: $key, label: $label)';
}
