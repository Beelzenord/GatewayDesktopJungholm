# Flutter Gateway App with Supabase

A Flutter desktop application (Windows & macOS) that serves as a gateway with Supabase authentication.

## Features

- 🔐 Email/Password authentication
- 📧 User registration and login
- 🔑 Password reset functionality
- 👤 User profile display
- 🚪 Secure sign out
- 🖥️ Native desktop experience for Windows and macOS

## Prerequisites

- Flutter SDK (>=3.0.0) with desktop support enabled
- Dart SDK
- A Supabase project (already configured)
- **For Windows:** Visual Studio 2019 or later with "Desktop development with C++" workload
- **For macOS:** Xcode 12 or later

## Setup Instructions

1. **Enable desktop support (if not already enabled):**
   ```bash
   flutter config --enable-windows-desktop
   flutter config --enable-macos-desktop
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   # For Windows
   flutter run -d windows
   
   # For macOS
   flutter run -d macos
   ```

4. **Build release versions:**
   ```bash
   # Windows
   flutter build windows
   
   # macOS
   flutter build macos
   ```

## Project Structure

```
lib/
├── config/
│   └── supabase_config.dart    # Supabase configuration
├── services/
│   └── auth_service.dart        # Authentication service
├── screens/
│   ├── login_screen.dart        # Login/Signup screen
│   └── home_screen.dart         # Home screen (post-login)
└── main.dart                    # App entry point
```

## Supabase Configuration

The app is configured with:
- **Project URL:** https://qthjpkuutaiuuofzrabk.supabase.co
- **Project ID:** qthjpkuutaiuuofzrabk

Configuration is stored in `lib/config/supabase_config.dart`.

## Authentication Flow

1. User opens the app
2. If not authenticated, login screen is shown
3. User can sign in or create a new account
4. After successful authentication, home screen is displayed
5. User can sign out from the home screen

## Notes

- Make sure email confirmation is configured in your Supabase project settings
- The app uses Supabase's built-in authentication system
- All authentication state is managed automatically by Supabase

