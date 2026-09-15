# BulkMailer

A professional email marketing platform built with **Flutter Web** + **Firebase** + **Gmail API**.

Similar to Mailchimp, MailerLite, and Brevo — but running on your own Firebase project.

## Features

- ?? **Import contacts** from Excel (.xlsx) or CSV files
- ?? **Personalized emails** with `{{first_name}}`, `{{last_name}}`, `{{email}}` merge tags
- ?? **HTML template editor** with live preview
- ?? **Campaign tracking** — sent/failed/total counts, delivery rate
- ?? **Safe sending** via Gmail API — staggered queue (10/min) to avoid spam filters
- ?? **Unsubscribe handling** — automatic + one-click unsubscribe
- ?? **Firebase Auth** — Google Sign-In
- ?? **Progressive Web App** — works on desktop and mobile

## Tech Stack

| | |
|--|--|
| Frontend | Flutter Web (Dart 3, Riverpod 2, GoRouter) |
| Auth | Firebase Authentication (Google) |
| Database | Cloud Firestore |
| Functions | Firebase Cloud Functions (TypeScript) |
| Email | Gmail API v1 via OAuth 2.0 |
| Hosting | Firebase Hosting |

## Getting Started

### 1. Prerequisites

- Flutter SDK (3.x+)
- Node.js 20+
- Firebase CLI: `npm install -g firebase-tools`
- Firebase project: **flix-mailer** (already configured)

### 2. Run locally

```bash
flutter pub get
flutter run -d chrome
```

### 3. Build & Deploy

```bash
# Build Flutter web
flutter build web --release

# Deploy to Firebase Hosting
npx -y firebase-tools@latest deploy --only hosting
```

### 4. Deploy Cloud Functions

> [!IMPORTANT]
> Cloud Functions require the **Firebase Blaze (pay-as-you-go) plan**.
> Upgrade at: https://console.firebase.google.com/project/flix-mailer/usage/details

```bash
cd functions
npm install
npm run build
cd ..
npx -y firebase-tools@latest deploy --only functions
```

### 5. Enable Gmail API

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/library/gmail.googleapis.com?project=flix-mailer)
2. Enable the **Gmail API** for the `flix-mailer` project
3. The OAuth client is already configured via Firebase Auth

### 6. Set up Firestore indexes & rules

```bash
npx -y firebase-tools@latest deploy --only firestore
```

## Email Sending Architecture

```
User creates campaign
       ?
Firestore: campaign.status = "sending"
       ?
Cloud Function trigger: create email_jobs documents (one per subscriber)
       ?
Scheduled Function (every 1 min): pick 10 pending jobs
       ?
Gmail API: send personalized email
       ?
Update job.status = "sent" | "failed"
Update campaign.stats.sent++
       ?
When all jobs done ? campaign.status = "sent"
```

## Gmail Limits

| Account Type | Daily Limit |
|--|--|
| Free Gmail | ~500 emails/day |
| Google Workspace | ~2,000 emails/day |

Emails are sent at 10/minute to stay well within these limits and avoid spam filters.

## Folder Structure

```
bulk_mailer/
+-- lib/
¦   +-- main.dart
¦   +-- app.dart
¦   +-- firebase_options.dart
¦   +-- core/
¦   ¦   +-- constants/
¦   ¦   +-- theme/
¦   ¦   +-- router/
¦   +-- data/
¦   ¦   +-- models/       # Firestore data models
¦   ¦   +-- services/     # Firebase, Gmail, Excel services
¦   ¦   +-- repositories/
¦   +-- features/
¦   ¦   +-- auth/
¦   ¦   +-- dashboard/
¦   ¦   +-- contacts/     # Contact lists + Excel import
¦   ¦   +-- campaigns/    # Campaign management + wizard
¦   ¦   +-- templates/    # HTML template editor
¦   ¦   +-- settings/
¦   +-- shared/
¦       +-- widgets/
¦       +-- providers/
+-- functions/            # Cloud Functions (TypeScript)
¦   +-- src/
¦       +-- index.ts
¦       +-- sendEmailBatch.ts
¦       +-- processEmailQueue.ts
¦       +-- unsubscribeHandler.ts
+-- web/
+-- firebase.json
+-- firestore.rules
+-- .firebaserc
```
