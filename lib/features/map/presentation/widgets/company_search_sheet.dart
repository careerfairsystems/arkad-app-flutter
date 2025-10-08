import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../company/domain/entities/company.dart';
import '../../../company/presentation/view_models/company_view_model.dart';

/// Bottom sheet for searching and selecting companies on the map
///
/// Displays a draggable modal with:
/// - Search field with real-time filtering
/// - List of companies matching the search query
/// - Loading and empty states
class CompanySearchSheet extends StatefulWidget {
  const CompanySearchSheet({super.key, required this.onCompanySelected});

  final void Function(Company) onCompanySelected;

  @override
  State<CompanySearchSheet> createState() => _CompanySearchSheetState();
}

class _CompanySearchSheetState extends State<CompanySearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: ArkadColors.arkadNavy,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              _buildHandleBar(),

              // Search field
              _buildSearchField(),

              // Company list
              Expanded(child: _buildCompanyList(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandleBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: ArkadColors.lightGray,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(
          color: ArkadColors.white,
          fontFamily: 'MyriadProCondensed',
        ),
        decoration: InputDecoration(
          hintText: 'Search companies',
          hintStyle: const TextStyle(
            color: ArkadColors.lightGray,
            fontFamily: 'MyriadProCondensed',
          ),
          prefixIcon: const Icon(Icons.search, color: ArkadColors.arkadTurkos),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: ArkadColors.arkadTurkos),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: ArkadColors.arkadLightNavy,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCompanyList(ScrollController scrollController) {
    return Consumer<CompanyViewModel>(
      builder: (context, companyViewModel, child) {
        final companies = companyViewModel.allCompanies
            .where((company) => company.matchesSearchQuery(_searchQuery))
            .toList();

        if (companyViewModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: ArkadColors.arkadTurkos),
          );
        }

        if (companies.isEmpty) {
          return Center(
            child: Text(
              _searchQuery.isEmpty
                  ? 'No companies available'
                  : 'No companies found',
              style: const TextStyle(
                color: ArkadColors.lightGray,
                fontFamily: 'MyriadProCondensed',
              ),
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          itemCount: companies.length,
          itemBuilder: (context, index) {
            final company = companies[index];
            return _buildCompanyListItem(company);
          },
        );
      },
    );
  }

  Widget _buildCompanyListItem(Company company) {
    return ListTile(
      leading: _buildCompanyLogo(company),
      title: Text(
        company.name,
        style: const TextStyle(
          color: ArkadColors.white,
          fontFamily: 'MyriadProCondensed',
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: company.industries.isNotEmpty
          ? Text(
              company.industries.first,
              style: const TextStyle(
                color: ArkadColors.lightGray,
                fontFamily: 'MyriadProCondensed',
              ),
            )
          : null,
      onTap: () {
        widget.onCompanySelected(company);
      },
    );
  }

  Widget _buildCompanyLogo(Company company) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: ArkadColors.arkadLightNavy,
        borderRadius: BorderRadius.circular(8),
      ),
      child: company.logoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                company.logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.business, color: ArkadColors.arkadTurkos),
              ),
            )
          : const Icon(Icons.business, color: ArkadColors.arkadTurkos),
    );
  }
}
