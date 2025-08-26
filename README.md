# Room Renting Group 1

A cross-platform Flutter application for managing and renting rooms. This project supports Android, Linux, Windows, macOS, and web platforms.

## Project Description

Room Renting Group 1 is designed to help users find, rent, and manage rooms efficiently. It provides a user-friendly interface and integrates with Firebase for backend services.

## Development Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (version 3.35.1 or newer)
- **Android SDK** (API level 35 or newer)
- **OpenJDK 17** (recommended for Android builds)

You can install these tools using your operating system’s package manager or by following the official installation guides:

- [Flutter installation guide](https://docs.flutter.dev/get-started/install)
- [Android SDK installation guide](https://developer.android.com/studio)
- [OpenJDK installation guide](https://openjdk.org/install/)

After installing, verify your Java version:

```sh
java -version
```

## Setup Instructions

1. Clone the repository:

```sh
git clone https://github.com/NathanAnto/room_renting_group1.git
cd room_renting_group1
```

2. Install dependencies:

```sh
flutter pub get
```

3. Connect your Android device or start an emulator.

4. Run the app:

```sh
flutter run
```


## Troubleshooting

If you encounter Gradle or Java compatibility errors, ensure you are using OpenJDK 17.
For more details, run:
```sh
flutter doctor --verbose
```

## Git Policies

We use the **git flow** workflow for managing branches:

- All new development must be done in `feature/` branches, branched off from `develop`.
- Feature branches should be named as `feature/<user-story>.<task>-<short-description>` (e.g., `feature/2.4-login-page`).
    - `<user-story>` is the User Story number.
    - `<task>` is the task number.
    - `<short-description>` is a brief summary of the feature.
    
- No direct commits to `master`.
- Pull requests should be opened from `feature/` branches to `develop`.
- Pull requests should be opened from the `develop` branch to `master`.
- Only merge to `develop` when task reviewed.
- Only merge to `master` the sprint is finished.

For more details on git flow, see: [Git Flow Documentation](https://nvie.com/posts/a-successful-git-branching-model/)
