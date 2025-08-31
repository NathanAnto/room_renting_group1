import 'package:flutter/material.dart';
import '../../../core/models/listing.dart';
import '../../../core/models/transport.dart'; // ItinerariesUI + parseItinerariesUI
import '../../../core/utils/transport_api.dart' as transportApi;

// NEW: imports pour récupérer l'user & son profil
import '../../../core/services/auth_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/models/user_model.dart'; // enum UserRole

/// Mapping par défaut nom d’école -> [lat, lng]
const Map<String, List<double>> kDefaultSchoolCoords = {
  "École de Design et Haute Ecole d'Art (EDHEA)": [46.291300, 7.520950],
  "Haute Ecole de Gestion (HEG)": [46.293050, 7.536450],
  "Haute Ecole d'Ingénierie (HEI)": [46.227420, 7.363820],
  "Haute Ecole de Santé (HES)": [46.235870, 7.351330],
  "Haute Ecole et Ecole Supérieure de Travail Social (HESTS)": [46.293050, 7.536450],
};

/// Widget autonome : affiche les itinéraires Listing -> école de l'utilisateur
/// (déduite du profil). N'affiche rien si l'utilisateur n'est pas étudiant.
class StudentListingItinerary extends StatefulWidget {
  final Listing listing;

  /// Optionnel: surcharger le mapping des écoles si besoin
  final Map<String, List<double>> schoolCoords;

  /// Limite d’itinéraires affichés dans la carte (UI)
  final int maxResults;

  /// Afficher le détail des legs (marche/transit)
  final bool showLegs;

  /// Padding externe
  final EdgeInsetsGeometry padding;

  /// Paramètres API (si besoin d’ajuster)
  final int pageLimitSafety;
  final int pageSize;

  const StudentListingItinerary({
    super.key,
    required this.listing,
    this.schoolCoords = kDefaultSchoolCoords,
    this.maxResults = 3,
    this.showLegs = true,
    this.padding = const EdgeInsets.all(12),
    this.pageLimitSafety = 20,
    this.pageSize = 6,
  });

  @override
  State<StudentListingItinerary> createState() => _StudentListingItineraryState();
}

class _StudentListingItineraryState extends State<StudentListingItinerary> {
  late Future<ItinerariesUI> _future;

  // Contexte résolu depuis le profil
  String? _resolvedSchoolName;
  bool _isStudent = false;
  bool _noUser = false;   // pas connecté
  bool _noSchool = false; // profil sans école

  @override
  void initState() {
    super.initState();
    _kickoff();
  }

  @override
  void didUpdateWidget(covariant StudentListingItinerary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listing.id != widget.listing.id) {
      _kickoff();
    }
  }

  void _kickoff() {
    _future = _load();
  }

  Future<ItinerariesUI> _load() async {
    // Reset flags à chaque chargement
    _resolvedSchoolName = null;
    _isStudent = false;
    _noUser = false;
    _noSchool = false;

    // 1) Récupérer l'utilisateur courant
    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      _noUser = true;
      return _emptyUI();
    }

    // 2) Charger le profil (role + school)
    final profile = await ProfileService().getUserProfile(uid);
    _isStudent = profile?.role == UserRole.student;
    if (!_isStudent) {
      // Non-étudiant → pas d'affichage
      return _emptyUI();
    }

    _resolvedSchoolName = profile?.school?.trim();
    if (_resolvedSchoolName == null || _resolvedSchoolName!.isEmpty) {
      _noSchool = true;
      return _emptyUI();
    }

    // 3) Coords école
    final coords = widget.schoolCoords[_resolvedSchoolName!];
    if (coords == null || coords.length != 2) {
      throw Exception("Coordonnées inconnues pour l'école: $_resolvedSchoolName");
    }

    // 4) Appel API transport
    final raw = await transportApi.getItinerariesNext2hByCoords(
      fromLat: widget.listing.lat,
      fromLon: widget.listing.lng,
      toLat: coords[0],
      toLon: coords[1],
      pageLimitSafety: widget.pageLimitSafety,
      pageSize: widget.pageSize,
    );

    final parsed = parseItinerariesUI(raw);
    final limited = parsed.itineraries.take(widget.maxResults).toList();

    return ItinerariesUI(
      fromLabel: parsed.fromLabel,
      toLabel: parsed.toLabel,
      windowStart: parsed.windowStart,
      windowEnd: parsed.windowEnd,
      itineraries: limited,
    );
  }

  ItinerariesUI _emptyUI() => ItinerariesUI(
        fromLabel: '',
        toLabel: '',
        windowStart: DateTime.now(),
        windowEnd: DateTime.now(),
        itineraries: const [],
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: FutureBuilder<ItinerariesUI>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _SkeletonCard(schoolName: _resolvedSchoolName);
          }
          if (snap.hasError) {
            return _ErrorCard(
              schoolName: _resolvedSchoolName,
              error: snap.error,
              onRetry: () => setState(_kickoff),
            );
          }

          // Garde-fous post-chargement
          if (!_isStudent) {
            // Même logique qu'avant: si pas étudiant → n'affiche rien
            return const SizedBox.shrink();
          }
          if (_noUser) {
            return const _HintCard(
              title: "Connectez-vous pour voir les trajets",
              subtitle: "Identifiez-vous pour récupérer votre école et les itinéraires.",
            );
          }
          if (_noSchool || _resolvedSchoolName == null || _resolvedSchoolName!.isEmpty) {
            return const _HintCard(
              title: "Ajoutez votre école",
              subtitle: "Renseignez votre campus dans le profil pour voir les trajets.",
            );
          }

          final data = snap.data!;
          if (data.itineraries.isEmpty) {
            return const _HintCard(
              title: "Aucune connexion trouvée",
              subtitle: "Essayez un autre créneau ou vérifiez la sélection d’école.",
            );
          }

          return _ItinerariesCard(
            schoolName: _resolvedSchoolName!,
            ui: data,
            showLegs: widget.showLegs,
          );
        },
      ),
    );
  }
}

/* =========================
 *   Cartes & sous-widgets
 * ========================= */

class _ItinerariesCard extends StatelessWidget {
  final String schoolName;
  final ItinerariesUI ui;
  final bool showLegs;

  const _ItinerariesCard({
    required this.schoolName,
    required this.ui,
    required this.showLegs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                const Icon(Icons.directions_transit, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Trajets vers $schoolName",
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Liste des itinéraires (non-scrollable ici)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ui.itineraries.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, i) {
                final it = ui.itineraries[i];
                return _ItineraryTile(it: it, showLegs: showLegs);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ItineraryTile extends StatelessWidget {
  final ItineraryUI it;
  final bool showLegs;

  const _ItineraryTile({required this.it, required this.showLegs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne principale: heures + durée + correspondances
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_hm(it.departure)} → ${_hm(it.arrival)}',
                style: theme.textTheme.titleSmall),
            Text('${it.durationMinutes} min',
                style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          [
            if (it.primaryLine != null) it.primaryLine,
            '${it.transfers} correspondance${it.transfers > 1 ? 's' : ''}',
          ].whereType<String>().join(' • '),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 6),

        // Produits
        Wrap(
          spacing: 6,
          runSpacing: -8,
          children: it.products
              .map((p) => Chip(
                    label: Text(p),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ))
              .toList(),
        ),

        if (showLegs) ...[
          const SizedBox(height: 8),
          Column(
            children: it.legs.map((l) {
              final isWalk = l.isWalk;
              final icon = isWalk ? Icons.directions_walk : Icons.train;
              final subtitle = isWalk
                  ? (l.walkDuration == null
                      ? "Marche"
                      : "Marche (${l.walkDuration!.inMinutes} min)")
                  : [
                      if ((l.lineLabel ?? '').isNotEmpty) l.lineLabel,
                      if ((l.direction ?? '').isNotEmpty) '→ ${l.direction}',
                      if ((l.toPlatform ?? '').isNotEmpty) '(Quai ${l.toPlatform})',
                    ].whereType<String>().join(' ');
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(icon),
                title: Text('${l.fromName} → ${l.toName}',
                    style: theme.textTheme.bodyMedium),
                subtitle: Text(
                  [
                    if (l.fromTime != null && l.toTime != null)
                      '${_hm(l.fromTime!)}→${_hm(l.toTime!)}',
                    subtitle,
                  ].where((e) => e != null && e.toString().trim().isNotEmpty)
                   .map((e) => e.toString())
                   .join(' • '),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final String? schoolName;
  const _SkeletonCard({this.schoolName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.directions_transit, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Trajets vers ${schoolName ?? '…'}",
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            _skeletonLine(),
            const SizedBox(height: 8),
            _skeletonLine(widthFactor: 0.6),
            const SizedBox(height: 12),
            _skeletonChipRow(),
          ],
        ),
      ),
    );
  }

  Widget _skeletonLine({double widthFactor = 1}) => FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: 12,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );

  Widget _skeletonChipRow() => Wrap(
        spacing: 6,
        children: List.generate(
          3,
          (_) => Container(
            height: 28,
            width: 54,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  final String? schoolName;
  final Object? error;
  final VoidCallback onRetry;

  const _ErrorCard({this.schoolName, this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.error_outline),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Impossible de charger les trajets ${schoolName == null ? '' : 'vers $schoolName'}",
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                tooltip: "Réessayer",
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Erreur inconnue',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _HintCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.black.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================
 * Helpers format
 * ========================= */

String _two(int v) => v.toString().padLeft(2, '0');
String _hm(DateTime dt) => '${_two(dt.hour)}:${_two(dt.minute)}';
