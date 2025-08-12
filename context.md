# Medical Assistant Application Documentation

## Table of Contents
1. [File Structure](#file-structure)
2. [Application Workflow](#application-workflow)
3. [Core Functions](#core-functions)
4. [Missing Functions](#missing-functions)
5. [Duplicate Functions](#duplicate-functions)
6. [Future Functions](#future-functions)

## File Structure

```
medical_assistant_new/
├── lib/
│   ├── l10n/
│   │   ├── app_localizations.dart         # Localization translations
│   │   └── app_localizations_delegate.dart # Localization delegate
│   ├── models/
│   │   ├── agent_model.dart              # Agent appearance configuration
│   │   ├── chat_message_model.dart       # Chat message structure
│   │   └── config_model.dart             # App configuration
│   ├── screens/
│   │   ├── agent_screen.dart             # Agent customization UI
│   │   ├── api_screen.dart               # API configuration UI
│   │   ├── api_settings_screen.dart      # Alternative API settings
│   │   ├── chat_screen.dart              # Main chat interface
│   │   ├── language_screen.dart          # Language selection
│   │   ├── settings_screen.dart          # App settings
│   │   └── subscription_screen.dart       # Premium features
│   ├── theme/
│   │   └── app_theme.dart                # Theme definitions
│   ├── widgets/
│   │   ├── agent_avatar.dart             # Agent avatar component
│   │   └── chat_bubble.dart              # Chat message bubble
│   └── main.dart                         # App entry point
├── backend/
│   ├── app.py                            # Flask application
│   ├── app.wsgi                          # WSGI configuration
│   ├── backend_deploy.sh                 # Deployment script
│   ├── backend_setup.sh                  # Server setup script
│   └── .env                              # Environment variables
└── pubspec.yaml                          # Flutter dependencies

```

## Application Workflow

### Frontend Workflow

1. **Initialization**
   - App starts from `main.dart`
   - Loads configuration from `ConfigService`
   - Sets up localization and theme
   - Initializes navigation

2. **User Authentication**
   - Currently not implemented
   - Future feature for user management

3. **Main Interface**
   - Bottom navigation with 4 sections:
     - Chat
     - Language
     - Settings
     - Agent

4. **Chat Flow**
   - User inputs message
   - Message sent to backend
   - Response received and displayed
   - Optional translation and voice features

5. **Settings Management**
   - Theme selection
   - Language selection
   - API configuration
   - Agent appearance customization

### Backend Workflow

1. **Server Initialization**
   - Loads environment variables
   - Sets up Flask application
   - Configures OpenAI client

2. **Request Processing**
   - Receives chat messages
   - Processes with OpenAI
   - Maintains conversation history
   - Returns structured responses

3. **Deployment Process**
   - Server setup script execution
   - Environment configuration
   - Service installation
   - WSGI configuration

## Core Functions

### Frontend Functions

#### Main App
```dart
void main()                    # App entry point
class MyApp                    # Root widget
class MainScreen              # Main navigation
```

#### Chat Functions
```dart
_handleSubmitted()            # Process user messages
_speak()                      # Text-to-speech
_translateText()              # Message translation
_loadLanguagePreference()     # Load language settings
```

#### Configuration Functions
```dart
loadConfig()                  # Load app configuration
saveConfig()                  # Save app configuration
_updateAppearance()          # Update agent appearance
_testConnection()            # Test API connection
```

#### UI Functions
```dart
build()                      # Build UI components
_buildThemeOption()         # Theme selection UI
_buildAppearanceOption()    # Agent appearance UI
_buildTextComposer()        # Chat input UI
```

### Backend Functions

#### API Endpoints
```python
@app.route("/")              # Root endpoint
@app.route("/health")        # Health check
@app.route("/api/chat")      # Chat processing
```

#### Chat Processing
```python
chat()                       # Main chat handler
clear_conversation()         # Clear chat history
```

## Missing Functions

1. **Authentication**
   - User registration
   - Login/logout
   - Session management

2. **Data Persistence**
   - Local chat history storage
   - User preferences backup
   - Offline mode support

3. **Error Recovery**
   - Automatic reconnection
   - Message retry mechanism
   - State recovery

4. **Analytics**
   - Usage tracking
   - Error reporting
   - Performance monitoring

## Duplicate Functions

1. **API Settings**
   - `api_screen.dart` and `api_settings_screen.dart` have similar functionality
   - Should be consolidated into a single implementation

2. **Configuration Management**
   - Multiple config loading implementations
   - Should be centralized in `ConfigService`

## Future Functions

1. **User Management**
```dart
class UserService {
  Future<void> register();
  Future<void> login();
  Future<void> logout();
  Future<void> resetPassword();
}
```

2. **Data Synchronization**
```dart
class SyncService {
  Future<void> syncChatHistory();
  Future<void> syncPreferences();
  Future<void> syncSubscription();
}
```

3. **Analytics Integration**
```dart
class AnalyticsService {
  void trackEvent();
  void logError();
  void measurePerformance();
}
```

4. **Enhanced Chat Features**
```dart
class ChatService {
  Future<void> attachFile();
  Future<void> shareLocation();
  Future<void> scheduleMessage();
}
```

5. **Security Enhancements**
```dart
class SecurityService {
  Future<void> encryptMessage();
  Future<void> verifyIdentity();
  Future<void> managePermissions();
}
```

## Development Roadmap

1. **Phase 1: Core Functionality**
   - ✅ Basic chat interface
   - ✅ Multiple languages
   - ✅ Theme system
   - ✅ Agent customization

2. **Phase 2: User Management**
   - ⏳ Authentication system
   - ⏳ User profiles
   - ⏳ Data persistence

3. **Phase 3: Enhanced Features**
   - ⏳ File sharing
   - ⏳ Voice messages
   - ⏳ Location sharing

4. **Phase 4: Analytics & Security**
   - ⏳ Usage tracking
   - ⏳ Error reporting
   - ⏳ End-to-end encryption

5. **Phase 5: Optimization**
   - ⏳ Performance improvements
   - ⏳ Code optimization
   - ⏳ UI/UX enhancements 