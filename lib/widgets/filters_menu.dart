import 'package:flutter/material.dart';

class FiltersMenu extends StatefulWidget {
  final String currentLocation;
  final String currentDateFilter;
  final List<String> currentProviderFilters;
  final Function(String location, String dateFilter, List<String> providerFilters) onFiltersApplied;
  final ScrollController scrollController;

  const FiltersMenu({
    super.key,
    required this.currentLocation,
    required this.currentDateFilter,
    required this.currentProviderFilters,
    required this.onFiltersApplied,
    required this.scrollController,
  });

  @override
  State<FiltersMenu> createState() => _FiltersMenuState();
}

class _FiltersMenuState extends State<FiltersMenu> {
  late String _selectedCountry;
  
  // Date slider mapping
  final List<String> _dateValues = ['', 'hour', 'today', '3days', 'week', 'month'];
  final List<String> _dateLabels = ['Any Time', 'Past 1 hour', 'Past 24 hours', 'Past 3 days', 'Past week', 'Past month'];
  late double _dateSliderValue;

  // Providers
  final List<String> _popularProviders = ['LinkedIn', 'Indeed', 'ZipRecruiter', 'Glassdoor', 'Google'];
  late Set<String> _selectedProviders;
  final TextEditingController _customProviderController = TextEditingController();
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.currentLocation;
    _locationController = TextEditingController(text: _selectedCountry);
    
    int dateIndex = _dateValues.indexOf(widget.currentDateFilter);
    _dateSliderValue = dateIndex >= 0 ? dateIndex.toDouble() : 0.0;
    
    _selectedProviders = Set<String>.from(widget.currentProviderFilters);
  }

  @override
  void dispose() {
    _customProviderController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _addCustomProvider(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      setState(() {
        _selectedProviders.add(trimmed);
      });
      _customProviderController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCountry = '';
                        _locationController.text = '';
                        _dateSliderValue = 0.0;
                        _selectedProviders.clear();
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildSectionTitle(context, 'Date Posted', Icons.access_time_rounded),
                  _buildCard(
                    context,
                    child: Column(
                      children: [
                        Text(
                          _dateLabels[_dateSliderValue.toInt()],
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _dateSliderValue,
                          min: 0,
                          max: 5,
                          divisions: 5,
                          label: _dateLabels[_dateSliderValue.toInt()],
                          onChanged: (value) {
                            setState(() {
                              _dateSliderValue = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Location', Icons.location_on_rounded),
                  _buildCard(
                    context,
                    child: TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'City, State or Country',
                        hintText: 'e.g. San Francisco, CA',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        _selectedCountry = value.trim();
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Job Providers', Icons.business_rounded),
                  _buildCard(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _popularProviders.map((provider) {
                            final isSelected = _selectedProviders.contains(provider);
                            return FilterChip(
                              label: Text(provider),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedProviders.add(provider);
                                  } else {
                                    _selectedProviders.remove(provider);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        
                        // Custom providers already added
                        if (_selectedProviders.difference(_popularProviders.toSet()).isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedProviders
                                .difference(_popularProviders.toSet())
                                .map((provider) => Chip(
                                      label: Text(provider),
                                      onDeleted: () {
                                        setState(() => _selectedProviders.remove(provider));
                                      },
                                    ))
                                .toList(),
                          ),
                        ],

                        const SizedBox(height: 16),
                        TextField(
                          controller: _customProviderController,
                          decoration: InputDecoration(
                            labelText: 'Add Custom Provider (e.g. Monster)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add_circle_rounded),
                              color: theme.colorScheme.primary,
                              onPressed: () => _addCustomProvider(_customProviderController.text),
                            ),
                          ),
                          onSubmitted: _addCustomProvider,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  widget.onFiltersApplied(
                    _selectedCountry,
                    _dateValues[_dateSliderValue.toInt()],
                    _selectedProviders.toList(),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}
