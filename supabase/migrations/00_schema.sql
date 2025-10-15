-- Salon Appointment AI App - Database Schema
-- This migration creates all necessary tables, indexes, and views
-- Run this via Supabase SQL Editor or psql

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types
CREATE TYPE user_role AS ENUM ('customer', 'salon_owner', 'admin');
CREATE TYPE appointment_status AS ENUM ('pending', 'confirmed', 'cancelled', 'completed', 'no_show');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'failed', 'refunded');
CREATE TYPE message_status AS ENUM ('sending', 'sent', 'delivered', 'read', 'failed');
CREATE TYPE notification_type AS ENUM ('appointment', 'message', 'promotion', 'system');
CREATE TYPE suggestion_type AS ENUM ('haircut', 'beard', 'styling', 'color');

-- Profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT auth.uid(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    role user_role DEFAULT 'customer',
    phone TEXT,
    avatar_url TEXT,
    is_email_verified BOOLEAN DEFAULT false,
    is_phone_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Salons table
CREATE TABLE IF NOT EXISTS public.salons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    address TEXT,
    city TEXT,
    zip_code TEXT,
    phone TEXT,
    email TEXT,
    logo_url TEXT,
    banner_url TEXT,
    rating NUMERIC(3,2) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
    review_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Salon staff table
CREATE TABLE IF NOT EXISTS public.salon_staff (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salon_id UUID REFERENCES public.salons(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    role TEXT NOT NULL DEFAULT 'stylist',
    specialties TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(salon_id, user_id)
);

-- Services table
CREATE TABLE IF NOT EXISTS public.services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salon_id UUID REFERENCES public.salons(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
    category TEXT,
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Appointments table
CREATE TABLE IF NOT EXISTS public.appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    salon_id UUID REFERENCES public.salons(id) ON DELETE CASCADE NOT NULL,
    service_id UUID REFERENCES public.services(id) ON DELETE CASCADE NOT NULL,
    staff_id UUID REFERENCES public.salon_staff(id) ON DELETE SET NULL,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    status appointment_status DEFAULT 'pending',
    notes TEXT,
    total_price NUMERIC(10,2) DEFAULT 0.0,
    payment_status payment_status DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CHECK (end_at > start_at)
);

-- Salon reviews table
CREATE TABLE IF NOT EXISTS public.salon_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    salon_id UUID REFERENCES public.salons(id) ON DELETE CASCADE NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(customer_id, salon_id)
);

-- Service reviews table
CREATE TABLE IF NOT EXISTS public.service_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    service_id UUID REFERENCES public.services(id) ON DELETE CASCADE NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(customer_id, service_id)
);

-- Messages table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    thread_id UUID NOT NULL,
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    text TEXT NOT NULL,
    attachments JSONB DEFAULT '[]',
    status message_status DEFAULT 'sent',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- AI suggestions table
CREATE TABLE IF NOT EXISTS public.ai_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    suggestion_type suggestion_type NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    content JSONB DEFAULT '{}',
    salon_id UUID REFERENCES public.salons(id) ON DELETE SET NULL,
    service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
    image_url TEXT,
    confidence_score DECIMAL(3,2) DEFAULT 0.0,
    tags TEXT[] DEFAULT '{}',
    is_booked BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    type notification_type NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Payments table
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    appointment_id UUID REFERENCES public.appointments(id) ON DELETE CASCADE NOT NULL,
    amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    currency TEXT DEFAULT 'USD',
    method TEXT NOT NULL,
    status payment_status DEFAULT 'pending',
    transaction_id TEXT,
    payment_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Promotions table
CREATE TABLE IF NOT EXISTS public.promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salon_id UUID REFERENCES public.salons(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    discount_percentage DECIMAL(5,2) CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    discount_amount NUMERIC(10,2) CHECK (discount_amount >= 0),
    min_order_amount NUMERIC(10,2) DEFAULT 0,
    max_uses INTEGER,
    used_count INTEGER DEFAULT 0,
    valid_from TIMESTAMPTZ NOT NULL,
    valid_until TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    CHECK (valid_until > valid_from)
);

-- User favorites table
CREATE TABLE IF NOT EXISTS public.user_favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    salon_id UUID REFERENCES public.salons(id) ON DELETE CASCADE,
    service_id UUID REFERENCES public.services(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, salon_id),
    UNIQUE(user_id, service_id),
    CHECK (salon_id IS NOT NULL OR service_id IS NOT NULL)
);

-- User preferences table
CREATE TABLE IF NOT EXISTS public.user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL UNIQUE,
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Staff availability table
CREATE TABLE IF NOT EXISTS public.staff_availability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    staff_id UUID REFERENCES public.salon_staff(id) ON DELETE CASCADE NOT NULL,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CHECK (end_time > start_time)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

CREATE INDEX IF NOT EXISTS idx_salons_owner_id ON public.salons(owner_id);
CREATE INDEX IF NOT EXISTS idx_salons_city ON public.salons(city);
CREATE INDEX IF NOT EXISTS idx_salons_is_active ON public.salons(is_active);
CREATE INDEX IF NOT EXISTS idx_salons_rating ON public.salons(rating);

CREATE INDEX IF NOT EXISTS idx_services_salon_id ON public.services(salon_id);
CREATE INDEX IF NOT EXISTS idx_services_category ON public.services(category);
CREATE INDEX IF NOT EXISTS idx_services_is_active ON public.services(is_active);
CREATE INDEX IF NOT EXISTS idx_services_price ON public.services(price);

CREATE INDEX IF NOT EXISTS idx_appointments_customer_id ON public.appointments(customer_id);
CREATE INDEX IF NOT EXISTS idx_appointments_salon_id ON public.appointments(salon_id);
CREATE INDEX IF NOT EXISTS idx_appointments_service_id ON public.appointments(service_id);
CREATE INDEX IF NOT EXISTS idx_appointments_staff_id ON public.appointments(staff_id);
CREATE INDEX IF NOT EXISTS idx_appointments_start_at ON public.appointments(start_at);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON public.appointments(status);

CREATE INDEX IF NOT EXISTS idx_messages_thread_id ON public.messages(thread_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at);

CREATE INDEX IF NOT EXISTS idx_ai_suggestions_user_id ON public.ai_suggestions(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_suggestions_type ON public.ai_suggestions(suggestion_type);

-- Create helpful views
CREATE OR REPLACE VIEW public.salon_details AS
SELECT 
    s.*,
    p.full_name as owner_name,
    p.email as owner_email,
    p.phone as owner_phone,
    COUNT(DISTINCT sr.id) as total_reviews,
    AVG(sr.rating) as avg_rating
FROM public.salons s
LEFT JOIN public.profiles p ON s.owner_id = p.id
LEFT JOIN public.salon_reviews sr ON s.id = sr.salon_id
WHERE s.is_active = true
GROUP BY s.id, p.full_name, p.email, p.phone;

CREATE OR REPLACE VIEW public.service_details AS
SELECT 
    s.*,
    sal.name as salon_name,
    sal.address as salon_address,
    sal.city as salon_city,
    COUNT(DISTINCT ser.id) as total_reviews,
    AVG(ser.rating) as avg_rating
FROM public.services s
LEFT JOIN public.salons sal ON s.salon_id = sal.id
LEFT JOIN public.service_reviews ser ON s.id = ser.service_id
WHERE s.is_active = true AND sal.is_active = true
GROUP BY s.id, sal.name, sal.address, sal.city;

CREATE OR REPLACE VIEW public.appointment_details AS
SELECT 
    a.*,
    c.full_name as customer_name,
    c.email as customer_email,
    c.phone as customer_phone,
    sal.name as salon_name,
    sal.address as salon_address,
    ser.name as service_name,
    ser.price as service_price,
    ser.duration_minutes as service_duration,
    st.user_id as staff_user_id,
    st.role as staff_role
FROM public.appointments a
LEFT JOIN public.profiles c ON a.customer_id = c.id
LEFT JOIN public.salons sal ON a.salon_id = sal.id
LEFT JOIN public.services ser ON a.service_id = ser.id
LEFT JOIN public.salon_staff st ON a.staff_id = st.id;

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_salons_updated_at BEFORE UPDATE ON public.salons FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_services_updated_at BEFORE UPDATE ON public.services FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_salon_staff_updated_at BEFORE UPDATE ON public.salon_staff FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON public.user_preferences FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_staff_availability_updated_at BEFORE UPDATE ON public.staff_availability FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Create function to update salon rating when reviews change
CREATE OR REPLACE FUNCTION public.update_salon_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.salons 
    SET 
        rating = (
            SELECT COALESCE(AVG(rating), 0.0) 
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
    FOR EACH ROW EXECUTE FUNCTION public.update_salon_rating();

CREATE TRIGGER update_salon_rating_on_review_update 
    AFTER UPDATE ON public.salon_reviews 
    FOR EACH ROW EXECUTE FUNCTION public.update_salon_rating();

CREATE TRIGGER update_salon_rating_on_review_delete 
    AFTER DELETE ON public.salon_reviews 
    FOR EACH ROW EXECUTE FUNCTION public.update_salon_rating();
