import 'package:flutter/material.dart';

import '../../../../shared/presentation/widgets/async_state_builder.dart';
import '../../domain/entities/company.dart';
import '../commands/get_companies_command.dart';
import 'company_card.dart';

/// Company list widget with loading/error states
class CompanyList extends StatelessWidget {
  const CompanyList({
    super.key,
    required this.command,
    required this.companies,
    required this.onCompanyTap,
    this.onRefresh,
    this.emptyStateWidget,
    this.padding = const EdgeInsets.all(0),
  });

  final GetCompaniesCommand command;
  final List<Company> companies;
  final Function(Company) onCompanyTap;
  final Future<void> Function()? onRefresh;
  final Widget? emptyStateWidget;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AsyncStateBuilder<List<Company>>(
      command: command,
      builder: (context, _) => _buildCompanyList(context),
      loadingBuilder: (context) => const CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading companies...'),
                ],
              ),
            ),
          ),
        ],
      ),
      errorBuilder: (context, error) => _buildErrorState(context),
    );
  }

  Widget _buildCompanyList(BuildContext context) {
    if (companies.isEmpty) {
      return emptyStateWidget ?? _buildEmptyState(context);
    }

    final widget = ListView.builder(
      padding: padding,
      itemCount: companies.length,
      itemBuilder: (context, index) {
        final company = companies[index];
        return CompanyCard(
          company: company,
          onTap: () => onCompanyTap(company),
        );
      },
    );

    // Wrap with RefreshIndicator if refresh callback is provided
    if (onRefresh != null) {
      return RefreshIndicator(onRefresh: onRefresh!, child: widget);
    }

    return widget;
  }

  Widget _buildEmptyState(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 60,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'No companies found',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search or filter criteria',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load companies',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => command.loadCompanies(forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
