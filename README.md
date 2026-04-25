# bookcart

Flutter app for browsing, listing, and managing books with Firebase-backed
login and profile data.

## Chat Notifications

This repo now includes Firebase Cloud Messaging wiring for mobile chat alerts:

- Foreground chat messages show a `SnackBar`
- Foreground call payloads show a high-priority local notification
- Background/terminated alerts are handled by FCM, with a local-notification
  fallback for data-only payloads
- Signed-in users automatically save their device tokens to
  `users/{uid}.notificationTokens`

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

The app stores user profiles, book listings, and live chats in Firestore, so create the database too.

1. In Firebase Console, open `Firestore Database`.
2. Click `Create database`.
3. Choose `Start in test mode` for local development.
4. Pick a nearby region.
5. Click `Enable`.

For development, this repo includes `firestore.rules`. Deploy them with:

```bash
firebase deploy --only firestore:rules
```

The rule set allows signed-in users to read listings, manage their own listings, and chat only in threads where they are a participant:

```txt
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() {
      return request.auth != null;
    }

    function isChatParticipant(chatId) {
      return signedIn() &&
        request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participantIds;
    }

    match /users/{userId} {
      allow read, write: if signedIn() && request.auth.uid == userId;
    }

    match /books/{bookId} {
      allow read: if signedIn();
      allow create: if signedIn() &&
        request.resource.data.sellerId == request.auth.uid;
      allow update, delete: if signedIn() &&
        resource.data.sellerId == request.auth.uid;
    }

    match /chats/{chatId} {
      allow read, update: if signedIn() &&
        request.auth.uid in resource.data.participantIds;
      allow create: if signedIn() &&
        request.auth.uid in request.resource.data.participantIds;

      match /messages/{messageId} {
        allow read: if isChatParticipant(chatId);
        allow create: if isChatParticipant(chatId) &&
          request.resource.data.senderId == request.auth.uid;
      }
    }
  }
}
```

## Firebase Messaging Setup

Use these steps to make chat and call notifications work on Android and iPhone.

### 1. Turn on Cloud Messaging

1. Open [Firebase Console](https://console.firebase.google.com/).
2. Open your Firebase project.
3. Go to `Project settings` -> `Cloud Messaging`.
4. Leave Android as-is if `google-services.json` is already added.
5. For iOS, upload an APNs authentication key or APNs certificates.

### 2. Android setup

This repo already contains:

- `android/app/google-services.json`
- `POST_NOTIFICATIONS` permission
- default FCM channel id: `bookcart_chat`

After pulling the latest code, run:

```bash
flutter pub get
flutter run
```

When the app opens on Android 13+, allow notifications when prompted.

### 3. iOS setup

In Xcode, open `ios/Runner.xcworkspace`, then for the `Runner` target enable:

1. `Signing & Capabilities` -> `Push Notifications`
2. `Signing & Capabilities` -> `Background Modes`
3. Check `Remote notifications`

Then run on a real iPhone:

```bash
flutter run
```

The simulator is not enough for APNs push delivery.

### 4. Message payload contract

Use `data.type` to control the app behavior:

- `chat`: shows a foreground `SnackBar`
- `call`: shows a high-priority local notification

Useful keys:

- `type`
- `chatId`
- `senderName`
- `callerName`
- `bookTitle`
- `message`
- `title`
- `body`

Example chat payload:

```json
{
  "message": {
    "token": "USER_FCM_TOKEN",
    "notification": {
      "title": "New message from Rahul",
      "body": "Is this book still available?"
    },
    "data": {
      "type": "chat",
      "chatId": "book123_seller456_buyer789",
      "senderName": "Rahul",
      "bookTitle": "Atomic Habits",
      "message": "Is this book still available?"
    },
    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "bookcart_chat"
      }
    },
    "apns": {
      "payload": {
        "aps": {
          "sound": "default"
        }
      }
    }
  }
}
```

Example call-style payload:

```json
{
  "message": {
    "token": "USER_FCM_TOKEN",
    "notification": {
      "title": "Incoming call from Priya",
      "body": "Tap to open the book chat"
    },
    "data": {
      "type": "call",
      "chatId": "book123_seller456_buyer789",
      "callerName": "Priya",
      "bookTitle": "Atomic Habits"
    },
    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "bookcart_call"
      }
    },
    "apns": {
      "headers": {
        "apns-priority": "10"
      },
      "payload": {
        "aps": {
          "sound": "default"
        }
      }
    }
  }
}
```

### 5. Example backend trigger

Background notifications do not happen by themselves when a Firestore chat
message is written. You need backend code to send the FCM message.

Example Firebase Cloud Function:

```js
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendChatNotification = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const message = event.data.data();
    const chatId = event.params.chatId;

    const chatSnap = await admin.firestore().doc(`chats/${chatId}`).get();
    const chat = chatSnap.data();
    if (!chat) return;

    const recipientId =
      chat.buyerId === message.senderId ? chat.sellerId : chat.buyerId;

    const userSnap = await admin.firestore().doc(`users/${recipientId}`).get();
    const tokens = userSnap.data()?.notificationTokens || [];
    if (!tokens.length) return;

    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: `New message from ${chat.buyerId === message.senderId ? chat.buyerName : chat.sellerName}`,
        body: message.text || "Open the app to view the latest message."
      },
      data: {
        type: "chat",
        chatId,
        senderName: chat.buyerId === message.senderId ? chat.buyerName : chat.sellerName,
        bookTitle: chat.bookTitle || "",
        message: message.text || ""
      },
      android: {
        priority: "high",
        notification: {
          channelId: "bookcart_chat"
        }
      },
      apns: {
        payload: {
          aps: {
            sound: "default"
          }
        }
      }
    });
  }
);
```

If you also want a real incoming-call UI instead of a high-priority
notification, add CallKit/ConnectionService support separately. The current
code stops at notification-level call alerts.

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
