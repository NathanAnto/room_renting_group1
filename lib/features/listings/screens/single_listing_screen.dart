// lib/features/listings/screens/single_listing_screen.dart

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/models/listing.dart';
import '../../../core/models/ListingAvailability.dart';
import '../widgets/transport_widget.dart';
import '../widgets/places_widget.dart';
import '../widgets/booking_planner_button.dart';

class SingleListingScreen extends StatelessWidget {
  final Listing listing;

  const SingleListingScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(listing.title),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Images (plein écran) ---
            if (listing.images.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                  height: 250.0,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  viewportFraction: 0.95,
                ),
                items: listing.images.map((url) {
                  return Builder(
                    builder: (BuildContext context) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width,
                          placeholder: (ctx, _) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (ctx, _, __) => const Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),

            // --- Infos principales ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _InfoCard(listing: listing),
            ),
            BookingPlannerButton(listing: listing),

            const SizedBox(height: 16),

            // --- Disponibilités (Calendrier) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AvailabilitySection(availability: listing.availability),
            ),

            const SizedBox(height: 16),

            // --- Description ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _Section(
                title: 'Description',
                child: Text(
                  listing.description,
                  style: TextStyle(color: theme.colorScheme.foreground),
                ),
              ),
            ),
            const SizedBox(height: 16),
            StudentListingItinerary(listing: listing),
            const SizedBox(height: 12),
            NearbyPlacesList(lat: listing.lat, lon: listing.lng, limit: 10),
          ],
        ),
      ),
    );
  }
}

// =============== Sections / Cards =================

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    final chips = <Widget>[
      _Chip(text: listing.status),
      if (listing.amenities['is_furnished'] == true) const _Chip(text: 'Furnished'),
      if (listing.amenities['wifi_incl'] == true) const _Chip(text: 'WiFi included'),
      if (listing.amenities['charges_incl'] == true) const _Chip(text: 'Charges included'),
      if (listing.amenities['car_park'] == true) const _Chip(text: 'Parking'),
    ];

    return _Section(
      title: 'Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${listing.city} • ${listing.addressLine}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.foreground,
              )),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 6, children: chips),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoStat(
                icon: Icons.euro_symbol_rounded,
                label: 'Rent',
                value: '${listing.rentPerMonth.toStringAsFixed(0)} CHF/month',
              ),
              const SizedBox(width: 16),
              _InfoStat(
                icon: Icons.auto_graph_rounded,
                label: 'Predicted',
                value: '${listing.predictedRentPerMonth.toStringAsFixed(0)} CHF',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoStat(
                icon: Icons.square_foot_rounded,
                label: 'Surface',
                value: listing.surface > 0 ? '${listing.surface} m²' : '—',
              ),
              const SizedBox(width: 16),
              _InfoStat(
                icon: Icons.meeting_room_outlined,
                label: 'Rooms',
                value: listing.numRooms > 0 ? '${listing.numRooms}' : '—',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: theme.colorScheme.mutedForeground, fontSize: 12),
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  const _InfoStat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.mutedForeground),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(color: theme.colorScheme.mutedForeground),
        ),
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: theme.colorScheme.foreground,
                )),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

// =============== Disponibilités / Calendrier =================

class _AvailabilitySection extends StatelessWidget {
  const _AvailabilitySection({required this.availability});
  final ListingAvailability availability;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    if (availability.windows.isEmpty) {
      return _Section(
        title: 'Availabilites',
        child: Text(
          'No availabilities',
          style: TextStyle(color: theme.colorScheme.mutedForeground),
        ),
      );
    }

    return _Section(
      title: 'Availabilites',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WindowsSummary(windows: availability.windows),
          const SizedBox(height: 8),
          _Legend(),
          const SizedBox(height: 12),
          _AvailabilityCalendar(availability: availability)
        ],
      ),
    );
  }
}

class _WindowsSummary extends StatelessWidget {
  const _WindowsSummary({required this.windows});
  final List<AvailabilityWindow> windows;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: windows.map((w) {
        String fmt(DateTime d) =>
            "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        final start = fmt(w.start);
        final end = fmt(w.end);
        final label = w.label == null || w.label!.trim().isEmpty ? '' : ' • ${w.label}';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: theme.colorScheme.muted,
          ),
          child: Text(
            "$start → $end (end excl.)$label",
            style: TextStyle(color: theme.colorScheme.mutedForeground, fontSize: 12),
          ),
        );
      }).toList(),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    Widget dot(Color c, {Widget? child}) => Container(
          width: 16,
          height: 16,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          child: child,
        );
    return Row(
      children: [
        dot(Colors.green.shade400),
        const SizedBox(width: 6),
        const Text('Available'),
        const SizedBox(width: 16),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.mutedForeground),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        const Text('Unavailable (outside windows)'),
      ],
    );
  }
}

class _AvailabilityCalendar extends StatefulWidget {
  const _AvailabilityCalendar({required this.availability});
  final ListingAvailability availability;

  @override
  State<_AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<_AvailabilityCalendar> {
  late DateTime _currentMonth;

  final _monthNames = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

    @override
  void initState() {
    super.initState();
    _currentMonth = _getInitialMonth(widget.availability);
  }

  @override
  void didUpdateWidget(covariant _AvailabilityCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availability != widget.availability) {
      // If listing data changes, reset the calendar to the best initial month
      setState(() {
        _currentMonth = _getInitialMonth(widget.availability);
      });
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = (_currentMonth.month == 1)
          ? DateTime.utc(_currentMonth.year - 1, 12, 1)
          : DateTime.utc(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonth = (_currentMonth.month == 12)
          ? DateTime.utc(_currentMonth.year + 1, 1, 1)
          : DateTime.utc(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }
  @override
  Widget build(BuildContext context) {
    final title = '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}';

    return Column(
      children: [
        // Header with navigation month précédent/suivant
        Row(
          children: [
            // Button is always enabled for infinite traversal
            IconButton(
              onPressed: _goToPreviousMonth,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous month',
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
            // Button is always enabled for infinite traversal
            IconButton(
              onPressed: _goToNextMonth,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next month',
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Grille calendrier pour le mois courant
        _MonthGrid(
          month: _currentMonth,
          availability: widget.availability,
        ),
      ],
    );
  }
    // Determines the best starting month to display.
  static DateTime _getInitialMonth(ListingAvailability availability) {
    final now = DateTime.now().toUtc();
    final thisMonth = DateTime.utc(now.year, now.month, 1);

    // If there are no windows, just default to the current month.
    if (availability.windows.isEmpty) {
      return thisMonth;
    }

    // Find the earliest date across all windows.
    final firstAvailableDay = availability.windows
        .map((w) => w.start)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final firstAvailableMonth =
        DateTime.utc(firstAvailableDay.year, firstAvailableDay.month, 1);

    // If the current month is after the first availability, show the current month.
    // Otherwise, start the calendar at the first available month.
    return thisMonth.isAfter(firstAvailableMonth) ? thisMonth : firstAvailableMonth;
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.availability,
  });

  final DateTime month; // 1er du mois (UTC)
  final ListingAvailability availability;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    // Labels des jours (Lun → Dim)
    final weekdayLabels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final firstDay = DateTime.utc(month.year, month.month, 1);
    final daysInMonth = DateTime.utc(month.year, month.month + 1, 0).day;
    // Offset pour commencer un lundi (DateTime.weekday: Lundi=1..Dimanche=7)
    final startOffset = (firstDay.weekday + 6) % 7;

    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        Row(
          children: List.generate(7, (i) {
            return Expanded(
              child: Center(
                child: Text(
                  weekdayLabels[i],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Column(
          children: List.generate(rows, (row) {
            return Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNum = cellIndex - startOffset + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 40));
                }

                final dateUtc = DateTime.utc(month.year, month.month, dayNum);
                final key = _ymd(dateUtc);

                final inWindow = availability.windows.any((w) => w.containsDateUtc(dateUtc));
                final isAvailable = inWindow;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _DayCell(
                      day: dayNum,
                      available: isAvailable,
                      muted: !inWindow,
                    ),
                  ),
                );
              }),
            );
          }),
        ),
      ],
    );
  }

  static String _ymd(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.available,
    required this.muted,
  });

  final int day;
  final bool available;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    Color border = theme.colorScheme.mutedForeground;
    Color text = theme.colorScheme.foreground;
    Color fill = Colors.transparent;
    Widget? innerIcon;

    if (muted) {
      text = theme.colorScheme.mutedForeground;
      border = theme.colorScheme.mutedForeground.withOpacity(0.5);
    }
    if (available) {
      fill = Colors.green.shade400;
      text = Colors.white;
    }

    return AspectRatio(
      aspectRatio: 1, // carré
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          border: Border.all(color: border.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(10),
          color: Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // pastille de fond (si dispo)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
              ),
            ),
            // numéro du jour
            Text(
              '$day',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: text,
              ),
            ),
            if (innerIcon != null)
              Positioned(
                right: 2,
                bottom: 2,
                child: innerIcon,
              ),
          ],
        ),
      ),
    );
  }
}
