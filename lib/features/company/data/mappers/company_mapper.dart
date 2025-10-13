import 'package:arkad_api/arkad_api.dart';

import '../../domain/entities/company.dart';

class CompanyMapper {
  const CompanyMapper();

  Company fromDto(CompanyOut dto) {
    return Company(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      logoUrl: dto.logoUrl,
      industries: dto.industries?.toList() ?? [],
      desiredProgrammes: dto.desiredProgramme?.toList() ?? [],
      desiredDegrees: dto.desiredDegrees?.toList() ?? [],
      positions: dto.positions?.toList() ?? [],
      desiredCompetences: dto.desiredCompetences?.toList() ?? [],
      jobs: dto.jobs?.map(_mapJobSchema).toList() ?? [],
      hasStudentSession: dto.hasStudentSession ?? false,
      urlLinkedin: dto.urlLinkedin,
      urlInstagram: dto.urlInstagram,
      urlFacebook: dto.urlFacebook,
      urlTwitter: dto.urlTwitter,
      urlYoutube: dto.urlYoutube,
      websiteUrl: dto.website,
      studentSessionMotivation: dto.studentSessionMotivation,
      visibleInCompanyList: dto.visibleInCompanyList ?? true,
    );
  }

  List<Company> fromDtoList(List<CompanyOut> dtos) {
    return dtos.map(fromDto).toList();
  }

  CompanyJob _mapJobSchema(JobSchema jobSchema) {
    return CompanyJob(
      id: jobSchema.id,
      title: jobSchema.title ?? '',
      locations: jobSchema.location?.toList() ?? [],
      jobTypes: jobSchema.jobType?.toList() ?? [],
      description: jobSchema.description,
      link: jobSchema.link,
    );
  }
}
