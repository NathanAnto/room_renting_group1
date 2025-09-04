# Documentation – Room Renting (Flutter + Firebase)

> **Scope**
> • Project architecture
> • Firebase configuration
> • Firebase initialization in Flutter
> • Firestore usage
> • Firebase Authentication usage
> • Firestore security rules (CRUD-based permissions)

---

## 1) Architecture

**Layers & modules**

```
lib/
├─ core/
│  ├─ models/              # Listing, Booking, Profile, Review
│  ├─ services/            # AuthService, ListingService, BookingService, ProfileService
│  └─ utils/               # helpers
├─ features/
│  ├─ authentication/      # login / sign up screens
│  ├─ listings/            # list, details, create/edit
│  ├─ bookings/            # planning & reservation management
│  ├─ reviews/             # reviews
│  └─ widgets/             # reusable UI
├─ router/                 # go_router (navigation)
└─ main.dart               # bootstrap + Firebase.initializeApp
```

**Data Flow (simplified)**

```
UI (features/*)  →  Services (core/services/*)  →  Firebase (Auth/Firestore/Storage)
                          ↑                                ↓ (Streams/Snapshots)
                     Models (core/models/*)  ←─────────────┘
```

### Key Libraries

**Firebase**

* `firebase_core` → Firebase initialization.
* `cloud_firestore` → Firestore NoSQL database.
* `firebase_auth` → authentication (email, Google, etc.).
* `firebase_storage` → file storage (images, docs…).

**Files & media**

* `image_picker` → pick images from gallery/camera.
* `file_picker` → pick any type of file.
* `carousel_slider` → carousel widget for image slideshows.
* `cached_network_image` → optimized caching of network images.
* `geolocator` → retrieve device GPS position.
* `geocoding` → convert GPS coordinates ↔ addresses.
* `http` → HTTP/REST requests.

**State management & routing**

* `flutter_hooks` → simplified reactive logic with hooks.
* `flutter_riverpod` → modern & robust state management.
* `go_router` → declarative route-based navigation.

**App info & external links**

* `package_info_plus` → app version/build info.
* `url_launcher` → open external links (web, mail, phone…).

**UI & utilities**

* `cupertino_icons` → iOS-style icons.
* `provider` → legacy state manager (may duplicate Riverpod).
* `uuid` → generate unique IDs.
* `shadcn_ui` → UI component library.
* `country_picker` → country picker widget.
* `lucide_icons_flutter` → Lucide icons pack.

**Reviews & text formatting**

* `intl` → date/number formatting (internationalization).
* `timeago` → relative time display (“2 hours ago”).

**Dev only**

* `flutter_test` → unit & widget testing framework.
* `flutter_lints` → linting rules (best practices).

---

## 2) Firebase Configuration

1. **Create the project** at console.firebase.google.com
2. **Enable**:

   * *Authentication* → Email/Password (and others if needed)
   * *Firestore Database* → production mode
   * *Storage*
3. **Register apps**: Android, iOS, Web.
4. **FlutterFire CLI**

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   → Generates `lib/firebase_options.dart` for each platform.

**Android**: set `applicationId` in `android/app/build.gradle`.
**iOS**: open `Runner.xcworkspace` after registering iOS app.
**Web**: `index.html` is auto-configured by FlutterFire; add CSP meta if needed.

---

## 3) Firebase Initialization (Flutter)

**pubspec.yaml** (excerpt)

```yaml
dependencies:
  firebase_core: ^3.x
  cloud_firestore: ^5.x
  firebase_auth: ^5.x
  firebase_storage: ^12.x
```

**main.dart** (minimal bootstrap)

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

## 4) Firestore – Usage

---

### Collections & documents

#### **Profile/{uid}**

Represents a user profile.

```json
{
  "id": "string (Firebase uid)",
  "displayName": "string",
  "email": "string",
  "phone": "string",
  "photoUrl": "string",
  "school": "string",
  "country": "string",
  "role": "string (student | homeowner | admin)",
  "createdAt": "timestamp"
}
```

---

#### **Listing/{listingId}**

Listing posted by a homeowner.

```json
{
  "id": "string",
  "ownerId": "string (Profile.uid)",
  "title": "string",
  "description": "string",
  "city": "string",
  "addressLine": "string",
  "lat": "double",
  "lng": "double",
  "rentPerMonth": "number",
  "predictedRentPerMonth": "number",
  "num_rooms": "number",
  "amenities": {
    "wifi_incl": "bool",
    "is_furnished": "bool",
    "car_park": "bool",
    "charges_incl": "bool"
  },
  "availability": {
    "windows": [
      { "start": "timestamp|string", "end": "timestamp|string", "label": "string|null" }
    ],
    "minStayNights": "number",
    "maxStayNights": "number"
  },
  "images": ["string (urls)"],
  "status": "string (active | archived)",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

---

#### **bookings/{bookingId}**

Booking made by a student for a listing.

```json
{
  "id": "string",
  "listingid": "string (Listing.id)",
  "homeownerid": "string (Profile.uid)",
  "studentid": "string (Profile.uid)",
  "start": "timestamp",
  "end": "timestamp",
  "nights": "number",
  "price": "number",
  "status": "string (pending | accepted | declined | cancelled)",
  "createdAt": "timestamp"
}
```

---

#### **Review/{reviewId}**

Review submitted after an accepted booking.

```json
{
  "id": "string",
  "bookingId": "string (bookings.id)",
  "listingId": "string (Listing.id)",
  "ownerId": "string (Profile.uid)",
  "studentId": "string (Profile.uid)",
  "reviewerType": "string (owner | student)",
  "rating": "number (1-5)",
  "comment": "string",
  "createdAt": "timestamp"
}
```

> **Indexing**: Firestore will suggest indexes when a query fails; create them as required.

---

## 5) Firebase Authentication – Usage

**Sign up / Sign in**

```dart
final auth = FirebaseAuth.instance;
await auth.createUserWithEmailAndPassword(email: email, password: pwd);
await auth.signInWithEmailAndPassword(email: email, password: pwd);
```

**Auth state stream**

```dart
auth.authStateChanges().listen((user) {
  if (user == null) { /* signed out */ } else { /* signed in */ }
});
```

**Current user**

```dart
final user = FirebaseAuth.instance.currentUser; // null if logged out
```

**Sign out**

```dart
await FirebaseAuth.instance.signOut();
```

**Roles / Admin**

* Store `role` (for UI/business logic) in `Profile/{uid}`.
* For **secure admin roles**, use **custom claims** via the Admin SDK (Cloud Function), and read them client-side with `getIdTokenResult()`.

---

## 6) Firestore Rules (CRUD by permissions)

> Minimalist: no schema validation; only checks **who can read/write**.

```rules
service cloud.firestore {
  match /databases/{database}/documents {

    // Helpers
    function signedIn() { return request.auth != null; }
    function isAdmin()  { return signedIn() && request.auth.token.admin == true; }

    // ---------------- Profile ----------------
    match /Profile/{userId} {
      allow read: if true;

      allow create: if signedIn() && request.auth.uid == userId;
      allow update: if signedIn() && request.auth.uid == userId
                    && (!('role' in request.resource.data)
                        || request.resource.data.role == resource.data.role);
      allow delete: if isAdmin() || (signedIn() && request.auth.uid == userId);
    }

    // ---------------- Listing ----------------
    match /Listing/{listingId} {
      allow read: if true;

      allow create: if signedIn()
                    && request.resource.data.ownerId == request.auth.uid;

      allow update: if signedIn()
                    && (resource.data.ownerId == request.auth.uid || isAdmin())
                    && (!('ownerId' in request.resource.data)
                        || request.resource.data.ownerId == resource.data.ownerId);

      allow delete: if signedIn()
                    && (resource.data.ownerId == request.auth.uid || isAdmin());
    }

    // ---------------- Bookings ----------------
    match /bookings/{bookingId} {
      allow read: if true;

      allow create: if signedIn()
                    && request.resource.data.studentid == request.auth.uid;

      allow update: if signedIn()
                    && (resource.data.studentid == request.auth.uid
                        || resource.data.homeownerid == request.auth.uid
                        || isAdmin())
                    && (!('studentid' in request.resource.data)
                        || request.resource.data.studentid == resource.data.studentid)
                    && (!('homeownerid' in request.resource.data)
                        || request.resource.data.homeownerid == resource.data.homeownerid)
                    && (!('listingid' in request.resource.data)
                        || request.resource.data.listingid == resource.data.listingid);

      allow delete: if signedIn()
                    && (resource.data.studentid == request.auth.uid
                        || resource.data.homeownerid == request.auth.uid
                        || isAdmin());
    }

    // ---------------- Review ----------------
    match /Review/{reviewId} {
      allow read: if true;

      allow create: if signedIn();
      allow delete: if isAdmin();
      allow update: if signedIn();
    }
  }
}
```

**Tips**

* Test rules using **Firebase Emulator Suite** and the **Rules Playground**.
* Always filter queries client-side (e.g., `.where('homeownerid', isEqualTo: uid)`) so Firestore can evaluate permissions efficiently.

---

## 7) Deployment & Environments

* **Emulators**: `firebase emulators:start` for local dev.
* **Deploy rules**: `firebase deploy --only firestore:rules`
* **Android App Bundle**: `flutter build appbundle --release`
* **Web**: `flutter build web` then host on Firebase Hosting (or any static hosting).

---
