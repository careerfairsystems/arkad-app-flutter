// Openapi Generator last run: : 2025-06-11T17:28:32.045587
import 'package:http/http.dart';
import 'package:openapi_generator_annotations/openapi_generator_annotations.dart';

@Openapi(
  additionalProperties: DioProperties(
    pubName: 'arkad_api',
    pubAuthor: 'Ludvig Lindholm',
  ),
  inputSpec: RemoteSpec(
    path: 'https://staging.backend.arkadtlth.se/api/openapi.json',
  ),
  typeMappings: {'Pet': 'ExamplePet'},
  generatorName: Generator.dio,
  runSourceGenOnOutput: true,
  outputDirectory: 'api/arkad_api',
)
class Example {}

extension ResponseEtension on Response {
  /// Checks if the response is successful based on the HTTP status code
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Returns the error message if the response is not successful
  String? get error => isSuccess ? null : reasonPhrase;
}