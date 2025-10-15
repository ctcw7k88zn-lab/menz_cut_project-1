-- Storage bucket creation and policies
-- This file sets up the storage buckets for the salon booking app

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('profile_avatars', 'profile_avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('salon_images', 'salon_images', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('service_images', 'service_images', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('ai_uploads', 'ai_uploads', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

-- Profile avatars policies
CREATE POLICY "Users can upload their own avatar" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'profile_avatars' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can update their own avatar" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'profile_avatars' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own avatar" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'profile_avatars' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Profile avatars are publicly readable" ON storage.objects
  FOR SELECT USING (bucket_id = 'profile_avatars');

-- Salon images policies
CREATE POLICY "Salon owners can upload salon images" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'salon_images' 
    AND EXISTS (
      SELECT 1 FROM salons 
      WHERE owner_id = auth.uid() 
      AND id::text = (storage.foldername(name))[1]
    )
  );

CREATE POLICY "Salon owners can update salon images" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'salon_images' 
    AND EXISTS (
      SELECT 1 FROM salons 
      WHERE owner_id = auth.uid() 
      AND id::text = (storage.foldername(name))[1]
    )
  );

CREATE POLICY "Salon owners can delete salon images" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'salon_images' 
    AND EXISTS (
      SELECT 1 FROM salons 
      WHERE owner_id = auth.uid() 
      AND id::text = (storage.foldername(name))[1]
    )
  );

CREATE POLICY "Salon images are publicly readable" ON storage.objects
  FOR SELECT USING (bucket_id = 'salon_images');

-- Service images policies
CREATE POLICY "Salon owners can upload service images" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'service_images' 
    AND EXISTS (
      SELECT 1 FROM services s
      JOIN salons sal ON s.salon_id = sal.id
      WHERE sal.owner_id = auth.uid() 
      AND s.id::text = (storage.foldername(name))[1]
    )
  );

CREATE POLICY "Salon owners can update service images" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'service_images' 
    AND EXISTS (
      SELECT 1 FROM services s
      JOIN salons sal ON s.salon_id = sal.id
      WHERE sal.owner_id = auth.uid() 
      AND s.id::text = (storage.foldername(name))[1]
    )
  );

CREATE POLICY "Salon owners can delete service images" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'service_images' 
    AND EXISTS (
      SELECT 1 FROM services s
      JOIN salons sal ON s.salon_id = sal.id
      WHERE sal.owner_id = auth.uid() 
      AND s.id::text = (storage.foldername(name))[1]
    )
  );

CREATE POLICY "Service images are publicly readable" ON storage.objects
  FOR SELECT USING (bucket_id = 'service_images');

-- AI uploads policies (private bucket)
CREATE POLICY "Users can upload their own AI images" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'ai_uploads' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view their own AI images" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'ai_uploads' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own AI images" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'ai_uploads' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
