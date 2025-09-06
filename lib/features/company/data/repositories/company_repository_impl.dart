import '../../../../shared/data/repositories/base_repository.dart';
import '../../../../shared/domain/result.dart';
import '../../domain/entities/company.dart';
import '../../domain/errors/company_errors.dart';
import '../../domain/repositories/company_repository.dart';
import '../data_sources/company_local_data_source.dart';
import '../data_sources/company_remote_data_source.dart';
import '../mappers/company_mapper.dart';

/// Implementation of CompanyRepository using clean architecture patterns
class CompanyRepositoryImpl extends BaseRepository
    with CachedRepositoryMixin<List<Company>>
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

  static const String _companiesKey = 'companies';

  @override
  Future<Result<List<Company>>> getCompanies({bool forceRefresh = false}) {
    return executeWithCache(
      _companiesKey,
      () => executeOperation(
        () async {
          // Check local cache first if not forcing refresh
          if (!forceRefresh) {
            final cachedCompanies = _localDataSource.getCachedCompanies();
            if (cachedCompanies != null) {
              return _mapper.fromDtoList(cachedCompanies);
            }
          }

          // Fetch from remote
          final companiesDto = await _remoteDataSource.getCompanies();

          // Cache locally
          _localDataSource.cacheCompanies(companiesDto);

          // Convert to domain entities
          return _mapper.fromDtoList(companiesDto);
        },
        'get companies',
        onError: (error) {
          // If it's a cache error, try to get from local as fallback
          if (error is CompanyCacheError) {
            final cachedCompanies = _localDataSource.getCachedCompanies();
            if (cachedCompanies != null && cachedCompanies.isNotEmpty) {
              // Return cached data even if expired as fallback
              return;
            }
          }
        },
      ),
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<Result<Company>> getCompanyById(int id) {
    return executeOperation(() async {
      // Try to get company from cached data first
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

          // Apply search filter
          if (query.isNotEmpty) {
            filteredCompanies =
                filteredCompanies
                    .where((company) => company.matchesSearchQuery(query))
                    .toList();
          }

          // Apply other filters
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
    clearCacheItem(_companiesKey);
    _localDataSource.clearCache();
  }

  @override
  Duration get cacheExpiration => const Duration(minutes: 10);
}
