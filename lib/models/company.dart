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
}
