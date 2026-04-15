# bookcart

Flutter app for browsing, listing, and managing books with Firebase-backed
login and profile data.

## Run The App

1. Install Flutter and confirm it works:

   ```bash
   flutter doctor
   ```

2. Install packages:

   ```bash
   flutter pub get
   ```

3. Start the app on Android, iOS, or web:

   ```bash
   flutter run
   ```

This repository already includes Firebase configuration for:

- Android
- iOS
- web

You do not need `--dart-define` values for those platforms unless you want to
override the built-in Firebase project.

## Firebase Auth Setup

Use these steps if login or signup is not working yet.

1. Open [Firebase Console](https://console.firebase.google.com/).
2. Open the `bookcart-c7f2f` project, or your own Firebase project.
3. Go to `Authentication` -> `Sign-in method`.
4. Click `Email/Password`.
5. Turn on `Email/Password`.
6. Click `Save`.

This app uses email and password login, so Google sign-in is not required.

## Firestore Setup

The app stores user profile data in Firestore, so create the database too.

1. In Firebase Console, open `Firestore Database`.
2. Click `Create database`.
3. Choose `Start in test mode` for local development.
4. Pick a nearby region.
5. Click `Enable`.

For development, a simple rule set is:

```txt
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## If You Want A New Firebase Project

If you want to connect this app to a different Firebase project:

1. Create the project in Firebase Console.
2. Add Android, iOS, or web apps to that project.
3. Run:

   ```bash
   flutterfire configure
   ```

4. Replace the generated Firebase files in this repo.
5. Run `flutter run` again.
