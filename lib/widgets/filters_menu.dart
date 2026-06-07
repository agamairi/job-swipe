import 'package:flutter/material.dart';

class FiltersMenu extends StatefulWidget {
  final String currentLocation;
  final String currentDateFilter;
  final Function(String, String) onFiltersApplied;
  final ScrollController scrollController;

  const FiltersMenu({
    super.key,
    required this.currentLocation,
    required this.currentDateFilter,
    required this.onFiltersApplied,
    required this.scrollController,
  });

  @override
  State<FiltersMenu> createState() => _FiltersMenuState();
}

class _FiltersMenuState extends State<FiltersMenu> {
  late String _selectedCountry;
  late String _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.currentLocation;
    _selectedDate = widget.currentDateFilter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          controller: widget.scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              Text('Filters', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 24),

              _buildCard(
                title: 'Date Posted',
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedDate,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Any Time')),
                    DropdownMenuItem(value: 'hour', child: Text('Past hour')),
                    DropdownMenuItem(value: 'today', child: Text('Past 24 hours')),
                    DropdownMenuItem(value: '3days', child: Text('Past 3 days')),
                    DropdownMenuItem(value: 'week', child: Text('Past week')),
                    DropdownMenuItem(value: 'month', child: Text('Past month')),
                  ],
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _selectedDate = newValue);
                    }
                  },
                ),
              ),

              const SizedBox(height: 16),

              _buildCard(
                title: 'Location',
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCountry,
                  decoration: const InputDecoration(
                    labelText: 'Country/Region',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Canada', 'USA', 'UK', 'Australia'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _selectedCountry = newValue);
                    }
                  },
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFiltersApplied(_selectedCountry, _selectedDate);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
