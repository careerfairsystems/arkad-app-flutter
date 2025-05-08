import 'package:flutter/material.dart';

/// Displays a map of the ARKAD event
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  // Map location selection
  final List<String> _locations = [
    'Building A',
    'Building B',
    'Building C',
    'Building D',
  ];
  String _selectedLocation = 'Building A';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Map')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
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
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Implement reload functionality
                setState(() {
                  _errorMessage = null;
                });
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Location selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildLocationSelector(),
        ),

        // Map display area
        Expanded(child: _buildMapPlaceholder()),

        // Legend or additional info
        Padding(padding: const EdgeInsets.all(16.0), child: _buildMapLegend()),
      ],
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLocation,
          icon: const Icon(Icons.arrow_drop_down),
          isExpanded: true,
          hint: const Text('Select Location'),
          onChanged: (String? newValue) {
            setState(() {
              _selectedLocation = newValue!;
            });
          },
          items:
              _locations.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 100, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Map for $_selectedLocation',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Interactive Map Coming Soon',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.info_outline),
              label: const Text('View Building Info'),
              onPressed: () {
                _showBuildingInfo();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Map Legend',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildLegendItem(Icons.circle, Colors.blue, 'Company Booth'),
            _buildLegendItem(Icons.circle, Colors.red, 'Information Desk'),
            _buildLegendItem(Icons.circle, Colors.green, 'Restrooms'),
            _buildLegendItem(Icons.circle, Colors.orange, 'Refreshments'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  void _showBuildingInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(_selectedLocation),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Opening Hours: 9:00 AM - 5:00 PM'),
                const SizedBox(height: 8),
                const Text('Number of Companies: 42'),
                const SizedBox(height: 8),
                const Text(
                  'Facilities: Restrooms, Refreshments, Information Desk',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
