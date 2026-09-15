# BulkMailer — Complete Project Walkthrough & Implementation Guide

This document provides a comprehensive walkthrough of the **BulkMailer** platform — an email marketing SaaS platform built with **Flutter Web**, **Firebase**, and the **Gmail API** for project **`flix-mailer`**.

---

## 📌 Table of Contents
1. [Executive Summary](#executive-summary)
2. [What Has Been Implemented](#what-has-been-implemented)
   - [1. Frontend Architecture & Design System](#1-frontend-architecture--design-system)
   - [2. Authentication & Gmail OAuth](#2-authentication--gmail-oauth)
   - [3. Audience & Contact Management (Excel/CSV Import)](#3-audience--contact-management-excelcsv-import)
   - [4. Email Template Editor & Merge Tags](#4-email-template-editor--merge-tags)
   - [5. Campaign Creation & Real-Time Tracking](#5-campaign-creation--real-time-tracking)
   - [6. Anti-Spam & Gmail Delivery Engine](#6-anti-spam--gmail-delivery-engine)
   - [7. Firebase Backend (Cloud Functions & Firestore)](#7-firebase-backend-cloud-functions--firestore)
3. [Verification & Test Results](#verification--test-results)
4. [What Else To Do (Next Steps & Roadmap)](#what-else-to-do-next-steps--roadmap)
5. [How to Run and Deploy](#how-to-run-and-deploy)

---

## Executive Summary

**BulkMailer** enables users to import subscriber lists via Excel/CSV, compose HTML emails with personalized merge tags (e.g. `{{first_name}}`, `{{email}}`), and send them via their connected Google Mail account without landing in spam filters or hitting rate limits.

---

## What Has Been Implemented

### 1. Frontend Architecture & Design System
- **Framework**: Flutter Web (Dart 3.12+, PWA ready).
- **State Management**: [Riverpod 2.x](file:///C:/Dev/bulk_mailer/lib/shared/providers/auth_provider.dart) with reactive streams (`StreamProvider`, `AsyncNotifier`).
- **Routing**: [GoRouter](file:///C:/Dev/bulk_mailer/lib/core/router/app_router.dart) with stateful `ShellRoute`, deep linking, and automated authentication guards (`/login` vs protected routes).
- **Theme**: Material 3 dark theme (`#0F1117` background, `#1A1D27` surface, `#6C63FF` primary purple accent) in [app_theme.dart](file:///C:/Dev/bulk_mailer/lib/core/theme/app_theme.dart).
- **Responsive Layout**: Collapsible sidebar navigation shell in [app_shell.dart](file:///C:/Dev/bulk_mailer/lib/shared/widgets/app_shell.dart) with active route indicator.

### 2. Authentication & Gmail OAuth
- **Firebase Auth**: Integrated Google Sign-In with automated user profile provisioning into Firestore collection `users/{uid}`.
- **Gmail OAuth Scopes**: Scopes for `gmail.send` requested during sign-in/connection to allow authenticated sending as the user.
- **Login UI**: Branded split-screen sign-in screen in [login_page.dart](file:///C:/Dev/bulk_mailer/lib/features/auth/presentation/login_page.dart) with feature bullet points and Google SSO button.
- **Settings Screen**: [settings_page.dart](file:///C:/Dev/bulk_mailer/lib/features/settings/presentation/settings_page.dart) displaying active Gmail connection status, email address, account limits, and one-click disconnect/logout.

### 3. Audience & Contact Management (Excel/CSV Import)
- **Contact Lists**: Ability to create multiple subscriber lists, view subscriber counts, and delete lists with cascade cleanup in [contacts_page.dart](file:///C:/Dev/bulk_mailer/lib/features/contacts/presentation/contacts_page.dart).
- **4-Step Import Wizard** in [import_contacts_page.dart](file:///C:/Dev/bulk_mailer/lib/features/contacts/presentation/import_contacts_page.dart):
  1. **Upload**: Drag-and-drop file picker supporting `.xlsx`, `.xls`, and `.csv`.
  2. **Column Mapping**: Auto-detects headers (`email`, `first_name`, `last_name`) and lets users map or skip custom columns.
  3. **Preview**: Displays total subscriber count and the first 5 parsed records in a styled data table.
  4. **Batch Import**: Executes batched writes (500 documents per batch) to Firestore with incremental counter updates.

### 4. Email Template Editor & Merge Tags
- **Editor UI**: [template_editor_page.dart](file:///C:/Dev/bulk_mailer/lib/features/templates/presentation/template_editor_page.dart) with subject line input, template name, and responsive HTML body editor.
- **Interactive Merge Tags**: Click-to-insert merge tags (`{{first_name}}`, `{{last_name}}`, `{{full_name}}`, `{{email}}`).
- **Live Preview Mode**: Seamless toggle between editor and preview that renders HTML with realistic mock recipient data.
- **Template Gallery**: [templates_page.dart](file:///C:/Dev/bulk_mailer/lib/features/templates/presentation/templates_page.dart) listing all saved templates with last updated timestamps.

### 5. Campaign Creation & Real-Time Tracking
- **4-Step Campaign Wizard** in [create_campaign_page.dart](file:///C:/Dev/bulk_mailer/lib/features/campaigns/presentation/create_campaign_page.dart):
  1. **Details**: Campaign name, subject line, optional custom sender name, and reply-to email.
  2. **Audience**: Interactive picker to select target subscriber list.
  3. **Template**: Visual selector for pre-made email templates.
  4. **Review & Send**: Summary check, spam prevention notice, and one-click launch button.
- **Campaign Dashboard & List**: Real-time progress bars, delivery rates, and status indicators (`draft`, `scheduled`, `sending`, `sent`, `failed`) in [campaigns_page.dart](file:///C:/Dev/bulk_mailer/lib/features/campaigns/presentation/campaigns_page.dart) and [dashboard_page.dart](file:///C:/Dev/bulk_mailer/lib/features/dashboard/presentation/dashboard_page.dart).

### 6. Anti-Spam & Gmail Delivery Engine
- **Staggered Queue**: Emails are **not** blasted simultaneously. Campaigns generate individual `email_jobs` that are queued.
- **Cloud Scheduler (1 min)**: Cloud function [processEmailQueue.ts](file:///C:/Dev/bulk_mailer/functions/src/processEmailQueue.ts) processes up to 10 emails every minute, staying well below spam triggers.
- **RFC-Compliant Headers**: Injects `List-Unsubscribe` and `List-Unsubscribe-Post: List-Unsubscribe=One-Click`.
- **Unsubscribe Handler**: Cloud function [unsubscribeHandler.ts](file:///C:/Dev/bulk_mailer/functions/src/unsubscribeHandler.ts) provides a one-click unsubscribe endpoint and confirmation webpage.

### 7. Firebase Backend (Cloud Functions & Firestore)
- **Functions Codebase**: TypeScript in Node.js 20 with `firebase-admin` and `firebase-functions/v2`.
- **Firestore Security Rules**: [firestore.rules](file:///C:/Dev/bulk_mailer/firestore.rules) enforcing user-level data isolation.
- **Compound Indexes**: [firestore.indexes.json](file:///C:/Dev/bulk_mailer/firestore.indexes.json) for filtered and sorted queries.
- **Hosting Configuration**: [firebase.json](file:///C:/Dev/bulk_mailer/firebase.json) configured for single-page app rewrites and asset caching.

---

## 🧪 Verification & Test Results

| Verification Step | Command | Status | Notes |
|---|---|---|---|
| **Dart Static Analysis** | `flutter analyze` | ✅ **PASS** | 0 errors, 0 warnings |
| **Unit / Widget Tests** | `flutter test` | ✅ **PASS** | All tests passed |
| **Functions Compilation** | `npm run build` | ✅ **PASS** | TypeScript compiled to `lib/` with exit code 0 |
| **Production Web Build** | `flutter build web --release` | ✅ **PASS** | HTML, service workers, canvaskit, and tree-shaken JS created in `build/web` |

---

## 📋 What Else To Do (Next Steps & Roadmap)

Here is the checklist of operational requirements and recommended enhancements before going to production:

### ⚠️ Operational Prerequisites (Before First Live Send)
- [ ] **Upgrade Firebase to Blaze Plan**:
  - Cloud Functions require outbound HTTP connections to `gmail.googleapis.com`.
  - Go to [Firebase Console Billing](https://console.firebase.google.com/project/flix-mailer/usage/details) and activate the pay-as-you-go (Blaze) plan (free quotas apply).
- [ ] **Enable Gmail API in Google Cloud Console**:
  - Open [Google Cloud Console API Library](https://console.cloud.google.com/apis/library/gmail.googleapis.com?project=flix-mailer).
  - Select project `flix-mailer` and click **Enable**.
- [ ] **Configure OAuth Consent Screen**:
  - In [Google Cloud Console OAuth Consent Screen](https://console.cloud.google.com/apis/credentials/consent?project=flix-mailer), add the scope `https://www.googleapis.com/auth/gmail.send`.
  - Add test users or publish the consent screen to avoid OAuth verification warnings.
- [ ] **Deploy Security Rules & Functions**:
  ```powershell
  npx -y firebase-tools@latest deploy --only firestore,functions
  ```

### 🚀 Recommended Feature Enhancements
1. **Open & Click Tracking**:
   - Add a 1x1 transparent tracking pixel endpoint in Cloud Functions (`/track/open?jobId=...`) to record actual email open events in `campaigns.stats.opened`.
   - Wrap links in campaign emails with a redirect endpoint (`/track/click?url=...&jobId=...`) to track click-through rates (CTR).
2. **Visual Drag-and-Drop Template Builder**:
   - Currently, templates support clean HTML code with live preview. A future update could add a block-based visual email designer (integrating GrapeJS, MJML, or Flutter drag-and-drop cards).
3. **Multi-Provider Fallback (SMTP / SendGrid / Brevo)**:
   - Free Gmail is capped at ~500 emails/day and Google Workspace at ~2,000 emails/day.
   - Add an optional SMTP/API relay fallback (SendGrid, Mailgun, Amazon SES, Brevo) in `Settings` for high-volume senders (>10,000 emails/day).
4. **Automated Bounce Detection**:
   - Use Gmail API pub/sub topic notifications to detect delivery failure (bounce) notification messages and automatically update contact status to `bounced`.
5. **Campaign Scheduling**:
   - Add a datetime picker in the campaign creation wizard to schedule a campaign for future delivery via Cloud Scheduler instead of immediate dispatch.

---

## 🚀 How to Run and Deploy

### 1. Run Locally
```powershell
cd c:\Dev\bulk_mailer
flutter run -d chrome
```

### 2. Deploy Web App to Firebase Hosting
```powershell
cd c:\Dev\bulk_mailer
flutter build web --release
npx -y firebase-tools@latest deploy --only hosting
```

### 3. Deploy Cloud Functions and Firestore Rules
```powershell
cd c:\Dev\bulk_mailer
npx -y firebase-tools@latest deploy --only firestore,functions
```