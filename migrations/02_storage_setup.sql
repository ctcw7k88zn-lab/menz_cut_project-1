-- Migration: Setup Storage Buckets and Policies
-- Description: Creates storage buckets and their access policies

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) VALUES
('profile-pics', 'profile-pics', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
('salon-images', 'salon-images', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
('service-images', 'service-images', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

-- Create storage policies for profile-pics bucket
CREATE POLICY "Anyone can view profile pictures" ON storage.objects
FOR SELECT USING (bucket_id = 'profile-pics');

CREATE POLICY "Authenticated users can upload profile pictures" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'profile-pics' AND 
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can update their own profile pictures" ON storage.objects
FOR UPDATE USING (
    bucket_id = 'profile-pics' AND 
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can delete their own profile pictures" ON storage.objects
FOR DELETE USING (
    bucket_id = 'profile-pics' AND 
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Create storage policies for salon-images bucket
CREATE POLICY "Anyone can view salon images" ON storage.objects
FOR SELECT USING (bucket_id = 'salon-images');

CREATE POLICY "Salon owners can upload salon images" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'salon-images' AND 
    auth.role() = 'authenticated' AND
    EXISTS (
        SELECT 1 FROM public.salons 
        WHERE salons.id::text = (storage.foldername(name))[1] 
        AND salons.owner_id = auth.uid()
    )
);

CREATE POLICY "Salon owners can update their salon images" ON storage.objects
FOR UPDATE USING (
    bucket_id = 'salon-images' AND 
    auth.role() = 'authenticated' AND
    EXISTS (
        SELECT 1 FROM public.salons 
        WHERE salons.id::text = (storage.foldername(name))[1] 
        AND salons.owner_id = auth.uid()
    )
);

CREATE POLICY "Salon owners can delete their salon images" ON storage.objects
FOR DELETE USING (
    bucket_id = 'salon-images' AND 
    auth.role() = 'authenticated' AND
    EXISTS (
        SELECT 1 FROM public.salons 
        WHERE salons.id::text = (storage.foldername(name))[1] 
        AND salons.owner_id = auth.uid()
    )
);

-- Create storage policies for service-images bucket
CREATE POLICY "Anyone can view service images" ON storage.objects
FOR SELECT USING (bucket_id = 'service-images');

CREATE POLICY "Salon owners can upload service images" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'service-images' AND 
    auth.role() = 'authenticated' AND
    EXISTS (
        SELECT 1 FROM public.services s
        JOIN public.salons sal ON sal.id = s.salon_id
        WHERE s.id::text = (storage.foldername(name))[1] 
        AND sal.owner_id = auth.uid()
    )
);

CREATE POLICY "Salon owners can update their service images" ON storage.objects
FOR UPDATE USING (
    bucket_id = 'service-images' AND 
    auth.role() = 'authenticated' AND
    EXISTS (
        SELECT 1 FROM public.services s
        JOIN public.salons sal ON sal.id = s.salon_id
        WHERE s.id::text = (storage.foldername(name))[1] 
        AND sal.owner_id = auth.uid()
    )
);

CREATE POLICY "Salon owners can delete their service images" ON storage.objects
FOR DELETE USING (
    bucket_id = 'service-images' AND 
    auth.role() = 'authenticated' AND
    EXISTS (
        SELECT 1 FROM public.services s
        JOIN public.salons sal ON sal.id = s.salon_id
        WHERE s.id::text = (storage.foldername(name))[1] 
        AND sal.owner_id = auth.uid()
    )
);
