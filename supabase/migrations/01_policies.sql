-- Salon Appointment AI App - Row Level Security Policies
-- This migration enables RLS and creates security policies for all tables
-- Run this via Supabase SQL Editor or psql

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salon_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salon_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_availability ENABLE ROW LEVEL SECURITY;

-- PROFILES POLICIES
-- Users can view and update their own profile
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Admins can view all profiles
CREATE POLICY "Admins can view all profiles" ON public.profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- SALONS POLICIES
-- Anyone can view active salons
CREATE POLICY "Anyone can view active salons" ON public.salons
    FOR SELECT USING (is_active = true);

-- Salon owners can manage their own salons
CREATE POLICY "Salon owners can manage own salons" ON public.salons
    FOR ALL USING (auth.uid() = owner_id);

-- Admins can manage all salons
CREATE POLICY "Admins can manage all salons" ON public.salons
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- SALON STAFF POLICIES
-- Anyone can view active staff
CREATE POLICY "Anyone can view active staff" ON public.salon_staff
    FOR SELECT USING (is_active = true);

-- Salon owners can manage their staff
CREATE POLICY "Salon owners can manage own staff" ON public.salon_staff
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.salons 
            WHERE id = salon_id AND owner_id = auth.uid()
        )
    );

-- Staff members can view their own records
CREATE POLICY "Staff can view own records" ON public.salon_staff
    FOR SELECT USING (auth.uid() = user_id);

-- SERVICES POLICIES
-- Anyone can view active services
CREATE POLICY "Anyone can view active services" ON public.services
    FOR SELECT USING (is_active = true);

-- Salon owners can manage services for their salons
CREATE POLICY "Salon owners can manage own services" ON public.services
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.salons 
            WHERE id = salon_id AND owner_id = auth.uid()
        )
    );

-- Admins can manage all services
CREATE POLICY "Admins can manage all services" ON public.services
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- APPOINTMENTS POLICIES
-- Customers can view their own appointments
CREATE POLICY "Customers can view own appointments" ON public.appointments
    FOR SELECT USING (auth.uid() = customer_id);

-- Customers can create appointments for themselves
CREATE POLICY "Customers can create own appointments" ON public.appointments
    FOR INSERT WITH CHECK (auth.uid() = customer_id);

-- Salon owners can view appointments for their salons
CREATE POLICY "Salon owners can view salon appointments" ON public.appointments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.salons 
            WHERE id = salon_id AND owner_id = auth.uid()
        )
    );

-- Salon owners can update appointments for their salons
CREATE POLICY "Salon owners can update salon appointments" ON public.appointments
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.salons 
            WHERE id = salon_id AND owner_id = auth.uid()
        )
    );

-- Staff can view appointments assigned to them
CREATE POLICY "Staff can view assigned appointments" ON public.appointments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.salon_staff 
            WHERE id = staff_id AND user_id = auth.uid()
        )
    );

-- SALON REVIEWS POLICIES
-- Anyone can view reviews
CREATE POLICY "Anyone can view salon reviews" ON public.salon_reviews
    FOR SELECT USING (true);

-- Customers can create reviews for themselves
CREATE POLICY "Customers can create own reviews" ON public.salon_reviews
    FOR INSERT WITH CHECK (auth.uid() = customer_id);

-- Customers can update their own reviews
CREATE POLICY "Customers can update own reviews" ON public.salon_reviews
    FOR UPDATE USING (auth.uid() = customer_id);

-- SERVICE REVIEWS POLICIES
-- Anyone can view service reviews
CREATE POLICY "Anyone can view service reviews" ON public.service_reviews
    FOR SELECT USING (true);

-- Customers can create service reviews for themselves
CREATE POLICY "Customers can create own service reviews" ON public.service_reviews
    FOR INSERT WITH CHECK (auth.uid() = customer_id);

-- Customers can update their own service reviews
CREATE POLICY "Customers can update own service reviews" ON public.service_reviews
    FOR UPDATE USING (auth.uid() = customer_id);

-- MESSAGES POLICIES
-- Users can view messages where they are sender or receiver
CREATE POLICY "Users can view own messages" ON public.messages
    FOR SELECT USING (
        auth.uid() = sender_id OR auth.uid() = receiver_id
    );

-- Users can send messages
CREATE POLICY "Users can send messages" ON public.messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Users can update their own sent messages
CREATE POLICY "Users can update own sent messages" ON public.messages
    FOR UPDATE USING (auth.uid() = sender_id);

-- AI SUGGESTIONS POLICIES
-- Users can view their own suggestions
CREATE POLICY "Users can view own suggestions" ON public.ai_suggestions
    FOR SELECT USING (auth.uid() = user_id);

-- Users can create suggestions for themselves
CREATE POLICY "Users can create own suggestions" ON public.ai_suggestions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own suggestions
CREATE POLICY "Users can update own suggestions" ON public.ai_suggestions
    FOR UPDATE USING (auth.uid() = user_id);

-- NOTIFICATIONS POLICIES
-- Users can view their own notifications
CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

-- Users can update their own notifications
CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- System can create notifications (for triggers/functions)
CREATE POLICY "System can create notifications" ON public.notifications
    FOR INSERT WITH CHECK (true);

-- PAYMENTS POLICIES
-- Customers can view payments for their appointments
CREATE POLICY "Customers can view own payments" ON public.payments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.appointments 
            WHERE id = appointment_id AND customer_id = auth.uid()
        )
    );

-- Salon owners can view payments for their salon appointments
CREATE POLICY "Salon owners can view salon payments" ON public.payments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.appointments a
            JOIN public.salons s ON a.salon_id = s.id
            WHERE a.id = appointment_id AND s.owner_id = auth.uid()
        )
    );

-- PROMOTIONS POLICIES
-- Anyone can view active promotions
CREATE POLICY "Anyone can view active promotions" ON public.promotions
    FOR SELECT USING (is_active = true AND valid_until > now());

-- Salon owners can manage promotions for their salons
CREATE POLICY "Salon owners can manage own promotions" ON public.promotions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.salons 
            WHERE id = salon_id AND owner_id = auth.uid()
        )
    );

-- USER FAVORITES POLICIES
-- Users can manage their own favorites
CREATE POLICY "Users can manage own favorites" ON public.user_favorites
    FOR ALL USING (auth.uid() = user_id);

-- USER PREFERENCES POLICIES
-- Users can manage their own preferences
CREATE POLICY "Users can manage own preferences" ON public.user_preferences
    FOR ALL USING (auth.uid() = user_id);

-- STAFF AVAILABILITY POLICIES
-- Anyone can view staff availability
CREATE POLICY "Anyone can view staff availability" ON public.staff_availability
    FOR SELECT USING (true);

-- Staff can manage their own availability
CREATE POLICY "Staff can manage own availability" ON public.staff_availability
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.salon_staff 
            WHERE id = staff_id AND user_id = auth.uid()
        )
    );

-- Salon owners can manage availability for their staff
CREATE POLICY "Salon owners can manage staff availability" ON public.staff_availability
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.salon_staff ss
            JOIN public.salons s ON ss.salon_id = s.id
            WHERE ss.id = staff_id AND s.owner_id = auth.uid()
        )
    );

-- Create function to handle profile creation on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'role', 'customer')::user_role
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create function to send notifications on appointment status change
CREATE OR REPLACE FUNCTION public.notify_appointment_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Send notification to customer when status changes
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO public.notifications (user_id, type, title, message, data)
        VALUES (
            NEW.customer_id,
            'appointment',
            'Appointment Status Updated',
            'Your appointment status has been updated to ' || NEW.status,
            jsonb_build_object(
                'appointment_id', NEW.id,
                'old_status', OLD.status,
                'new_status', NEW.status,
                'salon_id', NEW.salon_id
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for appointment status changes
CREATE TRIGGER on_appointment_status_change
    AFTER UPDATE ON public.appointments
    FOR EACH ROW EXECUTE FUNCTION public.notify_appointment_status_change();

-- Create function to send notifications for new messages
CREATE OR REPLACE FUNCTION public.notify_new_message()
RETURNS TRIGGER AS $$
BEGIN
    -- Send notification to receiver
    INSERT INTO public.notifications (user_id, type, title, message, data)
    VALUES (
        NEW.receiver_id,
        'message',
        'New Message',
        'You have a new message from ' || (
            SELECT full_name FROM public.profiles WHERE id = NEW.sender_id
        ),
        jsonb_build_object(
            'message_id', NEW.id,
            'thread_id', NEW.thread_id,
            'sender_id', NEW.sender_id
        )
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new messages
CREATE TRIGGER on_new_message
    AFTER INSERT ON public.messages
    FOR EACH ROW EXECUTE FUNCTION public.notify_new_message();
