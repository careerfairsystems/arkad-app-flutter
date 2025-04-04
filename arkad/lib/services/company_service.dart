import 'dart:convert';
import '../config/api_endpoints.dart';
import '../models/company.dart';
import 'api_service.dart';
import 'auth_service.dart';

class CompanyService {
  final AuthService _authService;
  final ApiService _apiService;
  List<Company> _companies = [];
  bool _isLoaded = false;

  CompanyService({
    AuthService? authService,
    ApiService? apiService,
  })  : _authService = authService ?? AuthService(),
        _apiService = apiService ?? ApiService();

  // Getter for cached companies
  List<Company> get companies => _companies;

  // Check if companies are loaded
  bool get isLoaded => _isLoaded;

  // Fetch all companies from API and cache them
  Future<List<Company>> getAllCompanies({bool forceRefresh = false}) async {
    // Return cached data if available and no refresh is requested
    if (_isLoaded && !forceRefresh) {
      return _companies;
    }

    try {
      final response = await _apiService.get(
        ApiEndpoints.companies,
      );

      if (response.isSuccess && response.data != null) {
        // The data is already parsed as a List<dynamic>
        final List<dynamic> companiesJson = response.data as List<dynamic>;
        _companies = companiesJson
            .map((json) => Company.fromJson(json as Map<String, dynamic>))
            .toList();
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
  Company? getCompanyById(int id) {
    if (!_isLoaded) {
      throw Exception(
          'Companies not loaded yet. Call getAllCompanies() first.');
    }

    try {
      return _companies.firstWhere((company) => company.id == id);
    } catch (e) {
      return null; // Return null if no company matches the ID
    }
  }

  // Search companies by name, industries, locations, etc.
  List<Company> searchCompanies(String query) {
    if (!_isLoaded) {
      throw Exception(
          'Companies not loaded yet. Call getAllCompanies() first.');
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
      if (company.industries
          .any((industry) => industry.toLowerCase().contains(queryLower))) {
        return true;
      }

      // Search in job locations
      for (var job in company.jobs) {
        if (job.location
            .any((location) => location.toLowerCase().contains(queryLower))) {
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
  List<Company> filterCompanies({
    List<Company>? companies,
    List<String>? industries,
    List<String>? programmes,
    List<String>? degrees,
    List<String>? positions,
    List<String>? competences,
    bool? hasStudentSessions,
  }) {
    if (!_isLoaded && companies == null) {
      throw Exception(
          'Companies not loaded yet. Call getAllCompanies() first.');
    }

    final List<Company> companiesToFilter = companies ?? _companies;

    return companiesToFilter.where((company) {
      // Filter by industries
      if (industries != null && industries.isNotEmpty) {
        if (!company.industries.any((i) => industries.contains(i))) {
          return false;
        }
      }

      // Filter by programmes
      if (programmes != null && programmes.isNotEmpty) {
        if (!company.desiredProgramme.any((p) => programmes.contains(p))) {
          return false;
        }
      }

      // Filter by degrees
      if (degrees != null && degrees.isNotEmpty) {
        if (!company.desiredDegrees.any((d) => degrees.contains(d))) {
          return false;
        }
      }

      // Filter by positions
      if (positions != null && positions.isNotEmpty) {
        if (!company.positions.any((p) => positions.contains(p))) {
          return false;
        }
      }

      // Filter by competences
      if (competences != null && competences.isNotEmpty) {
        if (!company.desiredCompetences.any((c) => competences.contains(c))) {
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
