import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/trainer_service.dart';
import '../../models/trainer_model.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/trainer_card.dart';
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TrainerService _trainerService;
  final TextEditingController _searchController = TextEditingController();
  
  List<TrainerModel> _trainers = [];
  List<TrainerModel> _filteredTrainers = [];
  bool _isLoading = false;
  
  // Filters
  String? _selectedSpecialty;
  double _maxPrice = AppConstants.maxPrice.toDouble();
  double _minRating = 0.0;
  bool _showFilters = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _trainerService = context.read<TrainerService>();
    _loadAllTrainers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllTrainers() async {
    setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthProvider>().user?.id;
      final trainers = await _trainerService.getTrainers(
        limit: 100,
        excludeUserId: userId,
      );
      setState(() {
        _trainers = trainers;
        _filteredTrainers = trainers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTrainers = _trainers.where((trainer) {
        // Text search
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch = searchQuery.isEmpty ||
            trainer.fullName.toLowerCase().contains(searchQuery) ||
            trainer.specialties.any((s) => s.toLowerCase().contains(searchQuery));

        // Specialty filter
        final matchesSpecialty = _selectedSpecialty == null ||
            trainer.specialties.contains(_selectedSpecialty!.toLowerCase());

        // Price filter
        final matchesPrice = trainer.pricePerSession <= _maxPrice.toInt();

        // Rating filter
        final matchesRating = trainer.averageRating >= _minRating;

        return matchesSearch && matchesSpecialty && matchesPrice && matchesRating;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedSpecialty = null;
      _maxPrice = AppConstants.maxPrice.toDouble();
      _minRating = 0.0;
      _filteredTrainers = _trainers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            if (_showFilters) _buildFilters(),
            _buildResultsHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Search Trainers',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by name or specialty...',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.primaryColor,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    _applyFilters();
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              setState(() => _showFilters = !_showFilters);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _showFilters
                    ? AppTheme.primaryColor
                    : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: _showFilters
                    ? AppTheme.backgroundColor
                    : AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Specialty Filter
          Text(
            'Specialty',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSpecialtyChip('All', null),
              ...AppConstants.specialties.map((specialty) {
                return _buildSpecialtyChip(specialty, specialty);
              }).toList(),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Price Range
          Text(
            'Max Price: ₹${_maxPrice.toInt()}/session',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          Slider(
            value: _maxPrice,
            min: AppConstants.minPrice.toDouble(),
            max: AppConstants.maxPrice.toDouble(),
            divisions: 40,
            activeColor: AppTheme.primaryColor,
            inactiveColor: AppTheme.textSecondary.withOpacity(0.2),
            onChanged: (value) {
              setState(() => _maxPrice = value);
              _applyFilters();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Rating Filter
          Text(
            'Min Rating: ${_minRating.toStringAsFixed(1)} ⭐',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 10,
            activeColor: AppTheme.warningColor,
            inactiveColor: AppTheme.textSecondary.withOpacity(0.2),
            onChanged: (value) {
              setState(() => _minRating = value);
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyChip(String label, String? value) {
    final isSelected = _selectedSpecialty == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedSpecialty = value);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textSecondary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected ? AppTheme.backgroundColor : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Text(
            '${_filteredTrainers.length} Trainers Found',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const Spacer(),
          if (_filteredTrainers.length != _trainers.length)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_filteredTrainers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Trainers Found',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredTrainers.length,
      itemBuilder: (context, index) {
        final trainer = _filteredTrainers[index];
        return TrainerCard(trainer: trainer);
      },
    );
  }
}