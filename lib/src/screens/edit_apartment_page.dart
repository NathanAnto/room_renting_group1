import 'package:flutter/material.dart';
import '../data/apartment_service.dart';
import '../models/apartment.dart';

class EditApartmentPage extends StatefulWidget {
  final Apartment? apartment;
  const EditApartmentPage({super.key, this.apartment});

  @override
  State<EditApartmentPage> createState() => _EditApartmentPageState();
}

class _EditApartmentPageState extends State<EditApartmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _city = TextEditingController();
  final _price = TextEditingController();
  final _desc = TextEditingController();

  @override
  void initState() {
    super.initState();
    final a = widget.apartment;
    if (a != null) {
      _title.text = a.title;
      _city.text = a.city;
      _price.text = a.price.toString();
      _desc.text = a.description ?? '';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _city.dispose();
    _price.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.apartment != null;
    final svc = ApartmentService();

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Modifier' : 'Ajouter')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              TextFormField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'Ville'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              TextFormField(
                controller: _price,
                decoration: const InputDecoration(labelText: 'Prix (CHF/mois)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final x = int.tryParse(v ?? '');
                  if (x == null || x < 0) return 'Prix invalide';
                  return null;
                },
              ),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final price = int.parse(_price.text.trim());
                  if (isEdit) {
                    final updated = widget.apartment!.copyWith(
                      title: _title.text.trim(),
                      city: _city.text.trim(),
                      price: price,
                      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
                    );
                    await svc.update(updated);
                  } else {
                    await svc.add(Apartment(
                      id: 'tmp', // ignoré par add()
                      title: _title.text.trim(),
                      city: _city.text.trim(),
                      price: price,
                      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
                      ownerId: null, // à remplir avec l'uid plus tard
                    ));
                  }
                  if (mounted) Navigator.pop(context);
                },
                child: Text(isEdit ? 'Enregistrer' : 'Créer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on Apartment {
  Apartment copyWith({
    String? title,
    String? city,
    int? price,
    String? description,
    String? ownerId,
  }) {
    return Apartment(
      id: id,
      title: title ?? this.title,
      city: city ?? this.city,
      price: price ?? this.price,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}
