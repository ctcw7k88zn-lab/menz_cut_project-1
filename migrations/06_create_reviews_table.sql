-- Migration: Create Reviews Table
-- Description: Creates the reviews table with proper relationships and constraints

-- Create reviews table
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT NOT NULL CHECK (length(comment) >= 10),
    images TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure unique review per customer per salon
    UNIQUE(customer_id, salon_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_reviews_salon_id ON public.reviews(salon_id);
CREATE INDEX IF NOT EXISTS idx_reviews_customer_id ON public.reviews(customer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON public.reviews(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON public.reviews(rating);

-- Enable RLS
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view all reviews" ON public.reviews
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own reviews" ON public.reviews
    FOR INSERT WITH CHECK (customer_id = auth.uid());

CREATE POLICY "Users can update their own reviews" ON public.reviews
    FOR UPDATE USING (customer_id = auth.uid());

CREATE POLICY "Users can delete their own reviews" ON public.reviews
    FOR DELETE USING (customer_id = auth.uid());

-- Create function to update salon rating and review count
CREATE OR REPLACE FUNCTION update_salon_rating_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update salon rating and review count
    UPDATE public.salons 
    SET 
        rating = (
            SELECT COALESCE(AVG(rating), 0)
            FROM public.reviews 
            WHERE salon_id = COALESCE(NEW.salon_id, OLD.salon_id)
        ),
        review_count = (
            SELECT COUNT(*)
            FROM public.reviews 
            WHERE salon_id = COALESCE(NEW.salon_id, OLD.salon_id)
        )
    WHERE id = COALESCE(NEW.salon_id, OLD.salon_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers to automatically update salon stats
DROP TRIGGER IF EXISTS update_salon_stats_on_review_insert ON public.reviews;
CREATE TRIGGER update_salon_stats_on_review_insert
    AFTER INSERT ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_salon_rating_stats();

DROP TRIGGER IF EXISTS update_salon_stats_on_review_update ON public.reviews;
CREATE TRIGGER update_salon_stats_on_review_update
    AFTER UPDATE ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_salon_rating_stats();

DROP TRIGGER IF EXISTS update_salon_stats_on_review_delete ON public.reviews;
CREATE TRIGGER update_salon_stats_on_review_delete
    AFTER DELETE ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_salon_rating_stats();

-- Create function to validate review eligibility
CREATE OR REPLACE FUNCTION can_customer_review_salon(p_customer_id UUID, p_salon_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if customer has already reviewed this salon
    IF EXISTS (
        SELECT 1 FROM public.reviews 
        WHERE customer_id = p_customer_id AND salon_id = p_salon_id
    ) THEN
        RETURN FALSE;
    END IF;
    
    -- Check if customer has completed appointments with this salon
    IF EXISTS (
        SELECT 1 FROM public.appointments 
        WHERE customer_id = p_customer_id 
        AND salon_id = p_salon_id 
        AND status = 'completed'
    ) THEN
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get review statistics
CREATE OR REPLACE FUNCTION get_salon_review_stats(p_salon_id UUID)
RETURNS TABLE(
    average_rating NUMERIC,
    total_reviews BIGINT,
    rating_distribution JSONB
) AS $$
DECLARE
    avg_rating NUMERIC;
    total_count BIGINT;
    distribution JSONB;
BEGIN
    SELECT 
        COALESCE(AVG(rating), 0),
        COUNT(*)
    INTO avg_rating, total_count
    FROM public.reviews
    WHERE salon_id = p_salon_id;
    
    -- Build rating distribution
    SELECT jsonb_build_object(
        '5', COALESCE((SELECT COUNT(*) FROM public.reviews WHERE salon_id = p_salon_id AND rating = 5), 0),
        '4', COALESCE((SELECT COUNT(*) FROM public.reviews WHERE salon_id = p_salon_id AND rating = 4), 0),
        '3', COALESCE((SELECT COUNT(*) FROM public.reviews WHERE salon_id = p_salon_id AND rating = 3), 0),
        '2', COALESCE((SELECT COUNT(*) FROM public.reviews WHERE salon_id = p_salon_id AND rating = 2), 0),
        '1', COALESCE((SELECT COUNT(*) FROM public.reviews WHERE salon_id = p_salon_id AND rating = 1), 0)
    ) INTO distribution;
    
    RETURN QUERY SELECT avg_rating, total_count, distribution;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create notification trigger for new reviews
CREATE OR REPLACE FUNCTION create_review_notification()
RETURNS TRIGGER AS $$
DECLARE
    owner_id UUID;
    customer_name TEXT;
    salon_name TEXT;
BEGIN
    -- Get salon owner ID
    SELECT s.owner_id INTO owner_id FROM public.salons s WHERE s.id = NEW.salon_id;
    
    -- Get customer name
    SELECT p.full_name INTO customer_name FROM public.profiles p WHERE p.id = NEW.customer_id;
    
    -- Get salon name
    SELECT s.name INTO salon_name FROM public.salons s WHERE s.id = NEW.salon_id;
    
    -- Create notification for salon owner
    PERFORM create_notification_for_user(
        owner_id,
        'newReview',
        'New Review Received',
        customer_name || ' left a ' || NEW.rating || '-star review for ' || salon_name || '.',
        jsonb_build_object('review_id', NEW.id, 'salon_id', NEW.salon_id, 'customer_id', NEW.customer_id, 'rating', NEW.rating)
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for review notifications
DROP TRIGGER IF EXISTS review_notification_trigger ON public.reviews;
CREATE TRIGGER review_notification_trigger
    AFTER INSERT ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION create_review_notification();

-- Add updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_reviews_updated_at ON public.reviews;
CREATE TRIGGER update_reviews_updated_at
    BEFORE UPDATE ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert some sample reviews for testing
INSERT INTO public.reviews (customer_id, salon_id, rating, comment, images) VALUES
    ('d9984233-93ad-46f7-97b1-8ac3e8b0ef29', '84d17cc2-ec2d-4d97-8479-0bd540853c12', 5, 'Amazing service! The staff was very professional and the haircut exceeded my expectations. Will definitely come back!', '{}'),
    ('d9984233-93ad-46f7-97b1-8ac3e8b0ef29', '84d17cc2-ec2d-4d97-8479-0bd540853c12', 4, 'Good experience overall. The salon is clean and the stylist was friendly. The only downside was the wait time.', '{}'),
    ('d9984233-93ad-46f7-97b1-8ac3e8b0ef29', '84d17cc2-ec2d-4d97-8479-0bd540853c12', 5, 'Perfect haircut! I will definitely come back again. Highly recommended! The atmosphere is great too.', '{}')
ON CONFLICT (customer_id, salon_id) DO NOTHING;
