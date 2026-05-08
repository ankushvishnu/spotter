import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/credits_service.dart';
import '../../models/trainer_model.dart';
import '../../models/trainer_availability.dart';
import '../../models/blocked_slot.dart';
import '../../config/theme.dart';
import '../../utils/app_exception.dart';
import 'payment_success_screen.dart';
import '../credits/buy_credits_screen.dart';
import 'package:table_calendar/table_calendar.dart';

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
  final CreditsService _creditsService = CreditsService();
  final PageController _pageCtrl = PageController();

  // Data
  TrainerAvailability? _availability;
  bool _loadingAvailability = true;
  final Map<String, List<BlockedSlot>> _blockedSlotsCache = {}; // dateStr → slots

  // Step 1 state
  final List<DateTime> _selectedDates = [];
  DateTime _focusedDay = DateTime.now();

  // Step 2 state
  TimeOfDay? _selectedTime;
  int? _selectedDuration;
  String? _selectedCategory;
  String _selectedLocation = 'trainer_space';
  bool _isLoading = false;

  // Credit state
  int _userCredits = 0;
  bool _loadingCredits = true;

  // Per-date times (opt-in)
  Map<String, TimeOfDay>? _perDateTimes; // dateStr → time

  int _currentStep = 0;

  final Map<String, String> _locations = {
    'trainer_space': 'Trainer\'s Studio',
    'client_location': 'Your Location',
    'park': 'Outdoor/Park',
    'gym': 'Gym',
  };

  @override
  void initState() {
    super.initState();
    _loadAvailability();
    _loadUserCredits();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    try {
      final avail = await _bookingService.getTrainerAvailability(widget.trainer.id);
      if (mounted) {
        setState(() {
          _availability = avail;
          _loadingAvailability = false;
          // Default to first available duration
          if (avail.sessionDurations.isNotEmpty) {
            _selectedDuration = avail.sessionDurations.contains(60)
                ? 60
                : avail.sessionDurations.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAvailability = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppException.cleanMessage(e)), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _loadUserCredits() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    try {
      final credits = await _creditsService.getUserCredits(userId);
      if (mounted) {
        setState(() {
          _userCredits = credits;
          _loadingCredits = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCredits = false);
      }
    }
  }

  int get _creditsRequired => _selectedDates.length;
  bool get _hasInsufficientCredits => !_loadingCredits && _userCredits < _creditsRequired;

  /// Pre-fetch blocked slots for a date when it's selected
  Future<void> _fetchBlockedSlots(DateTime date) async {
    final key = date.toIso8601String().split('T')[0];
    if (_blockedSlotsCache.containsKey(key)) return;
    final slots = await _bookingService.getBlockedTimesForDate(widget.trainer.id, date);
    if (mounted) {
      setState(() => _blockedSlotsCache[key] = slots);
    }
  }

  bool _isDateEnabled(DateTime day) {
    if (_availability == null) return false;
    // Block if explicitly unavailable
    if (_availability!.isDateUnavailable(day)) return false;
    // Block if trainer doesn't work that weekday
    if (!_availability!.worksOnDay(day)) return false;
    return true;
  }

  bool _isDaySelected(DateTime day) {
    return _selectedDates.any((d) => isSameDay(d, day));
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      final existingIndex = _selectedDates.indexWhere((d) => isSameDay(d, selectedDay));
      if (existingIndex >= 0) {
        _selectedDates.removeAt(existingIndex);
      } else {
        _selectedDates.add(selectedDay);
        _fetchBlockedSlots(selectedDay);
      }
      _focusedDay = focusedDay;
    });
  }

  void _goToStep2() {
    setState(() => _currentStep = 1);
    _pageCtrl.animateToPage(1, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  void _goToStep1() {
    setState(() => _currentStep = 0);
    _pageCtrl.animateToPage(0, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  /// Generate time slots for the selected dates based on working hours
  List<TimeOfDay> _generateTimeSlots() {
    if (_availability == null || _selectedDates.isEmpty) return [];

    // Find the intersection of working hours across all selected dates
    int earliestStart = 0;
    int latestEnd = 24 * 60;

    for (final date in _selectedDates) {
      final schedule = _availability!.getScheduleForDate(date);
      if (schedule == null) continue;
      final startMin = schedule.start.hour * 60 + schedule.start.minute;
      final endMin = schedule.end.hour * 60 + schedule.end.minute;
      if (startMin > earliestStart) earliestStart = startMin;
      if (endMin < latestEnd) latestEnd = endMin;
    }

    // Generate 30-min slots
    final slots = <TimeOfDay>[];
    for (int m = earliestStart; m < latestEnd; m += 30) {
      slots.add(TimeOfDay(hour: m ~/ 60, minute: m % 60));
    }
    return slots;
  }

  /// Check if a time slot is blocked on ANY of the selected dates
  /// It is blocked if it overlaps with an existing booking OR if adding the duration exceeds the day's working hours.
  bool _isSlotBlocked(TimeOfDay time) {
    if (_selectedDuration == null) return false;
    for (final date in _selectedDates) {
      final key = date.toIso8601String().split('T')[0];
      
      // Check if it exceeds working hour end time
      final schedule = _availability?.getScheduleForDate(date);
      if (schedule != null) {
        final pEndMin = (time.hour * 60 + time.minute) + _selectedDuration!;
        final wEndMin = schedule.end.hour * 60 + schedule.end.minute;
        if (pEndMin > wEndMin) return true;
      }

      // Check conflicts with existing bookings
      final blocked = _blockedSlotsCache[key] ?? [];
      for (final slot in blocked) {
        if (slot.conflictsWith(time, _selectedDuration!)) return true;
      }
    }
    return false;
  }

  int get _currentPrice {
    if (_availability == null || _selectedDuration == null) return 0;
    return _availability!.getPriceForDuration(_selectedDuration!, widget.trainer.pricePerSession);
  }

  int get _platformFee => _bookingService.calculatePlatformFee(_currentPrice);

  int get _totalPrice => (_currentPrice + _platformFee) * (_selectedDates.isEmpty ? 1 : _selectedDates.length);

  bool get _canConfirmBooking =>
      _selectedTime != null && _selectedDuration != null && _selectedCategory != null && _selectedDates.isNotEmpty && !_hasInsufficientCredits;

  Future<void> _showPerDateTimePromptAndBook() async {
    if (!_canConfirmBooking) return;

    // Prompt: same time or per-date?
    if (_selectedDates.length > 1) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Time for sessions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apply ${_selectedTime!.format(context)} to all ${_selectedDates.length} sessions?',
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                'You can always reschedule your bookings whenever you want from My Bookings tab.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'per_date'),
              child: const Text('Set per-date times'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'same'),
              child: const Text('Same time for all'),
            ),
          ],
        ),
      );

      if (choice == null) return; // Dismissed

      if (choice == 'per_date') {
        await _showPerDateTimeEditor();
        return;
      }
    }

    // Same time for all — proceed to book
    await _createBooking(null);
  }

  Future<void> _showPerDateTimeEditor() async {
    final perTimes = <String, TimeOfDay>{};
    for (final d in _selectedDates) {
      perTimes[d.toIso8601String().split('T')[0]] = _selectedTime!;
    }

    final confirmed = await showDialog<Map<String, TimeOfDay>>(
      context: context,
      builder: (ctx) => _PerDateTimeDialog(
        dates: _selectedDates,
        initialTimes: perTimes,
        availability: _availability!,
        blockedSlotsCache: _blockedSlotsCache,
        selectedDuration: _selectedDuration!,
      ),
    );

    if (confirmed != null && mounted) {
      await _createBooking(confirmed);
    }
  }

  Future<void> _createBooking(Map<String, TimeOfDay>? perDateTimes) async {
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final basePrice = _currentPrice;
      final platformFee = _platformFee;

      final sessions = _selectedDates.map((date) {
        final dateStr = date.toIso8601String().split('T')[0];
        final time = perDateTimes?[dateStr] ?? _selectedTime!;
        return {
          'date': dateStr,
          'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00',
          'duration': _selectedDuration,
          'location_type': _selectedLocation,
          'location_address': null,
          'category': _selectedCategory,
        };
      }).toList();

      final bookings = await _bookingService.createBulkBooking(
        clientId: currentUser.id,
        trainerId: widget.trainer.id,
        sessions: sessions,
        basePricePerSession: basePrice,
        platformFeePerSession: platformFee,
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              bookingId: bookings.first['id'] as String,
              amount: (basePrice + platformFee) * sessions.length,
              trainerName: widget.trainer.fullName,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppException.cleanMessage(e)), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.93),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                if (_currentStep == 1)
                  GestureDetector(
                    onTap: _goToStep1,
                    child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 22),
                  ),
                if (_currentStep == 1) const SizedBox(width: 12),
                Text(
                  _currentStep == 0 ? 'Select Dates' : 'Session Details',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const Spacer(),
                // Credit pill (visible on Step 2)
                if (_currentStep == 1 && !_loadingCredits)
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _hasInsufficientCredits
                          ? AppTheme.errorColor.withValues(alpha: 0.15)
                          : AppTheme.successColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _hasInsufficientCredits
                            ? AppTheme.errorColor.withValues(alpha: 0.5)
                            : AppTheme.successColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.toll_rounded,
                          size: 14,
                          color: _hasInsufficientCredits ? AppTheme.errorColor : AppTheme.successColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_userCredits',
                          style: TextStyle(
                            color: _hasInsufficientCredits ? AppTheme.errorColor : AppTheme.successColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Step dots
                Row(
                  children: [
                    _buildStepDot(0),
                    const SizedBox(width: 6),
                    _buildStepDot(1),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'with ${widget.trainer.fullName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.primaryColor),
              ),
            ),
          ),
          // Content
          Expanded(
            child: _loadingAvailability
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : PageView(
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(), // Only navigate via buttons
                    children: [
                      _buildStep1(),
                      _buildStep2(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step) {
    final active = _currentStep == step;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppTheme.primaryColor : AppTheme.textSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ─── STEP 1: DATE SELECTION ─────────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Hint text
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Tap dates to select · Greyed-out = unavailable',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Calendar
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 90)),
                    focusedDay: _focusedDay,
                    rangeSelectionMode: RangeSelectionMode.disabled,
                    enabledDayPredicate: _isDateEnabled,
                    selectedDayPredicate: _isDaySelected,
                    onDaySelected: _onDaySelected,
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                      leftChevronIcon: const Icon(Icons.chevron_left, color: AppTheme.primaryColor),
                      rightChevronIcon: const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                    ),
                    calendarStyle: CalendarStyle(
                      selectedDecoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                      selectedTextStyle: const TextStyle(color: AppTheme.backgroundColor, fontWeight: FontWeight.bold),
                      todayDecoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.3), shape: BoxShape.circle),
                      todayTextStyle: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                      defaultTextStyle: const TextStyle(color: AppTheme.textPrimary),
                      weekendTextStyle: const TextStyle(color: AppTheme.textPrimary),
                      disabledTextStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.25)),
                      outsideTextStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.2)),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                      weekendStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Selected date chips
                if (_selectedDates.isNotEmpty)
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: _selectedDates.map((d) {
                      final label = '${d.day}/${d.month}';
                      return Chip(
                        label: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => setState(() => _selectedDates.removeWhere((x) => isSameDay(x, d))),
                        backgroundColor: AppTheme.surfaceColor,
                        side: const BorderSide(color: AppTheme.primaryColor, width: 1),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // Bottom sticky button
        _buildBottomButton(
          label: _selectedDates.isEmpty
              ? 'Select dates to continue'
              : 'Confirm ${_selectedDates.length} Date${_selectedDates.length > 1 ? 's' : ''}',
          enabled: _selectedDates.isNotEmpty,
          onTap: _goToStep2,
        ),
      ],
    );
  }

  // ─── STEP 2: TIME, DURATION, CATEGORY, LOCATION ────────────────────────────

  Widget _buildStep2() {
    final timeSlots = _generateTimeSlots();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Time Slot Grid ──────────────────────────────────
                _buildSectionLabel('Pick a Time', Icons.access_time_rounded),
                const SizedBox(height: 8),
                if (timeSlots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No available slots', style: TextStyle(color: AppTheme.textSecondary)),
                  )
                else
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: timeSlots.map((time) {
                      final blocked = _isSlotBlocked(time);
                      final selected = _selectedTime != null &&
                          _selectedTime!.hour == time.hour &&
                          _selectedTime!.minute == time.minute;
                      return GestureDetector(
                        onTap: blocked ? null : () => setState(() => _selectedTime = time),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: selected ? AppTheme.primaryGradient : null,
                            color: blocked
                                ? AppTheme.surfaceColor.withValues(alpha: 0.4)
                                : (selected ? null : AppTheme.surfaceColor),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: blocked
                                  ? AppTheme.textSecondary.withValues(alpha: 0.15)
                                  : (selected ? AppTheme.primaryColor : AppTheme.textSecondary.withValues(alpha: 0.2)),
                            ),
                          ),
                          child: Text(
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: blocked
                                  ? AppTheme.textSecondary.withValues(alpha: 0.3)
                                  : (selected ? AppTheme.backgroundColor : AppTheme.textPrimary),
                              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                              decoration: blocked ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 24),

                // ── Duration ────────────────────────────────────────
                _buildSectionLabel('Duration', Icons.timer_rounded),
                const SizedBox(height: 8),
                Row(
                  children: (_availability?.sessionDurations ?? [45, 60, 90]).map((dur) {
                    final selected = _selectedDuration == dur;
                    final price = _availability?.getPriceForDuration(dur, widget.trainer.pricePerSession)
                        ?? (widget.trainer.pricePerSession * (dur / 60)).round();
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedDuration = dur;
                            // Reset time if it now conflicts
                            if (_selectedTime != null && _isSlotBlocked(_selectedTime!)) {
                              _selectedTime = null;
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: selected ? AppTheme.primaryGradient : null,
                              color: selected ? null : AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? AppTheme.primaryColor : AppTheme.textSecondary.withValues(alpha: 0.2),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$dur min',
                                  style: TextStyle(
                                    color: selected ? AppTheme.backgroundColor : AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold, fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹$price',
                                  style: TextStyle(
                                    color: selected ? AppTheme.backgroundColor.withValues(alpha: 0.8) : AppTheme.textSecondary,
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ── Category (from trainer specialties) ─────────────
                _buildSectionLabel('Training Type', Icons.category_rounded),
                const SizedBox(height: 8),
                if ((_availability?.specialties ?? widget.trainer.specialties).isEmpty)
                  Text('No categories set', style: TextStyle(color: AppTheme.textSecondary))
                else
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: (_availability?.specialties ?? widget.trainer.specialties).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final specialty = (_availability?.specialties ?? widget.trainer.specialties)[i];
                        final selected = _selectedCategory == specialty;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = specialty),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: selected ? AppTheme.primaryGradient : null,
                              color: selected ? null : AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? AppTheme.primaryColor : AppTheme.textSecondary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  AppTheme.getFitnessIcon(specialty),
                                  size: 16,
                                  color: selected ? AppTheme.backgroundColor : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  specialty,
                                  style: TextStyle(
                                    color: selected ? AppTheme.backgroundColor : AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600, fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Location ────────────────────────────────────────
                _buildSectionLabel('Location', Icons.location_on_rounded),
                const SizedBox(height: 8),
                ..._locations.entries.map((entry) {
                  final selected = _selectedLocation == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedLocation = entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.primaryColor.withValues(alpha: 0.12) : AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppTheme.primaryColor : AppTheme.textSecondary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(_getLocationIcon(entry.key), color: selected ? AppTheme.primaryColor : AppTheme.textSecondary, size: 20),
                            const SizedBox(width: 12),
                            Text(entry.value, style: TextStyle(
                              color: selected ? AppTheme.primaryColor : AppTheme.textPrimary,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontSize: 14,
                            )),
                            const Spacer(),
                            if (selected) const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // ── Price Breakdown ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradient,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      _buildPriceRow('Session Fee (${_selectedDuration ?? 60}m)', _currentPrice),
                      const SizedBox(height: 8),
                      _buildPriceRow('Platform Fee', _platformFee),
                      if (_selectedDates.length > 1) ...[
                        const SizedBox(height: 8),
                        _buildPriceRow('Sessions', _selectedDates.length, isCount: true),
                      ],
                      if (_selectedCategory != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Type', style: Theme.of(context).textTheme.bodyMedium),
                            Text(_selectedCategory!, style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ],
                      Divider(height: 24, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                      _buildPriceRow('Total', _totalPrice, isTotal: true),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Requires $_creditsRequired Credit${_creditsRequired > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: _hasInsufficientCredits ? AppTheme.errorColor : AppTheme.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // Bottom confirm / buy credits button
        if (_hasInsufficientCredits)
          _buildBuyCreditsButton()
        else
          _buildBottomButton(
            label: _canConfirmBooking
                ? 'Confirm Booking — ₹$_totalPrice'
                : 'Select time, duration & type',
            enabled: _canConfirmBooking,
            onTap: _showPerDateTimePromptAndBook,
            isLoading: _isLoading,
          ),
      ],
    );
  }

  // ─── SHARED WIDGETS ─────────────────────────────────────────────────────────

  Widget _buildBuyCreditsButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(top: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.2))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'You need $_creditsRequired credit${_creditsRequired > 1 ? 's' : ''}, but only have $_userCredits',
            style: TextStyle(color: AppTheme.errorColor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BuyCreditsScreen()),
                ).then((_) => _loadUserCredits());
              },
              icon: const Icon(Icons.add_circle_rounded, size: 18),
              label: const Text('Buy Credits'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.backgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({required String label, required bool enabled, required VoidCallback onTap, bool isLoading = false}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(top: BorderSide(color: AppTheme.textSecondary.withValues(alpha: 0.1))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (enabled && !isLoading) ? onTap : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            disabledBackgroundColor: AppTheme.surfaceColor,
          ),
          child: isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(label, style: const TextStyle(fontSize: 15)),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPriceRow(String label, int amount, {bool isTotal = false, bool isCount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          fontSize: isTotal ? 16 : 14, color: AppTheme.textPrimary,
        )),
        Text(
          isCount ? 'x$amount' : '₹$amount',
          style: TextStyle(
            color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimary,
            fontWeight: FontWeight.bold, fontSize: isTotal ? 18 : 14,
          ),
        ),
      ],
    );
  }


  IconData _getLocationIcon(String location) {
    switch (location) {
      case 'trainer_space': return Icons.home_work_rounded;
      case 'client_location': return Icons.home_rounded;
      case 'park': return Icons.park_rounded;
      case 'gym': return Icons.fitness_center_rounded;
      default: return Icons.location_on_rounded;
    }
  }
}

// ─── PER-DATE TIME EDITOR DIALOG ──────────────────────────────────────────────

class _PerDateTimeDialog extends StatefulWidget {
  final List<DateTime> dates;
  final Map<String, TimeOfDay> initialTimes;
  final TrainerAvailability availability;
  final Map<String, List<BlockedSlot>> blockedSlotsCache;
  final int selectedDuration;

  const _PerDateTimeDialog({
    required this.dates,
    required this.initialTimes,
    required this.availability,
    required this.blockedSlotsCache,
    required this.selectedDuration,
  });

  @override
  State<_PerDateTimeDialog> createState() => _PerDateTimeDialogState();
}

class _PerDateTimeDialogState extends State<_PerDateTimeDialog> {
  late final Map<String, TimeOfDay> _times;

  @override
  void initState() {
    super.initState();
    _times = Map.from(widget.initialTimes);
  }

  Future<void> _pickTime(String dateKey) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[dateKey] ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryColor,
            surface: AppTheme.surfaceColor,
            onSurface: AppTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _times[dateKey] = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: const Text('Set time for each date'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: widget.dates.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final date = widget.dates[i];
            final key = date.toIso8601String().split('T')[0];
            final time = _times[key];
            return GestureDetector(
              onTap: () => _pickTime(key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        Text(
                          time != null ? time.format(context) : 'Set time',
                          style: TextStyle(
                            color: time != null ? AppTheme.primaryColor : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit_rounded, size: 16, color: AppTheme.primaryColor),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _times.values.every((t) => true) ? () => Navigator.pop(context, _times) : null,
          child: const Text('Confirm All'),
        ),
      ],
    );
  }
}
