-- Migration: Create RLS Policies
-- Description: Sets up Row Level Security policies for all tables

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salon_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view all profiles" ON public.profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Salons policies
CREATE POLICY "Anyone can view active salons" ON public.salons
    FOR SELECT USING (is_active = true);

CREATE POLICY "Salon owners can manage their salons" ON public.salons
    FOR ALL USING (owner_id = auth.uid());

CREATE POLICY "Admins can manage all salons" ON public.salons
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Services policies
CREATE POLICY "Anyone can view active services" ON public.services
    FOR SELECT USING (is_active = true);

CREATE POLICY "Salon owners can manage services for their salons" ON public.services
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.salons 
            WHERE salons.id = services.salon_id AND salons.owner_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage all services" ON public.services
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Staff policies
CREATE POLICY "Anyone can view active staff" ON public.staff
    FOR SELECT USING (is_active = true);

CREATE POLICY "Salon owners can manage staff for their salons" ON public.staff
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.salons 
            WHERE salons.id = staff.salon_id AND salons.owner_id = auth.uid()
        )
    );

CREATE POLICY "Staff can view their own profile" ON public.staff
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Admins can manage all staff" ON public.staff
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Staff services policies
CREATE POLICY "Anyone can view staff services" ON public.staff_services
    FOR SELECT USING (true);

CREATE POLICY "Salon owners can manage staff services" ON public.staff_services
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.staff s
            JOIN public.salons sal ON sal.id = s.salon_id
            WHERE s.id = staff_services.staff_id AND sal.owner_id = auth.uid()
        )
    );

-- Appointments policies
CREATE POLICY "Users can view their own appointments" ON public.appointments
    FOR SELECT USING (customer_id = auth.uid());

CREATE POLICY "Salon owners can view appointments for their salons" ON public.appointments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.salons 
            WHERE salons.id = appointments.salon_id AND salons.owner_id = auth.uid()
        )
    );

CREATE POLICY "Staff can view appointments for their salons" ON public.appointments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.staff s
            JOIN public.salons sal ON sal.id = s.salon_id
            WHERE s.id = appointments.staff_id AND s.user_id = auth.uid()
        )
    );

CREATE POLICY "Customers can create appointments" ON public.appointments
    FOR INSERT WITH CHECK (customer_id = auth.uid());

CREATE POLICY "Salon owners can update appointments for their salons" ON public.appointments
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.salons 
            WHERE salons.id = appointments.salon_id AND salons.owner_id = auth.uid()
        )
    );

CREATE POLICY "Staff can update appointments assigned to them" ON public.appointments
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.staff s
            JOIN public.salons sal ON sal.id = s.salon_id
            WHERE s.id = appointments.staff_id AND s.user_id = auth.uid()
        )
    );

CREATE POLICY "Customers can cancel their own appointments" ON public.appointments
    FOR UPDATE USING (customer_id = auth.uid());

CREATE POLICY "Admins can manage all appointments" ON public.appointments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Messages policies
CREATE POLICY "Users can view messages they sent or received" ON public.messages
    FOR SELECT USING (sender_id = auth.uid() OR receiver_id = auth.uid());

CREATE POLICY "Users can send messages" ON public.messages
    FOR INSERT WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Users can update their own messages" ON public.messages
    FOR UPDATE USING (sender_id = auth.uid());

-- Salon reviews policies
CREATE POLICY "Anyone can view salon reviews" ON public.salon_reviews
    FOR SELECT USING (true);

CREATE POLICY "Customers can create reviews for their appointments" ON public.salon_reviews
    FOR INSERT WITH CHECK (
        customer_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.appointments 
            WHERE appointments.id = salon_reviews.appointment_id 
            AND appointments.customer_id = auth.uid()
            AND appointments.status = 'completed'
        )
    );

CREATE POLICY "Customers can update their own reviews" ON public.salon_reviews
    FOR UPDATE USING (customer_id = auth.uid());

CREATE POLICY "Customers can delete their own reviews" ON public.salon_reviews
    FOR DELETE USING (customer_id = auth.uid());

-- Service reviews policies
CREATE POLICY "Anyone can view service reviews" ON public.service_reviews
    FOR SELECT USING (true);

CREATE POLICY "Customers can create reviews for their appointments" ON public.service_reviews
    FOR INSERT WITH CHECK (
        customer_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.appointments 
            WHERE appointments.id = service_reviews.appointment_id 
            AND appointments.customer_id = auth.uid()
            AND appointments.status = 'completed'
        )
    );

CREATE POLICY "Customers can update their own reviews" ON public.service_reviews
    FOR UPDATE USING (customer_id = auth.uid());

CREATE POLICY "Customers can delete their own reviews" ON public.service_reviews
    FOR DELETE USING (customer_id = auth.uid());

-- Notifications policies
CREATE POLICY "Users can view their own notifications" ON public.notifications
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update their own notifications" ON public.notifications
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "System can create notifications" ON public.notifications
    FOR INSERT WITH CHECK (true);

-- AI suggestions policies
CREATE POLICY "Users can view their own suggestions" ON public.ai_suggestions
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update their own suggestions" ON public.ai_suggestions
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "System can create suggestions" ON public.ai_suggestions
    FOR INSERT WITH CHECK (true);

-- Payments policies
CREATE POLICY "Users can view payments for their appointments" ON public.payments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.appointments 
            WHERE appointments.id = payments.appointment_id 
            AND appointments.customer_id = auth.uid()
        )
    );

CREATE POLICY "Salon owners can view payments for their salon appointments" ON public.payments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.appointments a
            JOIN public.salons s ON s.id = a.salon_id
            WHERE a.id = payments.appointment_id AND s.owner_id = auth.uid()
        )
    );

CREATE POLICY "System can create payments" ON public.payments
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can manage all payments" ON public.payments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Favorites policies
CREATE POLICY "Users can view their own favorites" ON public.favorites
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own favorites" ON public.favorites
    FOR ALL USING (user_id = auth.uid());

-- Promotions policies
CREATE POLICY "Anyone can view active promotions" ON public.promotions
    FOR SELECT USING (is_active = true AND end_date > NOW());

CREATE POLICY "Salon owners can manage promotions for their salons" ON public.promotions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.salons 
            WHERE salons.id = promotions.salon_id AND salons.owner_id = auth.uid()
        )
    );

-- Staff availability policies
CREATE POLICY "Anyone can view staff availability" ON public.staff_availability
    FOR SELECT USING (true);

CREATE POLICY "Salon owners can manage staff availability" ON public.staff_availability
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.staff s
            JOIN public.salons sal ON sal.id = s.salon_id
            WHERE s.id = staff_availability.staff_id AND sal.owner_id = auth.uid()
        )
    );

CREATE POLICY "Staff can manage their own availability" ON public.staff_availability
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.staff 
            WHERE staff.id = staff_availability.staff_id AND staff.user_id = auth.uid()
        )
    );

-- User preferences policies
CREATE POLICY "Users can view their own preferences" ON public.user_preferences
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own preferences" ON public.user_preferences
    FOR ALL USING (user_id = auth.uid());
