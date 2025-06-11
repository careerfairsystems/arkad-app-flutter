import 'package:arkad/api/extensions.dart';
import 'package:arkad_api/arkad_api.dart';
import 'package:get_it/get_it.dart';

class CompanyService {
  final ArkadApi _apiService = GetIt.I<ArkadApi>();
  List<CompanyOut> _companies = [];
  bool _isLoaded = false;

  CompanyService();

  // Getter for cached companies
  List<CompanyOut> get companies => _companies;

  // Check if companies are loaded
  bool get isLoaded => _isLoaded;

  // Fetch all companies from API and cache them
  Future<List<CompanyOut>> getAllCompanies({bool forceRefresh = false}) async {
    // Return cached data if available and no refresh is requested
    if (_isLoaded && !forceRefresh) {
      return _companies;
    }

    try {
      final response =
          await _apiService.getCompaniesApi().companiesApiGetCompanies();

      if (response.isSuccess && response.data != null) {
        _companies = response.data!.toList();
        _isLoaded = true;
        return _companies;
      } else {
        throw Exception('Failed to load companies: ${response.error}');
      }
    } catch (e) {
      throw Exception('Error fetching companies: $e');
    }
  }

  // Get a single company by ID from cached data
  CompanyOut? getCompanyById(int id) {
    if (!_isLoaded) {
      throw Exception(
        'Companies not loaded yet. Call getAllCompanies() first.',
      );
    }

    try {
      return _companies.firstWhere((company) => company.id == id);
    } catch (e) {
      return null; // Return null if no company matches the ID
    }
  }

  // Search companies by name, industries, locations, etc.
  List<CompanyOut> searchCompanies(String query) {
    if (!_isLoaded) {
      throw Exception(
        'Companies not loaded yet. Call getAllCompanies() first.',
      );
    }

    if (query.isEmpty) {
      return _companies;
    }

    final queryLower = query.toLowerCase();
    return _companies.where((company) {
      // Search in name
      if (company.name.toLowerCase().contains(queryLower)) {
        return true;
      }

      // Search in industries
      if (company.industries!.any(
        (industry) => industry.toLowerCase().contains(queryLower),
      )) {
        return true;
      }

      // Search in job locations
      for (var job in company.jobs!) {
        if (job.location!.any(
          (location) => location.toLowerCase().contains(queryLower),
        )) {
          return true;
        }
      }

      // Search in description
      if (company.description != null &&
          company.description!.toLowerCase().contains(queryLower)) {
        return true;
      }

      return false;
    }).toList();
  }

  // Filter companies by various criteria with an optional list of companies to filter
  List<CompanyOut> filterCompanies({
    List<CompanyOut>? companies,
    List<String>? industries,
    List<String>? programmes,
    List<String>? degrees,
    List<String>? positions,
    List<String>? competences,
    bool? hasStudentSessions,
  }) {
    if (!_isLoaded && companies == null) {
      throw Exception(
        'Companies not loaded yet. Call getAllCompanies() first.',
      );
    }

    final List<CompanyOut> companiesToFilter = companies ?? _companies;

    return companiesToFilter.where((company) {
      // Filter by industries
      if (industries != null && industries.isNotEmpty) {
        if (!company.industries!.any((i) => industries.contains(i))) {
          return false;
        }
      }

      // Filter by programmes
      if (programmes != null && programmes.isNotEmpty) {
        if (!company.desiredProgramme!.any((p) => programmes.contains(p))) {
          return false;
        }
      }

      // Filter by degrees
      if (degrees != null && degrees.isNotEmpty) {
        if (!company.desiredDegrees!.any((d) => degrees.contains(d))) {
          return false;
        }
      }

      // Filter by positions
      if (positions != null && positions.isNotEmpty) {
        if (!company.positions!.any((p) => positions.contains(p))) {
          return false;
        }
      }

      // Filter by competences
      if (competences != null && competences.isNotEmpty) {
        if (!company.desiredCompetences!.any((c) => competences.contains(c))) {
          return false;
        }
      }

      // Filter by student sessions availability
      if (hasStudentSessions != null && hasStudentSessions) {
        if (company.daysWithStudentsession <= 0) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
