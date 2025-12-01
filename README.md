# Salon Appointment App

A premium Flutter application for salon appointments with glassmorphism design, AI hair suggestions, and real-time chat functionality.

## Features

### Customer Features
- 🏪 **Salon Discovery**: Find and explore salons with ratings, reviews, and photos
- 📅 **Easy Booking**: Book appointments with preferred stylists
- 🤖 **AI Hair Suggestions**: Get personalized hair style recommendations
- 💬 **Real-time Chat**: Communicate with salon staff
- 📱 **Responsive Design**: Works on mobile and desktop
- 🔔 **Notifications**: Stay updated with appointment reminders

### Salon Owner Features
- 📊 **Analytics Dashboard**: Track business performance
- 📋 **Appointment Management**: Manage bookings and schedules
- 💬 **Customer Communication**: Chat with customers
- 🛠️ **Service Management**: Add and manage services
- 📈 **Business Insights**: Revenue and customer analytics

## Tech Stack

- **Framework**: Flutter 3.0+
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **UI Design**: Glassmorphism with custom theme
- **Image Caching**: Cached Network Image
- **Animations**: Lottie animations
- **Charts**: FL Chart
- **Configuration**: Flutter Dotenv

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code
- Chrome browser (for web development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd menz_cut_project
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` file with your configuration:
   ```env
   APP_API_BASE_URL=http://localhost:3000
   APP_ENABLE_MOCK=true
   APP_GOOGLE_MAPS_API_KEY=your_api_key_here
   APP_ENVIRONMENT=development
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

4. **Run the app**
   ```bash
   # For web (Chrome)
   flutter run -d chrome
   
   # For mobile emulator
   flutter run
   
   # For specific device
   flutter devices
   flutter run -d <device-id>
   ```

## Project Structure

```
lib/
├── config/                 # App configuration
│   ├── app_theme.dart     # Glassmorphism theme system
│   └── app_env.dart       # Environment variables
├── models/                # Data models
│   ├── user_model.dart
│   ├── salon_model.dart
│   ├── service_model.dart
│   ├── appointment_model.dart
│   ├── message_model.dart
│   ├── notification_model.dart
│   └── ai_suggestion_model.dart
├── services/              # API and utility services
│   ├── app_api.dart       # Main API interface
│   └── image_cache_service.dart
├── providers/             # Riverpod state management
│   ├── auth_provider.dart
│   ├── salons_provider.dart
│   ├── services_provider.dart
│   ├── appointments_provider.dart
│   ├── chat_provider.dart
│   ├── notifications_provider.dart
│   └── ai_provider.dart
├── widgets/               # Reusable UI components
│   ├── glass_card.dart
│   ├── salon_card.dart
│   ├── service_tile.dart
│   ├── animated_button.dart
│   ├── search_bar.dart
│   ├── rating_stars.dart
│   ├── lottie_loader.dart
│   └── chat_bubble.dart
├── screens/               # App screens
│   ├── auth/             # Authentication screens
│   ├── customer/         # Customer portal
│   ├── owner/            # Salon owner portal
│   └── shared/           # Shared screens
└── main.dart             # App entry point
```

## Configuration

### Mock Data Mode

The app runs with mock data by default. To toggle between mock and real API:

1. **Enable Mock Mode** (default):
   ```env
   APP_ENABLE_MOCK=true
   ```

2. **Disable Mock Mode** (for backend integration):
   ```env
   APP_ENABLE_MOCK=false
   ```

### Google Maps Integration

To enable map functionality:

1. Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Add the key to your `.env` file:
   ```env
   APP_GOOGLE_MAPS_API_KEY=your_actual_api_key_here
   ```

## Demo Script

### 1. Onboarding & Authentication
- Launch the app
- Go through the 3-slide onboarding
- Select "I'm a Customer" or "I'm a Salon Owner"
- Sign up with test credentials
- Verify successful login

### 2. Customer Experience
- Browse featured salons on home screen
- Use search functionality
- Tap on salon cards to view details
- Try the AI hair suggestions feature
- Book an appointment
- Check appointment status

### 3. Salon Owner Experience
- View dashboard with today's appointments
- Manage pending appointment approvals
- Access quick actions (Services, Analytics)
- Review appointment statistics

### 4. Chat & Notifications
- Send messages in chat interface
- Receive real-time notifications
- Test notification interactions

### 5. Responsive Design
- Test on different screen sizes
- Verify mobile and desktop layouts
- Check glassmorphism effects

## Development

### Code Generation

Run code generation for models:
```bash
flutter packages pub run build_runner build
```

### Testing

Run tests:
```bash
flutter test
```

### Linting

Check code quality:
```bash
flutter analyze
```

## Backend Integration

When ready to connect to a real backend:

1. **Update AppApi**: Modify `lib/services/app_api.dart` to implement real API calls
2. **Environment Variables**: Set `APP_ENABLE_MOCK=false` in `.env`
3. **API Endpoints**: Update `APP_API_BASE_URL` with your backend URL
4. **Authentication**: Implement JWT or session-based auth
5. **Real-time Features**: Add WebSocket connections for chat and notifications

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Check the documentation
- Review the demo script for usage examples

---

**Note**: This is a frontend-only implementation with mock data. Backend integration is required for production use.
