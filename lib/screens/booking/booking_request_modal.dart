import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../models/trainer_model.dart';
import '../../config/theme.dart';
import 'payment_confirmation_screen.dart';

class BookingRequestModal extends StatefulWidget {
  final TrainerModel trainer;

  const BookingRequestModal({
    super.key,
    required this.trainer,
  });

  @override
  State<BookingRequestModal> createState() => _BookingRequestModalState();
}

class _BookingRequestModalState extends State<BookingRequestModal> {
  final BookingService _bookingService = BookingService();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _selectedDuration = 60;
  String _selectedLocation = 'trainer_space';
  bool _isLoading = false;

  final List<int> _durations = [30, 45, 60, 90];
  final Map<String, String> _locations = {
    'trainer_space': 'Trainer\'s Studio',
    'client_location': 'Your Location',
    'park': 'Outdoor/Park',
    'gym': 'Gym',
  };

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: AppTheme.backgroundColor,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: AppTheme.backgroundColor,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _createBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final platformFee = _bookingService.calculatePlatformFee(widget.trainer.pricePerSession);
      
      final booking = await _bookingService.createBooking(
        clientId: currentUser.id,
        trainerId: widget.trainer.id,
        sessionDate: _selectedDate!,
        sessionTime: '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00',
        durationMinutes: _selectedDuration,
        locationType: _selectedLocation,
        basePrice: widget.trainer.pricePerSession,
        platformFee: platformFee,
      );

      if (mounted) {
        Navigator.pop(context); // Close modal
        
        // Navigate to payment confirmation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentConfirmationScreen(
              bookingId: booking['id'] as String,
              totalAmount: booking['total_price'] as int,
              trainerName: widget.trainer.fullName,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final platformFee = _bookingService.calculatePlatformFee(widget.trainer.pricePerSession);
    final totalPrice = widget.trainer.pricePerSession + platformFee;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacingLG),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            SizedBox(height: AppTheme.spacingLG),
            
            // Title
            Text(
              'Book a Session',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            
            SizedBox(height: AppTheme.spacingXS),
            
            Text(
              'with ${widget.trainer.fullName}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
            
            SizedBox(height: AppTheme.spacingXL),
            
            // Date Picker
            _buildSelectorTile(
              icon: Icons.calendar_today_rounded,
              label: 'Date',
              value: _selectedDate != null
                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                  : 'Select date',
              onTap: _selectDate,
            ),
            
            SizedBox(height: AppTheme.spacingMD),
            
            // Time Picker
            _buildSelectorTile(
              icon: Icons.access_time_rounded,
              label: 'Time',
              value: _selectedTime != null
                  ? _selectedTime!.format(context)
                  : 'Select time',
              onTap: _selectTime,
            ),
            
            SizedBox(height: AppTheme.spacingXL),
            
            // Duration
            Text(
              'Duration',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppTheme.spacingSM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durations.map((duration) {
                final isSelected = _selectedDuration == duration;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDuration = duration),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppTheme.primaryGradient : null,
                      color: isSelected ? null : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '$duration min',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected ? AppTheme.backgroundColor : AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            SizedBox(height: AppTheme.spacingXL),
            
            // Location
            Text(
              'Location',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppTheme.spacingSM),
            ..._locations.entries.map((entry) {
              final isSelected = _selectedLocation == entry.key;
              return Padding(
                padding: EdgeInsets.only(bottom: AppTheme.spacingSM),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedLocation = entry.key),
                  child: Container(
                    padding: EdgeInsets.all(AppTheme.spacingMD),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppTheme.primaryGradient.withOpacity(0.2) : null,
                      color: isSelected ? null : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getLocationIcon(entry.key),
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                        ),
                        SizedBox(width: AppTheme.spacingMD),
                        Text(
                          entry.value,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            
            SizedBox(height: AppTheme.spacingXL),
            
            // Price Breakdown
            Container(
              padding: EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildPriceRow('Session Fee', widget.trainer.pricePerSession),
                  SizedBox(height: AppTheme.spacingSM),
                  _buildPriceRow('Platform Fee', platformFee),
                  Divider(height: AppTheme.spacingLG, color: AppTheme.textSecondary.withOpacity(0.3)),
                  _buildPriceRow('Total', totalPrice, isTotal: true),
                ],
              ),
            ),
            
            SizedBox(height: AppTheme.spacingXL),
            
            // Book Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createBooking,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Proceed to Payment'),
              ),
            ),
            
            SizedBox(height: AppTheme.spacingMD),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            SizedBox(width: AppTheme.spacingMD),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, int amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          '₹$amount',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
      ],
    );
  }

  IconData _getLocationIcon(String location) {
    switch (location) {
      case 'trainer_space':
        return Icons.home_work_rounded;
      case 'client_location':
        return Icons.home_rounded;
      case 'park':
        return Icons.park_rounded;
      case 'gym':
        return Icons.fitness_center_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }
}