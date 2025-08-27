import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/apartment_service.dart';
import '../models/apartment.dart';
import 'edit_apartment_page.dart';

class ApartmentsPage extends StatelessWidget {
  const ApartmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ApartmentService();

    return Scaffold(
      appBar: AppBar(title: const Text('Apartments')),
      body: StreamBuilder<List<Apartment>>(
        stream: service.streamAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Aucun appartement'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final a = items[i];
              return ListTile(
                title: Text('${a.title} • ${a.city}'),
                subtitle: Text('CHF ${a.price} / mois'),
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => EditApartmentPage(apartment: a),
                  ));
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Supprimer ?'),
                        content: Text('Supprimer "${a.title}" ?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await service.delete(a.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supprimé')));
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const EditApartmentPage(),
          ));
        },
        label: const Text('Ajouter'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
