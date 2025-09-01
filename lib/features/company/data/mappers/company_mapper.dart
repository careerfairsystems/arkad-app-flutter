import 'package:arkad_api/arkad_api.dart';

import '../../domain/entities/company.dart';

/// Mapper for converting between API DTOs and Domain entities
class CompanyMapper {
  const CompanyMapper();

  /// Convert CompanyOut DTO to Company domain entity
  Company fromDto(CompanyOut dto) {
    return Company(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      logoUrl: dto.logoUrl,
      websiteUrl: null, // Not available in current DTO
      industries: _convertToStringList(dto.industries),
      desiredProgrammes: _convertToStringList(dto.desiredProgramme),
      desiredDegrees: _convertToStringList(dto.desiredDegrees),
      positions: _convertToStringList(dto.positions),
      desiredCompetences: _convertToStringList(dto.desiredCompetences),
      jobs: _mapJobs(dto.jobs),
      daysWithStudentSession: dto.daysWithStudentsession,
    );
  }

  /// Convert list of CompanyOut DTOs to Company entities
  List<Company> fromDtoList(List<CompanyOut> dtos) {
    return dtos.map(fromDto).toList();
  }

  /// Convert job DTOs to CompanyJob entities
  List<CompanyJob> _mapJobs(Object? jobs) {
    if (jobs == null) return [];
    
    // The jobs field might be a list of dynamic objects
    if (jobs is List) {
      return jobs.map((job) {
        if (job == null) return null;
        
        // Extract job information safely
        final id = job is Map ? (job['id'] as int? ?? 0) : 0;
        final title = job is Map ? (job['title'] as String? ?? '') : '';
        final locations = job is Map ? _convertToStringList(job['location']) : <String>[];
        final description = job is Map ? (job['description'] as String?) : null;
        
        return CompanyJob(
          id: id,
          title: title,
          locations: locations,
          description: description,
        );
      }).whereType<CompanyJob>().toList();
    }
    
    return [];
  }

  /// Convert dynamic object to List<String>
  List<String> _convertToStringList(Object? obj) {
    if (obj == null) return [];
    
    if (obj is List) {
      return obj
          .where((item) => item != null)
          .map((item) => item.toString())
          .toList();
    }
    
    return [];
  }
}