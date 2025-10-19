-- Migration: Fix Notification Policies and Add Comprehensive Notifications
-- Description: Fixes RLS policies for notifications and ensures proper notification creation

-- Drop existing notification policies
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "System can create notifications" ON public.notifications;

-- Create comprehensive notification policies
CREATE POLICY "Users can view their own notifications" ON public.notifications
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update their own notifications" ON public.notifications
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can create notifications for themselves" ON public.notifications
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "System can create notifications for any user" ON public.notifications
    FOR INSERT WITH CHECK (true);

-- Add function to create notifications for appointment events
CREATE OR REPLACE FUNCTION create_appointment_notification()
RETURNS TRIGGER AS $$
BEGIN
    -- Create notification for salon owner when appointment is created
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.notifications (user_id, type, title, message, data, is_read, created_at)
        SELECT 
            s.owner_id,
            'appointment',
            'New Appointment Request',
            'You have a new appointment request for ' || NEW.start_at::date,
            jsonb_build_object('appointment_id', NEW.id, 'customer_id', NEW.customer_id),
            false,
            NOW()
        FROM public.salons s
        WHERE s.id = NEW.salon_id;
        
        -- Create notification for customer
        INSERT INTO public.notifications (user_id, type, title, message, data, is_read, created_at)
        VALUES (
            NEW.customer_id,
            'appointment',
            'Appointment Requested',
            'Your appointment request has been submitted and is pending confirmation',
            jsonb_build_object('appointment_id', NEW.id),
            false,
            NOW()
        );
    END IF;
    
    -- Create notification when appointment status changes
    IF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
        -- Notify customer about status change
        INSERT INTO public.notifications (user_id, type, title, message, data, is_read, created_at)
        VALUES (
            NEW.customer_id,
            'appointment',
            'Appointment ' || NEW.status,
            'Your appointment has been ' || NEW.status,
            jsonb_build_object('appointment_id', NEW.id, 'status', NEW.status),
            false,
            NOW()
        );
        
        -- Notify salon owner if status is confirmed
        IF NEW.status = 'confirmed' THEN
            INSERT INTO public.notifications (user_id, type, title, message, data, is_read, created_at)
            SELECT 
                s.owner_id,
                'appointment',
                'Appointment Confirmed',
                'Appointment confirmed for ' || NEW.start_at::date,
                jsonb_build_object('appointment_id', NEW.id, 'customer_id', NEW.customer_id),
                false,
                NOW()
            FROM public.salons s
            WHERE s.id = NEW.salon_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for appointment notifications
DROP TRIGGER IF EXISTS appointment_notification_trigger ON public.appointments;
CREATE TRIGGER appointment_notification_trigger
    AFTER INSERT OR UPDATE ON public.appointments
    FOR EACH ROW
    EXECUTE FUNCTION create_appointment_notification();

-- Add function to create notifications for profile updates
CREATE OR REPLACE FUNCTION create_profile_notification()
RETURNS TRIGGER AS $$
BEGIN
    -- Create notification when profile is updated
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO public.notifications (user_id, type, title, message, data, is_read, created_at)
        VALUES (
            NEW.id,
            'system',
            'Profile Updated',
            'Your profile has been successfully updated',
            jsonb_build_object('updated_at', NEW.updated_at),
            false,
            NOW()
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for profile notifications
DROP TRIGGER IF EXISTS profile_notification_trigger ON public.profiles;
CREATE TRIGGER profile_notification_trigger
    AFTER UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION create_profile_notification();

-- Add function to create notifications for salon updates
CREATE OR REPLACE FUNCTION create_salon_notification()
RETURNS TRIGGER AS $$
BEGIN
    -- Create notification when salon is updated
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO public.notifications (user_id, type, title, message, data, is_read, created_at)
        VALUES (
            NEW.owner_id,
            'system',
            'Salon Updated',
            'Your salon information has been updated',
            jsonb_build_object('salon_id', NEW.id, 'updated_at', NEW.updated_at),
            false,
            NOW()
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for salon notifications
DROP TRIGGER IF EXISTS salon_notification_trigger ON public.salons;
CREATE TRIGGER salon_notification_trigger
    AFTER UPDATE ON public.salons
    FOR EACH ROW
    EXECUTE FUNCTION create_salon_notification();

-- Add function to create notifications for new messages
CREATE OR REPLACE FUNCTION create_message_notification()
RETURNS TRIGGER AS $$
BEGIN
    -- Create notification for message receiver
    INSERT INTO public.notifications (user_id, type, title, message, data, is_read, created_at)
    VALUES (
        NEW.receiver_id,
        'message',
        'New Message',
        CASE 
            WHEN LENGTH(NEW.text) > 50 THEN LEFT(NEW.text, 50) || '...'
            ELSE NEW.text
        END,
        jsonb_build_object('message_id', NEW.id, 'sender_id', NEW.sender_id, 'thread_id', NEW.thread_id),
        false,
        NOW()
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for message notifications
DROP TRIGGER IF EXISTS message_notification_trigger ON public.messages;
CREATE TRIGGER message_notification_trigger
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION create_message_notification();

-- Add function to create welcome notification for new users
CREATE OR REPLACE FUNCTION create_welcome_notification()
RETURNS TRIGGER AS $$
BEGIN
    -- Create welcome notification for new user
    INSERT INTO public.notifications (user_id, type, title, message, data, is_read, created_at)
    VALUES (
        NEW.id,
        'system',
        'Welcome to Menz Cut!',
        CASE 
            WHEN NEW.role = 'customer' THEN 'Welcome! Start exploring salons and book your first appointment.'
            WHEN NEW.role = 'salon_owner' THEN 'Welcome! Set up your salon profile and start accepting appointments.'
            ELSE 'Welcome to Menz Cut!'
        END,
        jsonb_build_object('role', NEW.role, 'created_at', NEW.created_at),
        false,
        NOW()
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for welcome notifications
DROP TRIGGER IF EXISTS welcome_notification_trigger ON public.profiles;
CREATE TRIGGER welcome_notification_trigger
    AFTER INSERT ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION create_welcome_notification();
