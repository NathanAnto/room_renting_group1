import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/apartment.dart';

class ApartmentService {
  final _col = FirebaseFirestore.instance.collection('apartments');

  Stream<List<Apartment>> streamAll() {
    return _col.orderBy('title').snapshots().map((snap) =>
        snap.docs.map((d) => Apartment.fromMap(d.id, d.data())).toList());
  }

  Future<void> add(Apartment a) async {
    await _col.add(a.toMap());
  }

  Future<void> update(Apartment a) async {
    await _col.doc(a.id).update(a.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Future<Apartment?> getById(String id) async {
    final d = await _col.doc(id).get();
    if (!d.exists) return null;
    return Apartment.fromMap(d.id, d.data()!);
  }
}
