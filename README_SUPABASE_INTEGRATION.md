# Salon Appointment AI App - Supabase Backend Integration

This document provides complete instructions for setting up and running the Salon Appointment AI app with Supabase backend integration.

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.0+)
- Supabase CLI (optional, for local development)
- Node.js (for Edge Functions)

### 1. Environment Setup

Create a `.env` file in the project root:

```bash
# Supabase Configuration
SUPABASE_URL=http://127.0.0.1:54323/project/default
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU

# App Configuration
APP_API_BASE_URL=http://127.0.0.1:54323/project/default
APP_ENABLE_MOCK=false
APP_ENVIRONMENT=development
APP_GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

### 2. Database Setup

Run the following SQL migrations in your Supabase SQL Editor:

#### Step 1: Create Schema
```sql
-- Run supabase/migrations/00_schema.sql
-- This creates all tables, indexes, and triggers
```

#### Step 2: Enable RLS Policies
```sql
-- Run supabase/migrations/01_policies.sql
-- This enables Row Level Security and creates policies
```

#### Step 3: Insert Seed Data
```sql
-- Run supabase/migrations/02_seed.sql
-- This inserts sample data for testing
```

### 3. Storage Buckets

The following storage buckets are automatically created:

- `profile-pics` - User profile pictures (public read)
- `salon-images` - Salon photos (public read)
- `service-images` - Service photos (public read)
- `ai-uploads` - AI analysis images (private)

### 4. Edge Functions

Deploy the Edge Functions:

```bash
# Deploy AI Style Suggestion function
supabase functions deploy ai_style_suggestion

# Deploy Send Notification function
supabase functions deploy send_notification
```

### 5. Run the App

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run -d chrome
```

## 📊 Database Schema

### Core Tables

#### profiles
- `id` (uuid, primary key) - References auth.users.id
- `email` (text, unique)
- `full_name` (text)
- `role` (enum: customer, salon_owner, admin)
- `phone` (text)
- `avatar_url` (text)
- `is_email_verified` (boolean)
- `is_phone_verified` (boolean)
- `created_at` (timestamptz)
- `updated_at` (timestamptz)

#### salons
- `id` (uuid, primary key)
- `owner_id` (uuid) - References profiles.id
- `name` (text)
- `description` (text)
- `address` (text)
- `city` (text)
- `phone` (text)
- `email` (text)
- `logo_url` (text)
- `banner_url` (text)
- `rating` (numeric)
- `review_count` (integer)
- `is_active` (boolean)
- `latitude` (decimal)
- `longitude` (decimal)
- `created_at` (timestamptz)
- `updated_at` (timestamptz)

#### services
- `id` (uuid, primary key)
- `salon_id` (uuid) - References salons.id
- `name` (text)
- `description` (text)
- `price` (numeric)
- `duration_minutes` (integer)
- `category` (text)
- `image_url` (text)
- `is_active` (boolean)
- `created_at` (timestamptz)
- `updated_at` (timestamptz)

#### appointments
- `id` (uuid, primary key)
- `customer_id` (uuid) - References profiles.id
- `salon_id` (uuid) - References salons.id
- `service_id` (uuid) - References services.id
- `staff_id` (uuid) - References salon_staff.id
- `start_at` (timestamptz)
- `end_at` (timestamptz)
- `status` (enum: pending, confirmed, cancelled, completed, no_show)
- `notes` (text)
- `total_price` (numeric)
- `payment_status` (enum: pending, paid, failed, refunded)
- `created_at` (timestamptz)
- `updated_at` (timestamptz)

#### messages
- `id` (uuid, primary key)
- `thread_id` (uuid)
- `sender_id` (uuid) - References profiles.id
- `receiver_id` (uuid) - References profiles.id
- `text` (text)
- `attachments` (jsonb)
- `status` (enum: sending, sent, delivered, read, failed)
- `is_read` (boolean)
- `created_at` (timestamptz)

#### ai_suggestions
- `id` (uuid, primary key)
- `user_id` (uuid) - References profiles.id
- `suggestion_type` (enum: haircut, beard, styling, color)
- `title` (text)
- `description` (text)
- `content` (jsonb)
- `salon_id` (uuid) - References salons.id
- `service_id` (uuid) - References services.id
- `image_url` (text)
- `confidence_score` (decimal)
- `tags` (text[])
- `is_booked` (boolean)
- `created_at` (timestamptz)

#### notifications
- `id` (uuid, primary key)
- `user_id` (uuid) - References profiles.id
- `type` (enum: appointment, message, promotion, system)
- `title` (text)
- `message` (text)
- `data` (jsonb)
- `is_read` (boolean)
- `created_at` (timestamptz)

## 🔐 Row Level Security (RLS)

All tables have RLS enabled with the following policies:

### Profiles
- Users can view/update only their own profile
- Admins can view all profiles

### Salons
- Anyone can view active salons
- Salon owners can manage their own salons
- Admins can manage all salons

### Services
- Anyone can view active services
- Salon owners can manage services for their salons
- Admins can manage all services

### Appointments
- Customers can view/create their own appointments
- Salon owners can view/update appointments for their salons
- Staff can view appointments assigned to them

### Messages
- Users can view messages where they are sender or receiver
- Users can send messages

### AI Suggestions
- Users can view/create/update their own suggestions

### Notifications
- Users can view/update their own notifications
- System can create notifications

## 🔄 Real-time Features

The app uses Supabase Realtime for:

- **Appointments**: Live updates when status changes
- **Messages**: Real-time chat between users
- **Notifications**: Instant notification delivery
- **Services**: Live updates when services are added/modified

## 📱 App Features

### Authentication
- ✅ Signup with email, password, name, phone, and role
- ✅ Login with email and password
- ✅ Session persistence
- ✅ Password reset
- ✅ Profile management

### Customer Portal
- ✅ Browse salons and services
- ✅ Book appointments
- ✅ Chat with salon owners
- ✅ View appointment history
- ✅ Leave reviews
- ✅ AI hair suggestions
- ✅ Profile management

### Salon Owner Portal
- ✅ Manage salon information
- ✅ Add/edit/delete services
- ✅ View and manage appointments
- ✅ Chat with customers
- ✅ View analytics dashboard
- ✅ Manage staff
- ✅ Upload images

### Admin Features
- ✅ View all users, salons, and appointments
- ✅ Manage system-wide settings

## 🧪 Testing

### Test Users

The seed data includes these test accounts:

#### Salon Owners
- Email: `owner1@salon.com` | Password: `password123`
- Email: `owner2@salon.com` | Password: `password123`
- Email: `owner3@salon.com` | Password: `password123`

#### Customers
- Email: `customer1@example.com` | Password: `password123`
- Email: `customer2@example.com` | Password: `password123`
- Email: `customer3@example.com` | Password: `password123`
- Email: `customer4@example.com` | Password: `password123`

### Test Scenarios

1. **Signup Flow**
   - Create new customer account
   - Create new salon owner account
   - Verify profile creation

2. **Salon Management**
   - Login as salon owner
   - Add new service
   - Upload service image
   - Edit salon information

3. **Appointment Booking**
   - Login as customer
   - Browse salons
   - Book appointment
   - Verify owner sees appointment

4. **Real-time Chat**
   - Customer sends message
   - Owner receives message instantly
   - Both can view conversation history

5. **AI Suggestions**
   - Upload photo as customer
   - Generate AI suggestions
   - View suggestions in database

## 🚨 Troubleshooting

### Common Issues

1. **Supabase Connection Failed**
   - Check `.env` file exists and has correct values
   - Verify Supabase instance is running
   - Check network connectivity

2. **Authentication Errors**
   - Ensure RLS policies are properly set up
   - Check if user exists in `auth.users` table
   - Verify profile record exists

3. **Real-time Not Working**
   - Check if Realtime is enabled in Supabase
   - Verify RLS policies allow access
   - Check browser console for errors

4. **File Upload Issues**
   - Verify storage buckets exist
   - Check storage policies
   - Ensure file size is within limits

### Debug Mode

Enable debug logging by setting:
```bash
APP_ENVIRONMENT=development
```

## 📈 Performance

### Database Indexes
- Profiles: email, role
- Salons: owner_id, city, is_active, rating
- Services: salon_id, category, is_active, price
- Appointments: customer_id, salon_id, service_id, start_at, status
- Messages: thread_id, sender_id, receiver_id, created_at
- Notifications: user_id, is_read, created_at

### Optimization Tips
- Use pagination for large lists
- Implement proper caching
- Optimize image sizes before upload
- Use database views for complex queries

## 🔧 Development

### Adding New Features

1. **Database Changes**
   - Create migration file in `supabase/migrations/`
   - Update RLS policies if needed
   - Test with seed data

2. **API Changes**
   - Update `SupabaseService` methods
   - Update `AppApi` facade
   - Update providers if needed

3. **UI Changes**
   - Update providers to use new data
   - Update UI components
   - Test real-time updates

### Code Structure

```
lib/
├── config/           # App configuration
├── models/           # Data models
├── providers/        # Riverpod providers
├── screens/          # UI screens
├── services/         # Backend services
└── widgets/          # Reusable widgets

supabase/
├── functions/        # Edge Functions
└── migrations/       # Database migrations
```

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review Supabase documentation
3. Check Flutter logs for errors
4. Verify environment variables

---

**🎉 Your Salon Appointment AI app is now fully integrated with Supabase backend!**