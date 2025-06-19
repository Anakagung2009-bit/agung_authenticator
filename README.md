# Agung Authenticator

A modern two-factor authentication app built with Flutter. This application provides TOTP code generation and secure user verification integrated with Firebase Authentication. It offers a dynamic user experience with light/dark themes and in-app update detection.

------------------------------------------------------------
## Introduction

Agung Authenticator is a cross-platform Flutter app designed to secure your accounts using time-based one-time passwords (TOTP). The application is built with Firebase authentication and supports biometric (local) authentication along with a sleek material design that adapts dynamically to your system theme. The app ensures that sensitive operations like viewing passwords require successful user authentication.

------------------------------------------------------------
## Features

- **TOTP Generation**  
  Create time-based one-time passwords with automatic updates and expiration timers.

- **Secure Authentication**  
  Uses Firebase Authentication along with local device authentication (biometric or PIN) to confirm user identity before granting access to sensitive data.

- **Dynamic Theming**  
  Leverage DynamicColorBuilder and ThemeService to support light, dark, or system default modes for a personalized look.

- **Automatic Update Checking**  
  Integrated update checking notifies users when a new version is available and provides a direct download link via GitHub.

- **User-Friendly Interface**  
  Clean layouts, custom widgets, and interactive elements make it easy to get started.

------------------------------------------------------------
## Requirements

Before running Agung Authenticator, make sure you have the following installed:

- Flutter SDK (compatible with Flutter 3.x or later)
- Dart SDK
- Android Studio or Xcode (for Android/iOS development)
- A configured Firebase project (the repository includes a sample google-services.json configuration)
- Android API level 35 or higher
- Java 11 for Android build (specified in the gradle configuration)

Additional packages and plugins used include:
- Firebase Authentication
- local_auth for biometric authentication
- shared_preferences for persistent storage
- Provider for state management

------------------------------------------------------------
## Installation

To get started with Agung Authenticator, follow these steps:

1. **Clone the Repository**

   Run the following command in your terminal:
   ------------------------------------------------------------
   git clone https://github.com/Anakagung2009-bit/agung_authenticator.git
   ------------------------------------------------------------

2. **Install Dependencies**

   Navigate to the project directory and fetch the dependencies:
   ------------------------------------------------------------
   cd agung_authenticator
   flutter pub get
   ------------------------------------------------------------

3. **Configure Firebase**

   - Replace the sample Firebase configuration in the `android/app/google-services.json` file with your Firebase project settings.
   - For iOS, update the corresponding Firebase configuration files.

4. **Run the Application**

   Start the app on your connected device or emulator:
   ------------------------------------------------------------
   flutter run
   ------------------------------------------------------------

------------------------------------------------------------
## License

This project is licensed under the GNU General Public License version 3.0 (GPL-3.0).

------------------------------------------------------------
## Configuration

Agung Authenticator requires some initial configuration before use. Ensure you update the following settings as necessary:

- **Firebase Settings**  
  Update the Firebase project information in the `android/app/google-services.json` file. For iOS, check your `AppFrameworkInfo.plist` and related files.

- **Build Settings**  
  - Android build configuration requires Java 11 and proper gradle settings (see files such as `android/settings.gradle.kts` and `gradle-wrapper.properties`).
  - For Flutter, update the environment in the `pubspec.yaml` file if necessary.
  
- **Theme and Localization**  
  The app supports dynamic themes. Adjust theme preferences using the in-app settings and ensure that Device DynamicColor is enabled for better visual appearance.

- **Authentication Providers**  
  Check the implementation in `lib/services/auth_check.dart` to ensure you have enabled the desired local authentication methods (biometric, PIN, etc.).

------------------------------------------------------------
## Usage

After installation and configuration, launching Agung Authenticator will bring you to the login screen. The key usage features are:

- **Login and Authentication**  
  Users must sign in using Firebase credentials. After login, accessing password details or other sensitive data prompts a secure local authentication.

- **TOTP Generation and Display**  
  TOTP codes are generated using the TOTPService. The user interface refreshes every 30 seconds (or based on configured expiry) to ensure that codes are always up-to-date. The widget layout (see files like `android/app/src/main/res/layout/totp_widget_layout.xml`) is optimized for clear presentation.

- **Theme Switching**  
  Users can switch between light, dark, or system default themes through the app settings integrated with Provider and DynamicColorBuilder.

- **Updates**  
  Upon app launch, the UpdateService checks for newer versions. If an update is available, a dialog appears with options for downloading the update directly.

Use the on-screen buttons and drawer menus to navigate between screens like the HomeScreen, LoginScreen, and detailed password views.

------------------------------------------------------------
## Contributing

Contributions to Agung Authenticator are welcome. To contribute:

1. Fork the repository on GitHub.
2. Create a new branch for any feature or bug fix.
3. Ensure your code follows the established coding styles and conventions used in the project.
4. Write clear commit messages and document your changes.
5. Submit a pull request with a detailed explanation of your updates. 

Feel free to open issues if you encounter bugs or have suggestions to improve the project.

------------------------------------------------------------
Happy coding! 🚀
