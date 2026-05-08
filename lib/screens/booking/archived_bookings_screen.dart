import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../models/booking_model.dart';
import '../../config/theme.dart';
import '../../utils/booking_status_utils.dart';
import 'booking_detail_screen.dart';

class ArchivedBookingsScreen extends StatefulWidget {
  const ArchivedBookingsScreen({super.key});

  @override
  State<ArchivedBookingsScreen> createState() => _ArchivedBookingsScreenState();
}

class _ArchivedBookingsScreenState extends State<ArchivedBookingsScreen> {
  late final BookingService _bookingService;
  List<BookingModel> _archivedBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _bookingService = context.read<BookingService>();
    _loadArchived();
  }

  Future<void> _loadArchived() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    try {
      final archived = await _bookingService.getArchivedBookings(userId);
      if (mounted) {
        setState(() {
          _archivedBookings = archived.map((json) => BookingModel.fromJson(json)).toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Archived Bookings'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _archivedBookings.isEmpty
              ? const Center(
                  child: Text('No archived bookings yet.',
                      style: TextStyle(color: AppTheme.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingLG),
                  itemCount: _archivedBookings.length,
                  itemBuilder: (context, index) {
                    final booking = _archivedBookings[index];
                    return _buildBookingCard(booking);
                  },
                ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailScreen(bookingId: booking.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.archive_rounded, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.trainerName ?? 'Unknown Trainer',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${booking.sessionDate} • ${booking.sessionTime}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
