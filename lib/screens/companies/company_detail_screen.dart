import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/company.dart';
import '../../models/job.dart';

class CompanyDetailScreen extends StatelessWidget {
  final Company company;

  const CompanyDetailScreen({super.key, required this.company});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(company.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(context),
            _buildDescriptionSection(context),
            _buildFactsSection(context),
            _buildSocialLinksSection(context),
            _buildStudentSessionSection(context),
            _buildJobsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          if (company.fullLogoUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                company.fullLogoUrl!,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    width: 120,
                    color: Colors.grey[200],
                    child: const Icon(Icons.business,
                        size: 60, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            company.name,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            company.industriesString,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          if (company.website != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.language),
              label: const Text('Visit Website'),
              onPressed: () => _launchUrl(company.website!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    if (company.description == null || company.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(company.description!),
        ],
      ),
    );
  }

  Widget _buildFactsSection(BuildContext context) {
    if ((company.didYouKnow == null || company.didYouKnow!.isEmpty) &&
        company.employeesLocally == null &&
        company.employeesGlobally == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company Facts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (company.didYouKnow != null && company.didYouKnow!.isNotEmpty) ...[
            Text(
              'Did You Know?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(company.didYouKnow!),
            const SizedBox(height: 16),
          ],
          if (company.employeesLocally != null) ...[
            _buildInfoRow('Employees locally:', '${company.employeesLocally}'),
          ],
          if (company.employeesGlobally != null) ...[
            _buildInfoRow(
                'Employees globally:', '${company.employeesGlobally}'),
          ],
          const SizedBox(height: 8),
          if (company.positions.isNotEmpty) ...[
            Text(
              'Positions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: company.positions
                  .map((position) => Chip(label: Text(position)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSocialLinksSection(BuildContext context) {
    final hasSocialMedia = [
      company.urlLinkedin,
      company.urlInstagram,
      company.urlFacebook,
      company.urlTwitter,
      company.urlYoutube,
    ].any((url) => url != null && url.isNotEmpty);

    if (!hasSocialMedia) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect With Us',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              if (company.urlLinkedin != null &&
                  company.urlLinkedin!.isNotEmpty)
                _buildSocialButton(
                  context,
                  Icons.link,
                  'LinkedIn',
                  company.urlLinkedin!,
                ),
              if (company.urlInstagram != null &&
                  company.urlInstagram!.isNotEmpty)
                _buildSocialButton(
                  context,
                  Icons.photo_camera,
                  'Instagram',
                  company.urlInstagram!,
                ),
              if (company.urlFacebook != null &&
                  company.urlFacebook!.isNotEmpty)
                _buildSocialButton(
                  context,
                  Icons.facebook,
                  'Facebook',
                  company.urlFacebook!,
                ),
              if (company.urlTwitter != null && company.urlTwitter!.isNotEmpty)
                _buildSocialButton(
                  context,
                  Icons.flutter_dash,
                  'Twitter',
                  company.urlTwitter!,
                ),
              if (company.urlYoutube != null && company.urlYoutube!.isNotEmpty)
                _buildSocialButton(
                  context,
                  Icons.video_library,
                  'YouTube',
                  company.urlYoutube!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSessionSection(BuildContext context) {
    if (company.daysWithStudentsession <= 0 ||
        (company.studentSessionMotivation == null ||
            company.studentSessionMotivation!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Sessions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
              'Days with sessions:', '${company.daysWithStudentsession}'),
          const SizedBox(height: 8),
          if (company.studentSessionMotivation != null) ...[
            Text(
              'Why meet with us:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(company.studentSessionMotivation!),
          ],
        ],
      ),
    );
  }

  Widget _buildJobsSection(BuildContext context) {
    if (company.jobs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Opportunities',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: company.jobs.length,
            itemBuilder: (context, index) {
              return _buildJobCard(context, company.jobs[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, Job job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.title ?? 'Untitled Position',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (job.location.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(job.location.join(', ')),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (job.jobType.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.work, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(job.jobType.join(', ')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (job.description != null && job.description!.isNotEmpty) ...[
              Text(
                job.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
            if (job.link != null && job.link!.isNotEmpty)
              ElevatedButton(
                onPressed: () => _launchUrl(job.link!),
                child: const Text('Apply Now'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSocialButton(
      BuildContext context, IconData icon, String platform, String url) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 4),
            Text(platform),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
