# 🛡️ Scam Radar

> **A mobile app that detects, reports, and tracks scam messages and phone numbers in Sri Lanka**

Scam Radar is a collaborative community-driven mobile application built with Flutter and Supabase. It helps users identify suspicious scam messages using AI-powered analysis, report fraudulent phone numbers, and stay informed about emerging scam trends through a live community feed.

---gg

## ✨ Features

### 📱 **Message Analysis**
- Paste suspicious messages to instantly analyze them for scam indicators
- Real-time scam score (0-100%) with detailed reasoning
- Rule-based detection engine powered by ML Kit for text recognition
- Identifies techniques like urgency keywords, financial requests, phishing links, personal info requests, and more
- Report analyzed messages to contribute to the community database

### 📲 **Scam Number Reporting**
- Report fraudulent phone numbers with scam type classification
- Track report count for each number across the community
- Geolocate numbers by Sri Lankan district for map-based visualization
- Search previously reported numbers to avoid calling scammers
- Auto-creates community reports for transparency

### 🗺️ **Scam Map**
- Interactive OpenStreetMap (no API key required) centered on Sri Lanka
- Visualize reported scam numbers by geographic location
- Color-coded markers by scam type (lottery, bank fraud, romance, etc.)
- Tap markers to view detailed report information
- Real-time update legend showing total scam reports

### 👥 **Community Feed**
- Live feed of all scam reports (messages & phone numbers)
- Real-time updates via Supabase Realtime subscriptions
- Filter by report type (All, Messages, Numbers)
- Reporter names and timestamps for transparency
- Pull-to-refresh support
- Push notifications for new high-risk reports

### 📸 **Screenshot OCR Scanning**
- Extract text from screenshots using Google ML Kit
- Take photos directly from camera or upload from gallery
- Auto-analyze extracted text for scam indicators
- Seamless integration with message analyzer

### 🔐 **Authentication & Profiles**
- Email/password authentication via Supabase Auth
- Auto-confirm emails (no verification required for development)
- Personal profiles with stats tracking
- Dark mode / Light mode toggle

### 📊 **User Stats & Dashboard**
- Messages analyzed count
- Scam numbers reported count
- High-risk messages detected
- Community contribution visibility
- Quick action cards for all major features

### 🔔 **Push Notifications**
- Local notifications (expandable to Firebase Cloud Messaging)
- Alerts for new scam reports in the community
- Customizable notification settings in profile

---

## 🏗️ Architecture

### **Tech Stack**
- **Frontend**: Flutter 3+ with Material 3 design
- **State Management**: Riverpod 2.x (StateNotifier pattern)
- **Routing**: GoRouter with auth guards
- **Backend**: Supabase (PostgreSQL + Auth + Realtime + Storage)
- **HTTP Client**: Dio
- **OCR**: Google ML Kit Text Recognition
- **Notifications**: flutter_local_notifications
- **Maps**: flutter_map + OpenStreetMap (leaflet)
- **Local Storage**: shared_preferences
- **UI Utilities**: flutter_animate, timeago

### **Database Schema**
```
profiles (extends auth.users)
├── id (UUID, PK)
├── name, email, avatar_url
└── created_at

scam_messages
├── id (UUID, PK)
├── user_id (FK → profiles)
├── message_text, scam_score, reasons
├── is_reported
└── created_at

scam_numbers
├── id (UUID, PK)
├── phone_number (UNIQUE)
├── scam_type, reported_by (FK)
├── reports_count, region
├── latitude, longitude
└── created_at

community_reports
├── id (UUID, PK)
├── reporter_id (FK → profiles)
├── report_type ('message' | 'number')
├── scam_message_id / scam_number_id (FK)
├── description
└── created_at
```

### **RLS Policies**
- All tables visible to authenticated users
- Users can only insert/update their own records
- Phone number uniqueness enforced via constraint + upsert logic

### **Scam Detection Engine**
Rule-based analysis with weighted keyword scoring:
- **Urgency keywords** (ACT NOW, IMMEDIATELY) — weight 8
- **Financial requests** (bank, transfer, payment) — weight 10
- **Phishing** (verify account, confirm identity) — weight 12
- **Sri Lanka specific** (Rupees, local numbers) — weight 10
- **Suspicious URLs** (shortened links) — weight 15
- **Personal info requests** — weight 10
- **Excessive caps** — weight 5
- **Short message + link** — weight 8

Final score: 0-100 (normalized)

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.10.7+ 
- Dart 3.0+
- Android SDK (API 21+) or iOS 12+
- A Supabase account (free at https://supabase.com)

### 1. Clone & Setup
```bash
git clone <repo-url>
cd scam_radar
flutter pub get
```

### 2. Create Supabase Project
1. Go to https://supabase.com/dashboard
2. Create a new project
3. Go to **SQL Editor** → paste the entire `supabase_schema.sql` and run it
4. Enable **Authentication → Providers → Email** (disable "Confirm email" for development)
5. Create a storage bucket: **Storage → New bucket → "screenshots" (public)**

### 3. Configure Credentials
Update `lib/config/supabase_config.dart`:
```dart
static const String url = 'https://your-ref.supabase.co';
static const String anonKey = 'your-anon-key';
```

Get these from **Supabase Dashboard → Settings → API**

### 4. Fix RPC Functions (if needed)
If you get "Database error saving new user", run this in Supabase SQL Editor:
```sql
-- Drop and recreate trigger with search_path
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, created_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'name', ''),
    COALESCE(NEW.email, ''),
    now()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
```

### 5. Run the App
```bash
flutter run
```

On first launch, you'll need to:
1. Sign up with an email and password
2. Set a name
3. Grant permissions (camera, gallery, notifications)
4. Start analyzing or reporting!

---

## 📖 How to Use

### **Analyze a Message**
1. Open the home screen
2. Paste a suspicious message in the text field
3. Tap **"Analyze Message"** or use **"Scan Screenshot"** for OCR
4. View the scam score and reasons
5. Optionally **Report** to the community

### **Report a Scam Number**
1. Tap the **"Report Number"** card on home
2. Enter the phone number (+94 format)
3. Select scam type (lottery, bank fraud, romance, etc.)
4. Pick the region (optional, for map location)
5. Add a description
6. Tap **"Submit Report"**
7. Number appears on community map instantly

### **View Community Feed**
1. Tap **"Community Feed"** from home
2. See all scam reports with reporter names
3. Filter by type (Messages / Numbers)
4. Pull to refresh for latest alerts

### **Check Scam Map**
1. Tap **"Scam Map"** from home
2. Explore the interactive map of Sri Lanka
3. Tap markers to see report details
4. View legend for scam type colors
5. Refresh to update with latest reports

### **Manage Profile**
1. Tap the **Profile** tab (bottom nav)
2. View your stats and activity
3. Toggle **Dark Mode** / **Notifications**
4. Sign out when done

---

## 🔧 Project Structure

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # Material 3 theming & routing
├── config/
│   ├── supabase_config.dart          # Credentials
│   ├── theme.dart                    # Light/dark themes
│   └── router.dart                   # GoRouter config with guards
├── models/
│   ├── profile.dart
│   ├── scam_message.dart
│   ├── scam_number.dart
│   └── community_report.dart
├── services/
│   ├── auth_service.dart             # Supabase Auth wrapper
│   ├── database_service.dart         # CRUD operations
│   ├── scam_detector.dart            # Rule-based engine
│   ├── ai_scam_service.dart          # Optional AI API integration
│   ├── ocr_service.dart              # Google ML Kit
│   └── notification_service.dart     # Local notifications
├── providers/
│   ├── auth_provider.dart            # Auth state
│   ├── scam_messages_provider.dart   # Message analysis
│   ├── scam_numbers_provider.dart    # Number reporting
│   ├── community_feed_provider.dart  # Live feed + Realtime
│   ├── theme_provider.dart           # Dark mode
│   └── map_provider.dart             # Map data
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── analysis/
│   │   └── message_analysis_screen.dart
│   ├── report/
│   │   └── report_number_screen.dart
│   ├── feed/
│   │   └── community_feed_screen.dart
│   ├── map/
│   │   └── scam_map_screen.dart
│   └── profile/
│       └── profile_screen.dart
├── widgets/
│   ├── app_shell.dart                # Bottom nav layout
│   ├── scam_score_gauge.dart         # Animated circular gauge
│   ├── scam_card.dart                # Report preview card
│   ├── screenshot_scanner.dart       # OCR UI
│   └── loading_overlay.dart
└── utils/
    ├── constants.dart                # Keywords, districts, scam types
    └── validators.dart               # Email, password, phone, message validation

test/
└── widget_test.dart                  # 8 unit tests for ScamDetector
```

---

## 📱 Screenshots & Flows

### **Onboarding**
- Signup screen with name, email, password validation
- Auto-creates profile on successful registration
- Login screen with email/password

### **Home Dashboard**
- Message paste & analysis UI
- Quick action cards (Report Number, Feed, Map)
- Recent scam reports from community
- Pull-to-refresh support
- Dark mode toggle in app bar

### **Message Analyzer**
- Animated scam score gauge (0-100, color-coded)
- Original message display
- Reasons as chips with warning icons
- "Report Message" button with loading state
- "Analyze Another" button

### **Report Screen**
- Phone number field with +94 format validation
- Scam type dropdown (10+ types)
- Region/district dropdown (25 Sri Lankan regions)
- Description text area
- "Previously Reported" indicator
- Success state with checkmark animation

### **Community Feed**
- List of all reports (messages + numbers)
- Filter chips (All, Messages, Numbers)
- Reporter names and timeago timestamps
- Pull-to-refresh
- Empty state when no reports

### **Scam Map**
- Leaflet/OpenStreetMap centered on Sri Lanka
- Colored markers by scam type
- Report count badge on each marker
- Legend overlay
- Tap marker for bottom sheet details
- No API key required

### **Profile Dashboard**
- User avatar, name, email
- Stats cards (messages, numbers, high-risk)
- Dark mode toggle with switch
- Notifications toggle
- About dialog
- Sign out with confirmation

---

## 🧪 Testing

### Run Unit Tests
```bash
flutter test
```

Tests cover the rule-based scam detection engine:
- Clean messages (score 0)
- Urgency keywords (score >30)
- Financial requests (score >30)
- Phishing attempts (score >40)
- Personal info requests (score >30)
- Sri Lanka-specific content (score >20)
- Short message with link (score >20)

---

## 🚀 Production Deployment

### Before Release:
1. **Update app name & package** in `pubspec.yaml` and Android/iOS configs
2. **Generate app icon** (512x512 PNG) → use Flutter Icon Generator
3. **Enable email verification** in Supabase Authentication
4. **Setup Firebase Cloud Messaging** for push notifications
5. **Enable HTTPS** for all API calls
6. **Implement AI API** (optional) for enhanced detection
7. **Test on real devices** (Android 8+, iOS 12+)
8. **Sign APK/IPA** with production keys

### Release Commands:
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'Add your feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

---

## 📋 Future Enhancements

- [ ] AI-powered scam detection via Supabase Edge Functions
- [ ] WhatsApp/SMS integration for real-time analysis
- [ ] User reputation system & trust scores
- [ ] Scam trend analytics & heatmaps
- [ ] Multi-language support (Tamil, Sinhala)
- [ ] Web dashboard for analytics
- [ ] Share reports via social media
- [ ] Offline mode with sync
- [ ] Biometric authentication

---

## 📄 License

This project is licensed under the MIT License — see the LICENSE file for details.

---

## 🆘 Troubleshooting

### Sign Up Fails with "Database error"
→ Run the `handle_new_user` trigger fix in Supabase SQL Editor (see setup section)

### Map Not Loading
→ Check internet permission in AndroidManifest.xml, ensure minSdk ≥ 21

### OCR Crashes on Android
→ Verify `READ_MEDIA_IMAGES` and `CAMERA` permissions are granted

### Notifications Not Working
→ Grant `POST_NOTIFICATIONS` permission (Android 13+), enable in app settings

### State Management Issues
→ Restart the app (`flutter run` restart or press `R` in terminal)

---

## 📞 Support

For issues, feature requests, or questions:
- Open an **Issue** on GitHub
- Email: support@scamradar.lk (if deployed)
- Join our community Discord (TBD)

---

**Built with ❤️ to protect Sri Lankan users from scams.**
