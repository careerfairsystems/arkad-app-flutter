import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Use case for getting current authentication session
class GetCurrentSessionUseCase extends NoParamsUseCase<AuthSession?> {
  const GetCurrentSessionUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthSession?>> call() async {
    try {
      final session = await _repository.getCurrentSession();
      return Result.success(session);
    } catch (e) {
      await Sentry.captureException(e);
      // If there's any error getting session, return null (unauthenticated)
      return Result.success(null);
    }
  }
}
