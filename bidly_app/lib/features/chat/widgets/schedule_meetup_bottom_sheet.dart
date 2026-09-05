import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_theme.dart';

class ScheduleMeetupBottomSheet extends ConsumerStatefulWidget {
  final String orderId;
  final String? initialLocation;
  final VoidCallback? onMeetupScheduled;

  const ScheduleMeetupBottomSheet({
    super.key,
    required this.orderId,
    this.initialLocation,
    this.onMeetupScheduled,
  });

  static Future<void> show(
    BuildContext context, {
    required String orderId,
    String? initialLocation,
    VoidCallback? onMeetupScheduled,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScheduleMeetupBottomSheet(
        orderId: orderId,
        initialLocation: initialLocation,
        onMeetupScheduled: onMeetupScheduled,
      ),
    );
  }

  @override
  ConsumerState<ScheduleMeetupBottomSheet> createState() => _ScheduleMeetupBottomSheetState();
}

class _ScheduleMeetupBottomSheetState extends ConsumerState<ScheduleMeetupBottomSheet> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;
  late final TextEditingController _timeController;
  late final TextEditingController _locationController;
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDate = now.add(const Duration(days: 1));
    final nextHour = now.add(const Duration(hours: 1));
    _timeController = TextEditingController(text: DateFormat('hh:00 a').format(nextHour));
    _locationController = TextEditingController(
      text: widget.initialLocation ?? '',
    );
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable device location / GPS')),
          );
        }
        setState(() => _isFetchingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          setState(() => _isFetchingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions permanently denied. Enable in device settings.')),
          );
        }
        setState(() => _isFetchingLocation = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          if (p.name != null && p.name!.isNotEmpty && p.name != p.street) p.name,
          if (p.street != null && p.street!.isNotEmpty) p.street,
          if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        if (mounted) {
          setState(() {
            _locationController.text = parts.isNotEmpty ? parts : 'Near ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
            _isFetchingLocation = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _locationController.text = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
            _isFetchingLocation = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  void _openGoogleMapPicker() {
    LatLng pickedPosition = const LatLng(13.0827, 80.2707); // Default Chennai
    String pickedAddress = _locationController.text.isNotEmpty ? _locationController.text : 'Selected Location';
    bool isReverseGeocoding = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: MediaQuery.of(sheetCtx).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pick Meetup on Google Maps',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Pan or tap map to set meeting point',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: pickedPosition,
                          zoom: 15,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        onCameraMove: (camPos) {
                          pickedPosition = camPos.target;
                        },
                        onCameraIdle: () async {
                          setModalState(() => isReverseGeocoding = true);
                          try {
                            final placemarks = await placemarkFromCoordinates(
                              pickedPosition.latitude,
                              pickedPosition.longitude,
                            );
                            if (placemarks.isNotEmpty) {
                              final p = placemarks.first;
                              final parts = [
                                if (p.name != null && p.name!.isNotEmpty && p.name != p.street) p.name,
                                if (p.street != null && p.street!.isNotEmpty) p.street,
                                if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
                                if (p.locality != null && p.locality!.isNotEmpty) p.locality,
                              ].where((e) => e != null && e.isNotEmpty).join(', ');
                              pickedAddress = parts.isNotEmpty ? parts : 'Selected Location';
                            }
                          } catch (_) {}
                          setModalState(() => isReverseGeocoding = false);
                        },
                      ),
                      const IgnorePointer(
                        child: Icon(Icons.location_pin, color: Color(0xFFE11D48), size: 44),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Color(0xFF004E54), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: isReverseGeocoding
                                ? const Text('Resolving address...', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF94A3B8)))
                                : Text(
                                    pickedAddress,
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _locationController.text = pickedAddress;
                            });
                            Navigator.pop(sheetCtx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004E54),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Confirm Location', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _timeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _confirmMeetup() async {
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a meetup location')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      await apiClient.post(
        '/orders/${widget.orderId}/schedule-meetup',
        data: {
          'location': _locationController.text.trim(),
          'dateString': dateStr,
          'timeString': _timeController.text.trim(),
          'notes': 'Meetup confirmed at ${_locationController.text.trim()}',
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meetup scheduled successfully!'),
            backgroundColor: Color(0xFF004E54),
          ),
        );
        widget.onMeetupScheduled?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule meetup: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildCalendarHeader() {
    final monthName = DateFormat('MMMM yyyy').format(_currentMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.textPrimary),
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
            });
          },
        ),
        Text(
          monthName,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.textPrimary),
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
            });
          },
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    const daysOfWeek = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    return Column(
      children: [
        // Days of week header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: daysOfWeek.map((d) {
            return SizedBox(
              width: 36,
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Days grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: startingWeekday + daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (ctx, idx) {
            if (idx < startingWeekday) {
              return const SizedBox();
            }
            final day = idx - startingWeekday + 1;
            final isSelected = _selectedDate.year == _currentMonth.year &&
                _selectedDate.month == _currentMonth.month &&
                _selectedDate.day == day;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, day);
                });
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF004E54) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule Meetup',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Pick a date and time to collect your item',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Select Date Label
            const Text(
              'SELECT DATE',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Calendar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
              ),
              child: Column(
                children: [
                  _buildCalendarHeader(),
                  _buildCalendarGrid(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Select Time
            const Text(
              'SELECT TIME',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(
                hintText: 'e.g. 10:00 AM or 14:30',
                prefixIcon: const Icon(Icons.access_time_rounded, size: 20, color: Color(0xFF004E54)),
                filled: true,
                fillColor: const Color(0xFFF9FBFA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF004E54), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'LOCATION',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                GestureDetector(
                  onTap: _fetchCurrentLocation,
                  child: Row(
                    children: [
                      const Icon(Icons.my_location_rounded, size: 14, color: Color(0xFF004E54)),
                      const SizedBox(width: 4),
                      Text(
                        _isFetchingLocation ? 'Locating...' : 'GPS Auto-Detect',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF004E54),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Enter agreed meetup location (e.g. Mall, Metro Station)',
                prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF004E54)),
                suffixIcon: _isFetchingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF004E54)),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.map_outlined, color: Color(0xFF004E54), size: 20),
                        tooltip: 'Pick on Google Maps',
                        onPressed: _openGoogleMapPicker,
                      ),
                filled: true,
                fillColor: const Color(0xFFF9FBFA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF004E54), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _fetchCurrentLocation,
                    icon: const Icon(Icons.my_location_rounded, size: 14, color: Color(0xFF004E54)),
                    label: const Text(
                      'Use My Location',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF004E54)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: Color(0xFF004E54), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openGoogleMapPicker,
                    icon: const Icon(Icons.pin_drop_rounded, size: 14, color: Color(0xFF004E54)),
                    label: const Text(
                      'Pick on Map',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF004E54)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: Color(0xFF004E54), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Confirm Meetup Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmMeetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004E54),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Confirm Meetup',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
