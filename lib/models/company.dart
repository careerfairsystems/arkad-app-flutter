import 'package:arkad_api/arkad_api.dart';

extension CompanyExtension on CompanyOut {
  // Returns the full logo URL with the base media URL prepended
  String? get fullLogoUrl => logoUrl != null ? (logoUrl!) : null;

  // Returns a comma-separated string of industries
  String get industriesString =>
      industries == null ? "" : industries!.join(', ');

  // Returns a comma-separated string of locations from jobs
  String get locationsString {
    if (jobs == null || jobs!.isEmpty) {
      return "";
    }
    Set<String> uniqueLocations = {};
    for (var job in jobs!) {
      if (job.location == null || job.location!.isEmpty) {
        continue;
      }
      uniqueLocations.addAll(job.location!);
    }
    return uniqueLocations.join(', ');
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    List<dynamic> jobsJson = json['jobs'] ?? [];
    List<Job> parsedJobs =
        jobsJson.map((jobJson) => Job.fromJson(jobJson)).toList();

    return Company(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      didYouKnow: json['did_you_know'],
      logoUrl: json['logo_url'],
      urlLinkedin: json['url_linkedin'],
      urlInstagram: json['url_instagram'],
      urlFacebook: json['url_facebook'],
      urlTwitter: json['url_twitter'],
      urlYoutube: json['url_youtube'],
      website: json['website'],
      studentSessionMotivation: json['student_session_motivation'],
      daysWithStudentsession: json['daysWithStudentsession'] ?? 0,
      desiredDegrees: List<String>.from(json['desired_degrees'] ?? []),
      desiredProgramme: List<String>.from(json['desired_programme'] ?? []),
      desiredCompetences: List<String>.from(json['desired_competences'] ?? []),
      positions: List<String>.from(json['positions'] ?? []),
      industries: List<String>.from(json['industries'] ?? []),
      employeesLocally: json['employees_locally'],
      employeesGlobally: json['employees_globally'],
      jobs: parsedJobs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'did_you_know': didYouKnow,
      'logo_url': logoUrl,
      'url_linkedin': urlLinkedin,
      'url_instagram': urlInstagram,
      'url_facebook': urlFacebook,
      'url_twitter': urlTwitter,
      'url_youtube': urlYoutube,
      'website': website,
      'student_session_motivation': studentSessionMotivation,
      'days_with_studentsession': daysWithStudentsession,
      'desired_degrees': desiredDegrees,
      'desired_programme': desiredProgramme,
      'desired_competences': desiredCompetences,
      'positions': positions,
      'industries': industries,
      'employees_locally': employeesLocally,
      'employees_globally': employeesGlobally,
      'jobs': jobs.map((job) => job.toJson()).toList(),
    };
  }
}
