AAPNI CHAI Android App – Starter Project

Is ZIP mein Flutter Android app ka starter source code diya gaya hai.
Yeh abhi deployed/live app ya APK nahi hai. Firebase project configuration aur Android build karna baaki hai.

Features in starter:
- Email/password login (Firebase Authentication)
- Owner / Staff role-based read-only staff screen
- Shopkeeper add: name, phone, address, per-glass rate, opening balance
- Delivery entry with timestamp, glass quantity and rate snapshot
- Payment entry
- Dashboard: today's sales and glass count
- Shopkeeper ledger

Important current limitations:
- WhatsApp share action, Excel export, editing/deleting entries, monthly summaries,
  automated balance aggregation, backup schedule, and production-grade validation
  are not yet implemented.
- Staff role must be assigned as 'staff' in Firestore users/{uid}; owner as 'owner'.
- Owner account and Firebase security rules must be configured before real customer data is entered.
- Do not use sample/test data as real business records.

Build steps:
1. Install Flutter SDK and Android Studio on a computer.
2. Create a Firebase project at https://console.firebase.google.com/
3. Enable Authentication > Email/Password.
4. Create Firestore database.
5. Install FlutterFire CLI and run:
   dart pub global activate flutterfire_cli
   flutterfire configure
6. Replace Firebase.initializeApp() with generated DefaultFirebaseOptions.currentPlatform
   and add generated firebase_options.dart.
7. Apply firestore.rules.example after reviewing it.
8. Create users/{FirebaseAuth UID} documents with role='owner' or role='staff'.
9. Run:
   flutter pub get
   flutter run
10. Build APK:
   flutter build apk --release
   Output: build/app/outputs/flutter-apk/app-release.apk

Data model:
shopkeepers/{shopId}: name, phone, address, rate, openingBalance, active, createdAt
users/{uid}: role ('owner' or 'staff')
ledger/{entryId}: shopId, shopName, type ('delivery'|'payment'), amount, glasses,
                  date, time, note, createdAt
deliveries/{deliveryId}: shopId, shopName, amount, glasses, date, time, createdAt

Before launch, add tested balance calculation and export/share workflows.
