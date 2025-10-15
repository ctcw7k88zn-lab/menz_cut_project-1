# Frontend-Only Salon Appointment System

This document describes the frontend-only implementation of the salon appointment system with Riverpod state management, local persistence, and realtime simulation.

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.9.2 or higher
- Dart SDK 3.9.2 or higher

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

3. **Generate code (if needed)**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── config/                 # App configuration
├── models/                 # Data models with Hive annotations
├── providers/              # Riverpod providers for state management
│   ├── *_enhanced.dart    # Enhanced providers using AsyncNotifier
│   └── *.dart             # Original providers
├── screens/               # UI screens
├── services/              # Core services
│   ├── app_api.dart       # API facade (local/backend switch)
│   ├── local_data_service.dart  # Hive persistence
│   └── realtime_service.dart    # Realtime simulation
└── widgets/               # Reusable UI components

assets/
└── mock_data/             # Seed data for local storage
    ├── services.json
    ├── appointments.json
    ├── messages.json
    ├── notifications.json
    └── salons.json

test/
├── providers/             # Unit tests for providers
└── widgets/              # Widget tests for realtime interactions
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the project root:

```env
# Realtime simulation
APP_SIMULATE_REALTIME=true

# AI API (optional)
GEMINI_API_KEY=your_gemini_api_key_here

# Mock mode
ENABLE_MOCK=true
```

### Toggle Realtime Simulation

Set `APP_SIMULATE_REALTIME=false` in `.env` to disable network delays and realtime simulation.

## 🏗️ Architecture

### State Management
- **Riverpod**: Primary state management solution
- **AsyncNotifier**: Enhanced providers with proper error handling
- **AsyncValue**: Consistent loading/error states across the app

### Local Persistence
- **Hive**: NoSQL database for local storage
- **Automatic seeding**: Initial data loaded from `assets/mock_data/`
- **Type-safe**: All models have Hive annotations

### Realtime Simulation
- **StreamController**: Broadcast streams for realtime updates
- **Network delays**: Configurable delays to simulate real backend
- **Event-driven**: All actions emit updates via streams

## 📊 Data Models

### Service Model
```dart
class ServiceModel {
  final String id;
  final String salonId;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;  // Duration in minutes
  final String category;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Appointment Model
```dart
class AppointmentModel {
  final String id;
  final String salonId;
  final String serviceId;
  final String customerId;
  final String? staffId;
  final DateTime startAt;     // Start time
  final DateTime endAt;       // End time (calculated)
  final AppointmentStatus status;
  final PaymentStatus paymentStatus;
  final double totalAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Message Model
```dart
class MessageModel {
  final String id;
  final String threadId;
  final String senderId;
  final String receiverId;
  final String text;
  final List<String> attachments;
  final MessageStatus status;
  final DateTime createdAt;
}
```

### Notification Model
```dart
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
}
```

## 🔄 Real Interactions

### 1. Owner adds a service → instantly visible to customers
```dart
// Owner adds service
final newService = ServiceModel(
  id: uuid.v4(),
  salonId: currentOwner.salonId,
  name: 'New Service',
  // ... other fields
);

await servicesProvider.addService(newService);
// → Saves to Hive
// → Emits via realtime_service
// → Customers see it immediately
```

### 2. Customer books appointment → owner sees it
```dart
// Customer books appointment
final appointment = await appointmentsProvider.bookAppointment(
  customerId: 'customer_1',
  salonId: 'salon_1',
  serviceId: 'service_1',
  startAt: DateTime.now().add(Duration(hours: 1)),
);
// → Creates appointment with status 'pending'
// → Saves to Hive
// → Emits via realtime_service
// → Owner sees pending appointment
```

### 3. Owner approves appointment → customer gets notification
```dart
// Owner approves
await appointmentsProvider.updateAppointmentStatus(
  appointmentId,
  AppointmentStatus.confirmed,
);
// → Updates status in Hive
// → Emits via realtime_service
// → Customer gets notification
// → Both parties see updated status
```

### 4. Chat between customer & owner
```dart
// Send message
await chatProvider.sendMessage(
  threadId: 'thread_customer_1_owner_1',
  senderId: 'customer_1',
  receiverId: 'owner_1',
  text: 'Hello!',
);
// → Saves message with status 'sending'
// → Emits via realtime_service
// → Receiver gets message
// → Status updates to 'sent' then 'read'
```

## 🧪 Testing

### Run Unit Tests
```bash
flutter test
```

### Run Specific Test Files
```bash
flutter test test/providers/services_provider_test.dart
flutter test test/providers/appointments_provider_test.dart
flutter test test/providers/chat_provider_test.dart
flutter test test/widgets/realtime_interactions_test.dart
```

### Test Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 🔄 Switching to Real Backend

### Step 1: Update AppApi Configuration
```dart
// In lib/services/app_api.dart
class AppApi {
  static bool useLocal = false; // Change to false
  // ... rest of the code
}
```

### Step 2: Implement Backend Methods
Replace all `throw UnimplementedError()` with actual HTTP calls:

```dart
// Example: Real backend implementation
static Future<List<ServiceModel>> getServices() async {
  if (useLocal) {
    // ... existing local implementation
  } else {
    // TODO: Replace with real backend call
    final response = await http.get(
      Uri.parse('$baseUrl/api/services'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ServiceModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load services');
    }
  }
}
```

### Step 3: Update Environment Variables
```env
# Backend configuration
API_BASE_URL=https://your-api.com
API_KEY=your_api_key
```

### Step 4: Replace Realtime Service
Replace `RealtimeService` with real WebSocket or Server-Sent Events:

```dart
class RealtimeService {
  late WebSocketChannel _channel;
  
  void connect() {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://your-api.com/ws'),
    );
    
    _channel.stream.listen((data) {
      final event = jsonDecode(data);
      // Handle realtime events
    });
  }
}
```

## 🛠️ Development Commands

### Reset Local Data
```dart
// In your app or test
await LocalDataService.resetData();
```

### Clear Hive Storage
```bash
flutter clean
flutter pub get
# This will reset all local data
```

### Generate Hive Adapters
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## 📱 Demo Credentials

### Customer Account
- **Email**: `customer@example.com`
- **Password**: `password`

### Owner Account
- **Email**: `owner@example.com`
- **Password**: `password`

## 🐛 Troubleshooting

### Common Issues

1. **Hive adapter not found**
   ```bash
   flutter packages pub run build_runner build
   ```

2. **Mock data not loading**
   - Check `assets/mock_data/` files exist
   - Verify JSON format is valid
   - Run `flutter clean` and rebuild

3. **Realtime updates not working**
   - Check `APP_SIMULATE_REALTIME=true` in `.env`
   - Verify providers are listening to streams
   - Check console for errors

4. **Tests failing**
   - Run `flutter test --verbose` for detailed output
   - Check mock setup in test files
   - Verify all dependencies are installed

### Debug Mode
```dart
// Enable debug logging
void main() {
  // Add this for detailed logging
  debugPrint = (String? message, {int? wrapWidth}) {
    if (kDebugMode) {
      print('DEBUG: $message');
    }
  };
  
  runApp(MyApp());
}
```

## 📈 Performance Considerations

### Local Storage
- Hive is optimized for mobile performance
- Data is stored in binary format
- Automatic compression for large datasets

### Realtime Updates
- Streams use broadcast mode for multiple listeners
- Configurable delays prevent UI flooding
- Automatic cleanup of disposed streams

### Memory Management
- Providers automatically dispose when not in use
- Hive boxes are lazy-loaded
- Stream subscriptions are properly managed

## 🔒 Security Notes

### Local Storage
- Hive data is stored in app sandbox
- No sensitive data should be stored locally
- Consider encryption for production use

### API Security
- All API calls should use HTTPS
- Implement proper authentication
- Validate all input data

## 📚 Additional Resources

- [Riverpod Documentation](https://riverpod.dev/)
- [Hive Documentation](https://docs.hivedb.dev/)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [AsyncValue Best Practices](https://riverpod.dev/docs/concepts/reading#asyncvalue)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
