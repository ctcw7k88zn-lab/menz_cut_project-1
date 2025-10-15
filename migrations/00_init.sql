-- Migration: Create Salon App Schema
-- Description: Creates all tables, indexes, triggers, and functions for the salon booking app

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types
CREATE TYPE user_role AS ENUM ('customer', 'salon_owner', 'staff', 'admin');
CREATE TYPE appointment_status AS ENUM ('pending', 'confirmed', 'cancelled', 'completed', 'no_show');
CREATE TYPE message_status AS ENUM ('sending', 'sent', 'delivered', 'read');
CREATE TYPE notification_type AS ENUM ('appointment', 'message', 'review', 'promotion', 'system');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE payment_method AS ENUM ('card', 'cash', 'bank_transfer', 'wallet');
CREATE TYPE suggestion_type AS ENUM ('hairstyle', 'color', 'treatment', 'accessory');

-- Profiles table (extends auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'customer',
    phone TEXT,
    avatar_url TEXT,
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_phone_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Salons table
CREATE TABLE public.salons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    zip_code TEXT,
    phone TEXT,
    email TEXT,
    logo_url TEXT,
    banner_url TEXT,
    rating NUMERIC(3,2) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
    review_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Services table
CREATE TABLE public.services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
    category TEXT NOT NULL,
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Staff table
CREATE TABLE public.staff (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    specialties TEXT[],
    bio TEXT,
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(salon_id, user_id)
);

-- Staff services (many-to-many)
CREATE TABLE public.staff_services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    staff_id UUID NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(staff_id, service_id)
);

-- Appointments table
CREATE TABLE public.appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
    staff_id UUID REFERENCES public.staff(id) ON DELETE SET NULL,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    status appointment_status DEFAULT 'pending',
    notes TEXT,
    total_price NUMERIC(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK (end_at > start_at)
);

-- Messages table
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    thread_id UUID NOT NULL DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    text TEXT,
    attachments JSONB,
    status message_status DEFAULT 'sent',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Salon reviews table
CREATE TABLE public.salon_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(salon_id, customer_id, appointment_id)
);

-- Service reviews table
CREATE TABLE public.service_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(service_id, customer_id, appointment_id)
);

-- Notifications table
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI suggestions table
CREATE TABLE public.ai_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    suggestion_type suggestion_type NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    content JSONB,
    salon_id UUID REFERENCES public.salons(id) ON DELETE SET NULL,
    service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
    confidence_score NUMERIC(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),
    image_url TEXT,
    tags TEXT[],
    is_booked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payments table
CREATE TABLE public.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    appointment_id UUID NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
    amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    currency TEXT DEFAULT 'USD',
    method payment_method NOT NULL,
    status payment_status DEFAULT 'pending',
    transaction_id TEXT,
    payment_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Favorites table
CREATE TABLE public.favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    salon_id UUID REFERENCES public.salons(id) ON DELETE CASCADE,
    service_id UUID REFERENCES public.services(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK ((salon_id IS NOT NULL AND service_id IS NULL) OR (salon_id IS NULL AND service_id IS NOT NULL))
);

-- Promotions table
CREATE TABLE public.promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    discount_percentage NUMERIC(5,2) CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    discount_amount NUMERIC(10,2) CHECK (discount_amount >= 0),
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK (end_date > start_date)
);

-- Staff availability table
CREATE TABLE public.staff_availability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    staff_id UUID NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK (end_time > start_time)
);

-- User preferences table
CREATE TABLE public.user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    preferences JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Create indexes for better performance
CREATE INDEX idx_profiles_email ON public.profiles(email);
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_salons_owner_id ON public.salons(owner_id);
CREATE INDEX idx_salons_city ON public.salons(city);
CREATE INDEX idx_salons_active ON public.salons(is_active);
CREATE INDEX idx_services_salon_id ON public.services(salon_id);
CREATE INDEX idx_services_category ON public.services(category);
CREATE INDEX idx_services_active ON public.services(is_active);
CREATE INDEX idx_staff_salon_id ON public.staff(salon_id);
CREATE INDEX idx_staff_user_id ON public.staff(user_id);
CREATE INDEX idx_appointments_customer_id ON public.appointments(customer_id);
CREATE INDEX idx_appointments_salon_id ON public.appointments(salon_id);
CREATE INDEX idx_appointments_service_id ON public.appointments(service_id);
CREATE INDEX idx_appointments_start_at ON public.appointments(start_at);
CREATE INDEX idx_appointments_status ON public.appointments(status);
CREATE INDEX idx_messages_thread_id ON public.messages(thread_id);
CREATE INDEX idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX idx_messages_receiver_id ON public.messages(receiver_id);
CREATE INDEX idx_messages_created_at ON public.messages(created_at);
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX idx_ai_suggestions_user_id ON public.ai_suggestions(user_id);
CREATE INDEX idx_payments_appointment_id ON public.payments(appointment_id);
CREATE INDEX idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX idx_promotions_salon_id ON public.promotions(salon_id);
CREATE INDEX idx_promotions_active ON public.promotions(is_active);
CREATE INDEX idx_staff_availability_staff_id ON public.staff_availability(staff_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_salons_updated_at BEFORE UPDATE ON public.salons FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_services_updated_at BEFORE UPDATE ON public.services FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_staff_updated_at BEFORE UPDATE ON public.staff FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_salon_reviews_updated_at BEFORE UPDATE ON public.salon_reviews FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_service_reviews_updated_at BEFORE UPDATE ON public.service_reviews FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_promotions_updated_at BEFORE UPDATE ON public.promotions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_staff_availability_updated_at BEFORE UPDATE ON public.staff_availability FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON public.user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update salon rating when reviews change
CREATE OR REPLACE FUNCTION update_salon_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.salons 
    SET 
        rating = (
            SELECT COALESCE(AVG(rating), 0)
            FROM public.salon_reviews 
            WHERE salon_id = COALESCE(NEW.salon_id, OLD.salon_id)
        ),
        review_count = (
            SELECT COUNT(*)
            FROM public.salon_reviews 
            WHERE salon_id = COALESCE(NEW.salon_id, OLD.salon_id)
        )
    WHERE id = COALESCE(NEW.salon_id, OLD.salon_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

-- Add triggers for salon rating updates
CREATE TRIGGER update_salon_rating_on_review_insert
    AFTER INSERT ON public.salon_reviews
    FOR EACH ROW EXECUTE FUNCTION update_salon_rating();

CREATE TRIGGER update_salon_rating_on_review_update
    AFTER UPDATE ON public.salon_reviews
    FOR EACH ROW EXECUTE FUNCTION update_salon_rating();

CREATE TRIGGER update_salon_rating_on_review_delete
    AFTER DELETE ON public.salon_reviews
    FOR EACH ROW EXECUTE FUNCTION update_salon_rating();
