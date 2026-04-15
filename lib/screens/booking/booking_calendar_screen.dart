import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../models/trainer_model.dart';
import '../../services/booking_service.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../utils/app_exception.dart';
import 'payment_success_screen.dart';

class BookingCalendarScreen extends StatefulWidget {
  final TrainerModel trainer;

  const BookingCalendarScreen({super.key, required this.trainer});

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen> {
  final BookingService _bookingService = BookingService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<String> _availableTimes = [];
  String? _selectedTime;
  bool _isLoading = false;
  final int _selectedDuration = 60;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAvailability(_focusedDay);
  }

  Future<void> _fetchAvailability(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      // For now, we'll mock more slots but this would call _bookingService.getAvailableSlots
      // await _bookingService.getAvailableSlots(widget.trainer.id, date);
      
      // Mocked available times based on trainer's typical day
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _availableTimes = [
          '09:00:00', '10:00:00', '11:00:00', 
          '14:00:00', '15:00:00', '16:00:00', '17:00:00'
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedTime = null;
      });
      _fetchAvailability(selectedDay);
    }
  }

  Future<void> _handleBooking() async {
    if (_selectedDay == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time slot')),
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
        sessionDate: _selectedDay!,
        sessionTime: _selectedTime!,
        durationMinutes: _selectedDuration,
        locationType: 'trainer_space', // Default for now
        basePrice: widget.trainer.pricePerSession,
        platformFee: platformFee,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              bookingId: booking['id'] as String,
              amount: booking['total_price'] as int,
              trainerName: widget.trainer.fullName,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppException.cleanMessage(e)),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book with ${widget.trainer.fullName}'),
        actions: [
          PopupMenuButton<CalendarFormat>(
            icon: const Icon(Icons.calendar_view_month),
            onSelected: (format) => setState(() => _calendarFormat = format),
            itemBuilder: (context) => [
              const PopupMenuItem(value: CalendarFormat.month, child: Text('Monthly View')),
              const PopupMenuItem(value: CalendarFormat.week, child: Text('Weekly View')),
              const PopupMenuItem(value: CalendarFormat.twoWeeks, child: Text('2-Week View')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppTheme.accentColor,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Available Slots',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _availableTimes.isEmpty
                ? const Center(child: Text('No slots available for this day'))
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _availableTimes.length,
                    itemBuilder: (context, index) {
                      final time = _availableTimes[index];
                      final isSelected = _selectedTime == time;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTime = time),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppTheme.primaryGradient : null,
                            color: isSelected ? null : AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              time.substring(0, 5),
                              style: TextStyle(
                                color: isSelected ? AppTheme.backgroundColor : AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          _buildSummaryBar(),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    if (_selectedTime == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Session',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${_selectedDay!.day}/${_selectedDay!.month} at ${_selectedTime!.substring(0, 5)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleBooking,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('CONFIRM BOOKING'),
            ),
          ],
        ),
      ),
    );
  }
}

