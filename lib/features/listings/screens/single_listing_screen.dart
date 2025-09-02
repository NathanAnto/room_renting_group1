// lib/features/listings/screens/single_listing_screen.dart

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/models/listing.dart';
import '../../../core/models/ListingAvailability.dart';
// Garde ce widget si tu l'utilises ailleurs ; sinon commente l'import.
// import '../widgets/transport_widget.dart';

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

            // // --- Transport / Autres widgets éventuels ---
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //   child: TransportWidget(listing: listing),
            // ),
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
      if (listing.amenities['is_furnished'] == true) const _Chip(text: 'Meublé'),
      if (listing.amenities['wifi_incl'] == true) const _Chip(text: 'WiFi inclus'),
      if (listing.amenities['charges_incl'] == true) const _Chip(text: 'Charges incluses'),
      if (listing.amenities['car_park'] == true) const _Chip(text: 'Parking'),
    ];

    return _Section(
      title: 'Informations',
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
                label: 'Loyer',
                value: '${listing.rentPerMonth.toStringAsFixed(0)} CHF/mois',
              ),
              const SizedBox(width: 16),
              _InfoStat(
                icon: Icons.auto_graph_rounded,
                label: 'Predit',
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
                label: 'Pièces',
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
        title: 'Disponibilités',
        child: Text(
          'Aucune disponibilité renseignée.',
          style: TextStyle(color: theme.colorScheme.mutedForeground),
        ),
      );
    }

    return _Section(
      title: 'Disponibilités',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WindowsSummary(windows: availability.windows),
          const SizedBox(height: 8),
          _Legend(),
          const SizedBox(height: 12),
          _AvailabilityCalendar(availability: availability),
          if (availability.blackoutDates.isNotEmpty) ...[
            const SizedBox(height: 12),
            _BlackoutList(blackouts: availability.blackoutDates),
          ],
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
            "$start → $end (fin excl.)$label",
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
        const Text('Disponible'),
        const SizedBox(width: 16),
        dot(Colors.orange.shade400, child: const Icon(Icons.close, size: 12, color: Colors.white)),
        const SizedBox(width: 6),
        const Text('Blackout'),
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
        const Text('Indisponible'),
      ],
    );
  }
}

class _BlackoutList extends StatelessWidget {
  const _BlackoutList({required this.blackouts});
  final List<String> blackouts;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jours “blackout”',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.foreground,
            )),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: blackouts.map((d) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.muted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(d, style: TextStyle(color: theme.colorScheme.mutedForeground, fontSize: 12)),
            );
          }).toList(),
        ),
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
  late final List<DateTime> _months; // 1er du mois (UTC)
  late int _index; // mois courant affiché
  final _monthNamesFr = const [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
  ];

  @override
  void initState() {
    super.initState();
    _months = _buildCoveredMonths(widget.availability.windows);
    _index = _initialMonthIndex(_months, widget.availability);
  }

  @override
  void didUpdateWidget(covariant _AvailabilityCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availability != widget.availability) {
      final months = _buildCoveredMonths(widget.availability.windows);
      final idx = _initialMonthIndex(months, widget.availability);
      setState(() {
        _months
          ..clear()
          ..addAll(months);
        _index = idx;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    if (_months.isEmpty) {
      return Text('Aucune période à afficher.',
          style: TextStyle(color: theme.colorScheme.mutedForeground));
    }

    final month = _months[_index];
    final title = '${_monthNamesFr[month.month - 1]} ${month.year}';

    return Column(
      children: [
        // Header avec navigation mois précédent/suivant
        Row(
          children: [
            IconButton(
              onPressed: _index > 0 ? () => setState(() => _index--) : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Mois précédent',
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
            IconButton(
              onPressed: _index < _months.length - 1
                  ? () => setState(() => _index++)
                  : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Mois suivant',
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Grille calendrier pour le mois courant
        _MonthGrid(
          month: month,
          availability: widget.availability,
        ),
      ],
    );
  }

  // --- helpers ---

  static List<DateTime> _buildCoveredMonths(List<AvailabilityWindow> windows) {
    if (windows.isEmpty) return [];

    // tri par start
    final sorted = [...windows]..sort((a, b) => a.start.compareTo(b.start));
    final first = sorted.first.start;
    // end est exclusif → on affiche jusqu'au mois précédent end (si end = 2025-10-01, on s'arrête à septembre)
    final lastEnd = sorted.map((w) => w.end).reduce((a, b) => a.isAfter(b) ? a : b);

    final months = <DateTime>[];
    var cursor = DateTime.utc(first.year, first.month, 1);
    final limitExcl = DateTime.utc(lastEnd.year, lastEnd.month, 1);

    // si aucune fenêtre ne couvre "today", on s'assure d'au moins inclure le mois de 'nextAvailableStart' si présent
    while (cursor.isBefore(limitExcl)) {
      months.add(cursor);
      cursor = (cursor.month == 12)
          ? DateTime.utc(cursor.year + 1, 1, 1)
          : DateTime.utc(cursor.year, cursor.month + 1, 1);
    }

    return months;
  }

  static int _initialMonthIndex(List<DateTime> months, ListingAvailability a) {
    if (months.isEmpty) return 0;
    final today = DateTime.now().toUtc();
    final todayYm = DateTime.utc(today.year, today.month, 1);

    final idxToday = months.indexWhere((m) => m.year == todayYm.year && m.month == todayYm.month);
    if (idxToday != -1) return idxToday;

    final next = a.nextAvailableStart;
    if (next != null) {
      final ym = DateTime.utc(next.year, next.month, 1);
      final idxNext = months.indexWhere((m) => m.year == ym.year && m.month == ym.month);
      if (idxNext != -1) return idxNext;
    }
    return 0;
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
    final weekdayLabels = const ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

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
                final isBlackout = availability.blackoutDates.contains(key);
                final isAvailable = inWindow && !isBlackout;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _DayCell(
                      day: dayNum,
                      available: isAvailable,
                      blackout: isBlackout,
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
    required this.blackout,
    required this.muted,
  });

  final int day;
  final bool available;
  final bool blackout;
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
    if (blackout) {
      fill = Colors.orange.shade400;
      text = Colors.white;
      innerIcon = const Icon(Icons.close, size: 12, color: Colors.white);
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
            // pastille de fond (si dispo/blackout)
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
