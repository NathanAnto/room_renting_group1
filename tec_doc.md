# Documentation – Room Renting (Flutter + Firebase)

> **Scope**
> • Architecture du projet
> • Configuration Firebase
> • Initialisation Firebase dans Flutter
> • Utilisation de Firestore (CRUD + exemples)
> • Utilisation de Firebase Authentication
> • Règles de sécurité Firestore (CRUD basé permissions)

---

## 1) Architecture

**Couches & modules**

```
lib/
├─ core/
│  ├─ models/              # Listing, Booking, Profile, Review
│  ├─ services/            # AuthService, ListingService, BookingService, ProfileService
│  └─ utils/               # helpers
├─ features/
│  ├─ authentication/      # écrans login / sign up
│  ├─ listings/            # liste, détail, création/édition
│  ├─ bookings/            # planification & gestion des réservations
│  ├─ reviews/             # avis
│  └─ widgets/             # UI réutilisable
├─ router/                 # go_router (navigation)
└─ main.dart               # bootstrap + Firebase.initializeApp
```

**Data Flow (simplifié)**

```
UI (features/*)  →  Services (core/services/*)  →  Firebase (Auth/Firestore/Storage)
                          ↑                                ↓ (Streams/Snapshots)
                     Models (core/models/*)  ←─────────────┘
```

Libs clés : Flutter, Riverpod/Provider, go\_router, shadcn\_ui, cloud\_firestore, firebase\_auth, firebase\_storage.

---

## 2) Configurer Firebase

1. **Créer le projet** sur console.firebase.google.com
2. **Activer** :

   * *Authentication* → Email/Password (et autres fournisseurs si besoin)
   * *Firestore Database* → mode production
   * *Storage*
3. **Associer les apps** : Android, iOS, Web.
4. **FlutterFire CLI**

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   → Génère `lib/firebase_options.dart` pour chaque plateforme.

**Android** : renseigner `applicationId` dans `android/app/build.gradle`.

**iOS** : ouvrir `Runner.xcworkspace` après ajout de l’app iOS.

**Web** : le `index.html` est auto‑configuré par FlutterFire; si besoin, ajoutez vos meta CSP.

---

## 3) Initialiser Firebase (Flutter)

**pubspec.yaml** (extrait)

```yaml
dependencies:
  firebase_core: ^3.x
  cloud_firestore: ^5.x
  firebase_auth: ^5.x
  firebase_storage: ^12.x
```

**main.dart** (bootstrap minimal)

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
```

---

## 4) Firestore – Utilisation

### Collections & documents

* **Profile/{uid}**: `{ displayName, phone, photoUrl, school, country, role }`
* **Listing/{listingId}**: `{ ownerId, title, description, city, address, rentPerMonth, availability: { windows:[{start,end}] } }`
* **bookings/{bookingId}**: `{ listingId, hostId, studentId, start, end, status }`
* **Review/{reviewId}**: `{ bookingId, listingId, authorId, rating, comment }`

> **Indexation** : créez les index au besoin (Firestore vous proposera un lien d’index quand une requête échoue).

### Exemples CRUD (Dart)

**Créer un listing**

```dart
final doc = FirebaseFirestore.instance.collection('Listing').doc();
await doc.set({
  'ownerId': uid,
  'title': title,
  'city': city,
  'rentPerMonth': rent,
  'createdAt': FieldValue.serverTimestamp(),
});
```

**Lire les listings publics**

```dart
final qs = await FirebaseFirestore.instance
  .collection('Listing')
  .orderBy('createdAt', descending: true)
  .limit(20)
  .get();
final listings = qs.docs.map((d) => d.data()).toList();
```

**Listings de l’owner courant** (compatible règles)

```dart
FirebaseFirestore.instance
  .collection('Listing')
  .where('ownerId', isEqualTo: uid)
  .snapshots();
```

**Créer un booking (pending)**

```dart
final bRef = FirebaseFirestore.instance.collection('bookings').doc();
await bRef.set({
  'listingId': listingId,
  'hostId': hostId,
  'studentId': uid,
  'start': Timestamp.fromDate(start),
  'end': Timestamp.fromDate(end),
  'status': 'pending',
  'createdAt': FieldValue.serverTimestamp(),
});
```

**Bookings de l’étudiant**

```dart
FirebaseFirestore.instance
  .collection('bookings')
  .where('studentId', isEqualTo: uid)
  .snapshots();
```

**Bookings de l’hôte**

```dart
FirebaseFirestore.instance
  .collection('bookings')
  .where('hostId', isEqualTo: uid)
  .snapshots();
```

> **Chevauchement de dates** : à gérer côté service (transaction/Cloud Function) – Firestore Rules ne peuvent pas faire de requêtes de plage.

---

## 5) Firebase Authentication – Utilisation

**Inscription / connexion**

```dart
final auth = FirebaseAuth.instance;
await auth.createUserWithEmailAndPassword(email: email, password: pwd);
await auth.signInWithEmailAndPassword(email: email, password: pwd);
```

**État d’auth en direct**

```dart
auth.authStateChanges().listen((user) {
  if (user == null) { /* déconnecté */ } else { /* connecté */ }
});
```

**Utilisateur courant**

```dart
final user = FirebaseAuth.instance.currentUser; // null si déconnecté
```

**Déconnexion**

```dart
await FirebaseAuth.instance.signOut();
```

**Rôles / Admin**

* Stockez `role` (affichage/logiciel) dans `Profile/{uid}`.
* Pour un **admin** de sécurité, utilisez des **custom claims** via l’Admin SDK (Cloud Function) et lisez-les côté client avec `getIdTokenResult()` si nécessaire.

---

## 6) Règles Firestore (CRUD par permissions)

> Minimalistes : pas de validation de schéma; uniquement qui a le droit d’écrire/lire.

```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() { return request.auth != null; }
    function isAdmin() { return signedIn() && request.auth.token.admin == true; }

    // Profile
    match /Profile/{userId} {
      allow read: if true; // ou signedIn()
      allow create: if signedIn() && request.auth.uid == userId;
      allow update: if signedIn() && request.auth.uid == userId
                    && (!('role' in request.resource.data) || request.resource.data.role == resource.data.role);
      allow delete: if isAdmin() || (signedIn() && request.auth.uid == userId);
    }

    // Listing
    match /Listing/{listingId} {
      allow read: if true;
      allow create: if signedIn() && request.resource.data.ownerId == request.auth.uid;
      allow update: if signedIn() && (resource.data.ownerId == request.auth.uid || isAdmin())
                    && (!('ownerId' in request.resource.data) || request.resource.data.ownerId == resource.data.ownerId);
      allow delete: if signedIn() && (resource.data.ownerId == request.auth.uid || isAdmin());
    }

    // Bookings
    match /bookings/{bookingId} {
      allow read: if signedIn() && (resource.data.studentId == request.auth.uid || resource.data.hostId == request.auth.uid || isAdmin());
      allow create: if signedIn() && request.resource.data.studentId == request.auth.uid;
      allow update: if signedIn() && (resource.data.studentId == request.auth.uid || resource.data.hostId == request.auth.uid || isAdmin())
                    && (!('studentId' in request.resource.data) || request.resource.data.studentId == resource.data.studentId)
                    && (!('hostId' in request.resource.data) || request.resource.data.hostId == resource.data.hostId)
                    && (!('listingId' in request.resource.data) || request.resource.data.listingId == resource.data.listingId);
      allow delete: if signedIn() && (resource.data.studentId == request.auth.uid || resource.data.hostId == request.auth.uid || isAdmin());
    }

    // Review
    match /Review/{reviewId} {
      allow read: if true;
      allow create: if signedIn() && request.resource.data.authorId == request.auth.uid;
      allow update, delete: if signedIn() && (resource.data.authorId == request.auth.uid || isAdmin());
    }
  }
}
```

**Conseils**

* Testez vos règles avec **Firebase Emulator Suite** et le **Rules Playground**.
* Bornez vos requêtes côté client (ex. `.where('hostId', isEqualTo: uid)`), pour que Firestore puisse évaluer les règles.

---

## 7) Déploiement & environnements

* **Emulators**: `firebase emulators:start` pour développer hors prod.
* **Déploiement Rules**: `firebase deploy --only firestore:rules`
* **Android App Bundle**: `flutter build appbundle --release`
* **Web**: `flutter build web` puis héberger (Firebase Hosting ou autre).

---

## 8) Troubleshooting rapide

* *PERMISSION\_DENIED* : vérifiez la requête (bornes `.where(...)`) et l’auth.
* *Missing or insufficient permissions* : la règle `update` empêche peut‑être un champ protégé (ex. `ownerId`, `role`).
* *Index requis* : créez l’index proposé par la console Firestore.
* *Horodatages* : utilisez `Timestamp` (Firestore) plutôt que des strings pour les dates manipulées.

---

### Annexes (optionnel)

* Diagrammes de navigation (go\_router)
* Conventions de nommage & style
* Matrice de permissions (qui peut créer/éditer/supprimer quoi)
* Process de revue de code et branches Git
