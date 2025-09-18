import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/data/repositories/base_repository.dart';
import '../../../../shared/domain/result.dart';
import '../../domain/entities/company.dart';
import '../../domain/errors/company_errors.dart';
import '../../domain/repositories/company_repository.dart';
import '../data_sources/company_local_data_source.dart';
import '../data_sources/company_remote_data_source.dart';
import '../mappers/company_mapper.dart';

class CompanyRepositoryImpl extends BaseRepository
    implements CompanyRepository {
  CompanyRepositoryImpl({
    required CompanyRemoteDataSource remoteDataSource,
    required CompanyLocalDataSource localDataSource,
    required CompanyMapper mapper,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _mapper = mapper;

  final CompanyRemoteDataSource _remoteDataSource;
  final CompanyLocalDataSource _localDataSource;
  final CompanyMapper _mapper;

  @override
  Future<Result<List<Company>>> getCompanies({bool forceRefresh = false}) {
    return executeOperation(() async {
      if (!forceRefresh) {
        final cachedCompanies = _localDataSource.getCachedCompanies();
        if (cachedCompanies != null) {
          return _mapper.fromDtoList(cachedCompanies);
        }
      }

      final companiesDto = await _remoteDataSource.getCompanies();
      _localDataSource.cacheCompanies(companiesDto);
      return _mapper.fromDtoList(companiesDto);
    }, 'get companies');
  }

  @override
  Future<Result<Company>> getCompanyById(int id) {
    return executeOperation(() async {
      final companiesResult = await getCompanies();

      return companiesResult.when(
        success: (companies) {
          try {
            return companies.firstWhere((company) => company.id == id);
          } catch (e) {
            throw CompanyNotFoundError(id);
          }
        },
        failure: (error) => throw error,
      );
    }, 'get company by id');
  }

  @override
  Future<Result<List<Company>>> searchCompanies(String query) {
    return executeOperation(() async {
      final companiesResult = await getCompanies();

      return companiesResult.when(
        success: (companies) {
          if (query.isEmpty) return companies;

          return companies
              .where((company) => company.matchesSearchQuery(query))
              .toList();
        },
        failure: (error) => throw error,
      );
    }, 'search companies');
  }

  @override
  Future<Result<List<Company>>> filterCompanies(CompanyFilter filter) {
    return executeOperation(() async {
      final companiesResult = await getCompanies();

      return companiesResult.when(
        success: (companies) {
          if (!filter.hasActiveFilters) return companies;

          return companies
              .where((company) => company.matchesFilter(filter))
              .toList();
        },
        failure: (error) => throw error,
      );
    }, 'filter companies');
  }

  @override
  Future<Result<List<Company>>> searchAndFilterCompanies(
    String query,
    CompanyFilter filter,
  ) {
    return executeOperation(() async {
      final companiesResult = await getCompanies();

      return companiesResult.when(
        success: (companies) {
          var filteredCompanies = companies;

          if (query.isNotEmpty) {
            filteredCompanies =
                filteredCompanies
                    .where((company) => company.matchesSearchQuery(query))
                    .toList();
          }

          if (filter.hasActiveFilters) {
            filteredCompanies =
                filteredCompanies
                    .where((company) => company.matchesFilter(filter))
                    .toList();
          }

          return filteredCompanies;
        },
        failure: (error) => throw error,
      );
    }, 'search and filter companies');
  }

  @override
  Future<void> clearCache() async {
    _localDataSource.clearCache();
  }
}
