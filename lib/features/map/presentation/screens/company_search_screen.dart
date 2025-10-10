import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../company/domain/entities/company.dart';
import '../../../company/presentation/view_models/company_view_model.dart';
import '../view_models/map_view_model.dart';

/// Full-screen company search for the map feature
class CompanySearchScreen extends StatefulWidget {
  const CompanySearchScreen({super.key});

  @override
  State<CompanySearchScreen> createState() => _CompanySearchScreenState();
}

class _CompanySearchScreenState extends State<CompanySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArkadColors.arkadNavy,
      appBar: AppBar(
        backgroundColor: ArkadColors.arkadNavy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ArkadColors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Search Companies',
          style: TextStyle(
            color: ArkadColors.white,
            fontFamily: 'MyriadProCondensed',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search field
          _buildSearchField(),

          // Company list
          Expanded(child: _buildCompanyList()),
        ],
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

  Widget _buildCompanyList() {
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
        // Use MapViewModel to select the company
        final mapViewModel = Provider.of<MapViewModel>(context, listen: false);
        mapViewModel.selectCompany(company.id);

        // Navigate back to map
        context.pop();
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
