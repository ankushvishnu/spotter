import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../services/trainer_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/trainer_slot_model.dart';
import '../../config/theme.dart';

class TrainerCalendarScreen extends StatefulWidget {
  const TrainerCalendarScreen({super.key});

  @override
  State<TrainerCalendarScreen> createState() => _TrainerCalendarScreenState();
}

class _TrainerCalendarScreenState extends State<TrainerCalendarScreen> {
  late final TrainerService _trainerService;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<TrainerSlotModel> _slots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _trainerService = context.read<TrainerService>();
    _selectedDay = _focusedDay;
    _loadSlots(_focusedDay);
  }

  String? _trainerId;

  Future<void> _loadSlots(DateTime date) async {
    if (_trainerId == null) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId == null) return;
      final profile = await _trainerService.getTrainerByUserId(userId);
      if (profile != null) {
        _trainerId = (profile['trainer_id'] ?? profile['id']) as String?;
      }
    }

    if (_trainerId == null) return;
    final trainerId = _trainerId!;

    setState(() => _isLoading = true);
    try {
      final slotData = await _trainerService.getTrainerSlots(trainerId, date);
      if (mounted) {
        setState(() {
          _slots = slotData.map((s) => TrainerSlotModel.fromJson(s)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading slots: $e')),
        );
      }
    }
  }

  Future<void> _addSlot(bool isPreferred) async {
    if (_trainerId == null || _selectedDay == null) return;
    final trainerId = _trainerId!;

    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: isPreferred ? 'Select Preferred Start Time' : 'Select Block Start Time',
    );

    if (startTime == null) return;

    if (!mounted) return;
    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute),
      helpText: 'Select End Time',
    );

    if (endTime == null) return;

    setState(() => _isLoading = true);
    try {
      await _trainerService.addTrainerSlot(
        trainerId: trainerId,
        date: _selectedDay!,
        startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
        endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
        isPreferred: isPreferred,
      );
      _loadSlots(_selectedDay!);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding slot: $e')),
        );
      }
    }
  }

  Future<void> _deleteSlot(String slotId) async {
    setState(() => _isLoading = true);
    try {
      await _trainerService.deleteTrainerSlot(slotId);
      _loadSlots(_selectedDay!);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting slot: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Calendar Help'),
                  content: const Text(
                    'Set "Preferred" slots to highlight your best availability to clients. '
                    'Use "Block" slots to explicitly hide times where you are unavailable ad-hoc.'
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 30)),
            lastDay: DateTime.now().add(const Duration(days: 180)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadSlots(selectedDay);
            },
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.2), shape: BoxShape.circle),
              selectedDecoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Scheduled Slots', style: Theme.of(context).textTheme.headlineSmall),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.accentColor),
                      onPressed: () => _addSlot(true), // Preferred
                      tooltip: 'Add Preferred Slot',
                    ),
                    IconButton(
                      icon: const Icon(Icons.block_flipped, color: AppTheme.errorColor),
                      onPressed: () => _addSlot(false), // Blocked
                      tooltip: 'Block Time Slot',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _slots.isEmpty
                ? const Center(child: Text('No custom slots set for this day'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _slots.length,
                    itemBuilder: (context, index) {
                      final slot = _slots[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: slot.isPreferred ? AppTheme.accentColor.withValues(alpha: 0.3) : AppTheme.errorColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              slot.isPreferred ? Icons.star_rounded : Icons.block_rounded,
                              color: slot.isPreferred ? AppTheme.accentColor : AppTheme.errorColor,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slot.isPreferred ? 'Preferred Availability' : 'Blocked Time',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(slot.timeRange),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary),
                              onPressed: () => _deleteSlot(slot.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

