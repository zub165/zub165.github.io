# Medical Assistant Flutter App

A Flutter application for the medical assistant chatbot that connects to the erchatagent backend API.

**Current Version: 1.0.5+3**

## Getting Started

This project is a Flutter application that provides a mobile interface for the medical chatbot assistant with a freemium subscription model.

### Prerequisites

- Flutter SDK (latest version)
- Android Studio or Xcode for building native apps
- Active backend API server

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies
4. Connect to a device or emulator
5. Run `flutter run` to start the application

## Subscription Model

The app uses a freemium model with the following tiers:

### Free Tier
- **8 messages per month** (reduced from 15 to encourage subscriptions)
- Basic medical information
- Standard response time

### Premium Tier ($6.99/month)
- **50 messages per month** (increased from 35)
- Priority response time
- Advanced symptom analysis
- Personalized health insights
- Medical term explanations
- Multi-language support
- Voice interaction
- Chat history export
- Detailed health reports
- Medication reminders
- Health tracking features

## API Configuration

The app connects to the backend API specified in `lib/config.dart`. Update this file to point to your production API when deploying:

```dart
// Change this URL to your production API endpoint
static const String prodApiUrl = 'https://your-production-domain.com/api/chat';

// Set to false for production builds
static const bool isDevelopment = false;
```

## Building for App Stores

### Android (Google Play)

1. Update the `android/app/build.gradle` file with your application ID and version
2. Create a keystore for signing the app:
   ```
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
3. Configure signing in `android/app/build.gradle` and `android/key.properties`
4. Build the app bundle:
   ```
   flutter build appbundle
   ```
5. The app bundle will be created at `build/app/outputs/bundle/release/app-release.aab`
6. Upload this bundle to the Google Play Console

### iOS (App Store)

1. Update the Bundle Identifier in Xcode
2. Configure app signing with your Apple Developer account
3. Build the iOS app:
   ```
   flutter build ios
   ```
4. Open the generated Xcode project:
   ```
   open ios/Runner.xcworkspace
   ```
5. In Xcode, select Product > Archive to create an archive
6. Use the Xcode Organizer to upload the archive to App Store Connect

## Features

- Real-time chat interface with the medical assistant
- Session management for conversation history
- Clear conversation option
- Error handling and network connectivity checks
- Responsive UI for various device sizes
- **New**: Visual message counter with premium indicators
- **New**: Enhanced subscription prompts when running low on messages
- **New**: Improved premium subscription UI with gradient design
- **New**: Better monetization with reduced free tier limits

## Version History

### v1.0.5+3 (Latest)
- **Fixed chat scrolling issue** - messages now appear in correct order
- **Added auto-scroll behavior** - view automatically scrolls to show new messages
- **Improved message visibility** - all messages are now properly visible
- **Enhanced user experience** - smooth scrolling animations
- Reduced free tier from 15 to 8 messages per month
- Increased premium tier from 35 to 50 messages per month
- Added visual message counter widget
- Enhanced subscription prompts
- Improved premium subscription UI
- Updated dependencies to latest versions
- Added new premium features (health reports, medication reminders)

### v1.0.4+2
- Reduced free tier from 15 to 8 messages per month
- Increased premium tier from 35 to 50 messages per month
- Added visual message counter widget
- Enhanced subscription prompts
- Improved premium subscription UI
- Updated dependencies to latest versions
- Added new premium features (health reports, medication reminders)

### v1.0.3+1
- Initial release with basic freemium model
- 15 free messages per month
- 35 premium messages per month

## Testing

Run tests with:

```
flutter test
```

## Troubleshooting

- **API Connection Issues**: Ensure the backend server is running and accessible. For testing on physical devices, use your computer's local network IP instead of localhost.
- **iOS Network Errors**: Verify that `NSAppTransportSecurity` is properly configured in `Info.plist`.
- **Android Network Errors**: Check that the `INTERNET` permission is in the `AndroidManifest.xml`.
- **Subscription Issues**: Ensure in-app purchase is properly configured for both platforms.

## Deployment Checklist

Before submitting to app stores:

1. Update app version and build number
2. Set `isDevelopment = false` in Config
3. Use a production API URL
4. Test on real devices
5. Prepare privacy policy
6. Create app store screenshots and descriptions
7. Set up app store listing information
8. **New**: Configure in-app purchase products in App Store Connect and Google Play Console
9. **New**: Test subscription flow on both platforms

# Flask API

This is a Flask-based API project.

## Setup Instructions

1. Clone the repository
2. Copy `.env.example` to `.env` and update with your configuration values:
   ```
   cp .env.example .env
   ```
3. Install dependencies:
   ```
   pip install -r requirements.txt
   ```
4. Run the application:
   ```
   flask run
   ```
   
The server will start on the port specified in your `.env` file (default: 5001).

## Configuration

All configuration is managed through environment variables in the `.env` file:

- `OPENAI_API_KEY`: Your OpenAI API key
- `FLASK_APP`: The Flask application entry point
- `FLASK_DEBUG`: Enable/disable debug mode
- `PORT`: The port to run the server on
