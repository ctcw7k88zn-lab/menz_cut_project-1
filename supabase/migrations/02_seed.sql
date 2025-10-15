-- Salon Appointment AI App - Seed Data
-- This migration inserts sample data for development and testing
-- Run this via Supabase SQL Editor or psql

-- Insert sample profiles (these will be created when users sign up)
-- For now, we'll create some test profiles with deterministic UUIDs

-- Sample salon owners
INSERT INTO public.profiles (id, email, full_name, role, phone, is_email_verified, is_phone_verified)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'owner1@salon.com', 'Ahmed Khan', 'salon_owner', '+92 300 1234567', true, true),
    ('22222222-2222-2222-2222-222222222222', 'owner2@salon.com', 'Sarah Johnson', 'salon_owner', '+92 301 2345678', true, true),
    ('33333333-3333-3333-3333-333333333333', 'owner3@salon.com', 'Muhammad Ali', 'salon_owner', '+92 302 3456789', true, true)
ON CONFLICT (id) DO NOTHING;

-- Sample customers
INSERT INTO public.profiles (id, email, full_name, role, phone, is_email_verified, is_phone_verified)
VALUES 
    ('44444444-4444-4444-4444-444444444444', 'customer1@example.com', 'John Doe', 'customer', '+92 303 4567890', true, true),
    ('55555555-5555-5555-5555-555555555555', 'customer2@example.com', 'Jane Smith', 'customer', '+92 304 5678901', true, true),
    ('66666666-6666-6666-6666-666666666666', 'customer3@example.com', 'Ali Hassan', 'customer', '+92 305 6789012', true, true),
    ('77777777-7777-7777-7777-777777777777', 'customer4@example.com', 'Fatima Ahmed', 'customer', '+92 306 7890123', true, true)
ON CONFLICT (id) DO NOTHING;

-- Sample salons
INSERT INTO public.salons (id, owner_id, name, description, address, city, zip_code, phone, email, logo_url, banner_url, rating, review_count, is_active, latitude, longitude)
VALUES 
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Elite Hair Studio', 'Premium hair salon offering cutting-edge styles and professional services.', '123 Main Street', 'Bahawalpur', '63100', '+92 300 1234567', 'info@elitehair.com', 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400', 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=800', 4.8, 120, true, 29.3931, 71.6821),
    
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'Modern Cuts', 'Your go-to destination for modern hairstyles and beard grooming.', '456 Oak Avenue', 'Bahawalpur', '63100', '+92 301 2345678', 'hello@moderncuts.com', 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400', 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800', 4.5, 85, true, 29.3931, 71.6821),
    
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333333', 'Royal Barber Shop', 'Traditional barber shop with modern amenities and expert barbers.', '789 Pine Road', 'Bahawalpur', '63100', '+92 302 3456789', 'contact@royalbarber.com', 'https://images.unsplash.com/photo-1621605815971-fa8b5fc82a63?w=400', 'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800', 4.7, 95, true, 29.3931, 71.6821)
ON CONFLICT (id) DO NOTHING;

-- Sample salon staff
INSERT INTO public.salon_staff (id, salon_id, user_id, role, specialties, is_active)
VALUES 
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'owner', ARRAY['Haircut', 'Styling', 'Coloring'], true),
    ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'owner', ARRAY['Haircut', 'Beard', 'Facial'], true),
    ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333333', 'owner', ARRAY['Traditional Cut', 'Beard', 'Mustache'], true)
ON CONFLICT (id) DO NOTHING;

-- Sample services
INSERT INTO public.services (id, salon_id, name, description, price, duration_minutes, category, image_url, is_active)
VALUES 
    -- Elite Hair Studio services
    ('gggggggg-gggg-gggg-gggg-gggggggggggg', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Classic Haircut', 'A timeless haircut for all hair types and lengths.', 25.00, 45, 'Haircut', 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400', true),
    ('hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Beard Trim', 'Professional beard grooming and shaping.', 15.00, 30, 'Beard', 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400', true),
    ('iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Hair Styling', 'Professional hair styling for special occasions.', 35.00, 60, 'Styling', 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400', true),
    ('jjjjjjjj-jjjj-jjjj-jjjj-jjjjjjjjjjjj', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Hair Coloring', 'Professional hair coloring and highlights.', 50.00, 90, 'Coloring', 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400', true),
    
    -- Modern Cuts services
    ('kkkkkkkk-kkkk-kkkk-kkkk-kkkkkkkkkkkk', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Fade Haircut', 'Modern fade style haircut.', 30.00, 60, 'Haircut', 'https://images.unsplash.com/photo-1621605815971-fa8b5fc82a63?w=400', true),
    ('llllllll-llll-llll-llll-llllllllllll', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Beard Styling', 'Complete beard styling and grooming.', 20.00, 45, 'Beard', 'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=400', true),
    ('mmmmmmmm-mmmm-mmmm-mmmm-mmmmmmmmmmmm', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Facial Treatment', 'Deep cleansing facial treatment.', 40.00, 75, 'Facial', 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400', true),
    
    -- Royal Barber Shop services
    ('nnnnnnnn-nnnn-nnnn-nnnn-nnnnnnnnnnnn', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Traditional Cut', 'Classic barber shop haircut.', 20.00, 40, 'Haircut', 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400', true),
    ('oooooooo-oooo-oooo-oooo-oooooooooooo', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Mustache Trim', 'Professional mustache trimming.', 10.00, 20, 'Mustache', 'https://images.unsplash.com/photo-1621605815971-fa8b5fc82a63?w=400', true)
ON CONFLICT (id) DO NOTHING;

-- Sample appointments
INSERT INTO public.appointments (id, customer_id, salon_id, service_id, staff_id, start_at, end_at, status, notes, total_price, payment_status)
VALUES 
    ('pppppppp-pppp-pppp-pppp-pppppppppppp', '44444444-4444-4444-4444-444444444444', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'gggggggg-gggg-gggg-gggg-gggggggggggg', 'dddddddd-dddd-dddd-dddd-dddddddddddd', '2024-01-15 10:00:00+00', '2024-01-15 10:45:00+00', 'confirmed', 'Regular haircut, please trim the sides', 25.00, 'paid'),
    
    ('qqqqqqqq-qqqq-qqqq-qqqq-qqqqqqqqqqqq', '55555555-5555-5555-5555-555555555555', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'kkkkkkkk-kkkk-kkkk-kkkk-kkkkkkkkkkkk', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '2024-01-15 14:00:00+00', '2024-01-15 15:00:00+00', 'pending', 'Fade haircut with beard trim', 50.00, 'pending'),
    
    ('rrrrrrrr-rrrr-rrrr-rrrr-rrrrrrrrrrrr', '66666666-6666-6666-6666-666666666666', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'nnnnnnnn-nnnn-nnnn-nnnn-nnnnnnnnnnnn', 'ffffffff-ffff-ffff-ffff-ffffffffffff', '2024-01-16 09:00:00+00', '2024-01-16 09:40:00+00', 'completed', 'Traditional cut, very satisfied', 20.00, 'paid'),
    
    ('ssssssss-ssss-ssss-ssss-ssssssssssss', '77777777-7777-7777-7777-777777777777', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii', 'dddddddd-dddd-dddd-dddd-dddddddddddd', '2024-01-16 16:00:00+00', '2024-01-16 17:00:00+00', 'confirmed', 'Wedding hair styling', 35.00, 'paid')
ON CONFLICT (id) DO NOTHING;

-- Sample salon reviews
INSERT INTO public.salon_reviews (id, customer_id, salon_id, rating, review_text)
VALUES 
    ('tttttttt-tttt-tttt-tttt-tttttttttttt', '44444444-4444-4444-4444-444444444444', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 5, 'Excellent service! Ahmed is very professional and skilled. Highly recommended!'),
    ('uuuuuuuu-uuuu-uuuu-uuuu-uuuuuuuuuuuu', '55555555-5555-5555-5555-555555555555', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 4, 'Great modern cuts and friendly staff. Will definitely come back.'),
    ('vvvvvvvv-vvvv-vvvv-vvvv-vvvvvvvvvvvv', '66666666-6666-6666-6666-666666666666', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 5, 'Traditional barber shop with excellent service. Very satisfied with the haircut.')
ON CONFLICT (id) DO NOTHING;

-- Sample messages
INSERT INTO public.messages (id, thread_id, sender_id, receiver_id, text, attachments, status, is_read)
VALUES 
    ('wwwwwwww-wwww-wwww-wwww-wwwwwwwwwwww', 'thread-1', '44444444-4444-4444-4444-444444444444', '11111111-1111-1111-1111-111111111111', 'Hi, I would like to book an appointment for tomorrow.', '[]', 'sent', false),
    ('xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx', 'thread-1', '11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'Hello! Sure, what time would work for you?', '[]', 'sent', true),
    ('yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy', 'thread-1', '44444444-4444-4444-4444-444444444444', '11111111-1111-1111-1111-111111111111', 'How about 2 PM?', '[]', 'sent', false),
    
    ('zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz', 'thread-2', '55555555-5555-5555-5555-555555555555', '22222222-2222-2222-2222-222222222222', 'I need a fade haircut. Are you available this weekend?', '[]', 'sent', false),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'thread-2', '22222222-2222-2222-2222-222222222222', '55555555-5555-5555-5555-555555555555', 'Yes, I have slots available on Saturday morning.', '[]', 'sent', true)
ON CONFLICT (id) DO NOTHING;

-- Sample AI suggestions
INSERT INTO public.ai_suggestions (id, user_id, suggestion_type, title, description, content, salon_id, service_id, image_url, confidence_score, tags, is_booked)
VALUES 
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '44444444-4444-4444-4444-444444444444', 'haircut', 'Modern Fade Style', 'A contemporary fade haircut that suits your face shape perfectly.', '{"style": "fade", "length": "short", "face_shape": "oval"}', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'gggggggg-gggg-gggg-gggg-gggggggggggg', 'https://images.unsplash.com/photo-1621605815971-fa8b5fc82a63?w=400', 0.92, ARRAY['modern', 'fade', 'short'], false),
    
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', '55555555-5555-5555-5555-555555555555', 'beard', 'Professional Beard Style', 'A well-groomed beard that enhances your professional appearance.', '{"style": "professional", "length": "medium", "maintenance": "low"}', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'llllllll-llll-llll-llll-llllllllllll', 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400', 0.88, ARRAY['professional', 'beard', 'groomed'], true),
    
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', '66666666-6666-6666-6666-666666666666', 'styling', 'Classic Side Part', 'A timeless side part hairstyle that never goes out of fashion.', '{"style": "side_part", "length": "medium", "formality": "business"}', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'nnnnnnnn-nnnn-nnnn-nnnn-nnnnnnnnnnnn', 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400', 0.85, ARRAY['classic', 'side_part', 'business'], false)
ON CONFLICT (id) DO NOTHING;

-- Sample notifications
INSERT INTO public.notifications (id, user_id, type, title, message, data, is_read)
VALUES 
    ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '44444444-4444-4444-4444-444444444444', 'appointment', 'Appointment Confirmed', 'Your appointment at Elite Hair Studio has been confirmed for tomorrow at 10:00 AM.', '{"appointment_id": "pppppppp-pppp-pppp-pppp-pppppppppppp", "salon_name": "Elite Hair Studio"}', false),
    
    ('ffffffff-ffff-ffff-ffff-ffffffffffff', '55555555-5555-5555-5555-555555555555', 'message', 'New Message', 'You have a new message from Modern Cuts.', '{"sender_name": "Sarah Johnson", "salon_name": "Modern Cuts"}', false),
    
    ('gggggggg-gggg-gggg-gggg-gggggggggggg', '66666666-6666-6666-6666-666666666666', 'appointment', 'Appointment Completed', 'Your appointment at Royal Barber Shop has been completed. Thank you for choosing us!', '{"appointment_id": "rrrrrrrr-rrrr-rrrr-rrrr-rrrrrrrrrrrr", "salon_name": "Royal Barber Shop"}', true)
ON CONFLICT (id) DO NOTHING;

-- Sample promotions
INSERT INTO public.promotions (id, salon_id, title, description, discount_percentage, discount_amount, min_order_amount, max_uses, used_count, valid_from, valid_until, is_active)
VALUES 
    ('hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'New Customer Special', 'Get 20% off your first visit!', 20.00, NULL, 0, 50, 12, '2024-01-01 00:00:00+00', '2024-12-31 23:59:59+00', true),
    
    ('iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Weekend Package', 'Haircut + Beard styling for just $40', NULL, 10.00, 50, 30, 8, '2024-01-01 00:00:00+00', '2024-12-31 23:59:59+00', true),
    
    ('jjjjjjjj-jjjj-jjjj-jjjj-jjjjjjjjjjjj', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Student Discount', '15% off for students with valid ID', 15.00, NULL, 0, 100, 25, '2024-01-01 00:00:00+00', '2024-12-31 23:59:59+00', true)
ON CONFLICT (id) DO NOTHING;

-- Sample user favorites
INSERT INTO public.user_favorites (id, user_id, salon_id, service_id)
VALUES 
    ('kkkkkkkk-kkkk-kkkk-kkkk-kkkkkkkkkkkk', '44444444-4444-4444-4444-444444444444', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', NULL),
    ('llllllll-llll-llll-llll-llllllllllll', '44444444-4444-4444-4444-444444444444', NULL, 'gggggggg-gggg-gggg-gggg-gggggggggggg'),
    ('mmmmmmmm-mmmm-mmmm-mmmm-mmmmmmmmmmmm', '55555555-5555-5555-5555-555555555555', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', NULL),
    ('nnnnnnnn-nnnn-nnnn-nnnn-nnnnnnnnnnnn', '66666666-6666-6666-6666-666666666666', 'cccccccc-cccc-cccc-cccc-cccccccccccc', NULL)
ON CONFLICT (id) DO NOTHING;

-- Sample user preferences
INSERT INTO public.user_preferences (id, user_id, preferences)
VALUES 
    ('oooooooo-oooo-oooo-oooo-oooooooooooo', '44444444-4444-4444-4444-444444444444', '{"notifications": {"email": true, "push": true, "sms": false}, "appointments": {"reminder_hours": 24}, "preferences": {"language": "en", "theme": "light"}}'),
    ('pppppppp-pppp-pppp-pppp-pppppppppppp', '55555555-5555-5555-5555-555555555555', '{"notifications": {"email": true, "push": true, "sms": true}, "appointments": {"reminder_hours": 12}, "preferences": {"language": "en", "theme": "dark"}}'),
    ('qqqqqqqq-qqqq-qqqq-qqqq-qqqqqqqqqqqq', '66666666-6666-6666-6666-666666666666', '{"notifications": {"email": false, "push": true, "sms": false}, "appointments": {"reminder_hours": 48}, "preferences": {"language": "ur", "theme": "light"}}')
ON CONFLICT (id) DO NOTHING;

-- Sample staff availability
INSERT INTO public.staff_availability (id, staff_id, day_of_week, start_time, end_time, is_available)
VALUES 
    -- Elite Hair Studio owner availability
    ('rrrrrrrr-rrrr-rrrr-rrrr-rrrrrrrrrrrr', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 1, '09:00:00', '18:00:00', true), -- Monday
    ('ssssssss-ssss-ssss-ssss-ssssssssssss', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 2, '09:00:00', '18:00:00', true), -- Tuesday
    ('tttttttt-tttt-tttt-tttt-tttttttttttt', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 3, '09:00:00', '18:00:00', true), -- Wednesday
    ('uuuuuuuu-uuuu-uuuu-uuuu-uuuuuuuuuuuu', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 4, '09:00:00', '18:00:00', true), -- Thursday
    ('vvvvvvvv-vvvv-vvvv-vvvv-vvvvvvvvvvvv', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 5, '09:00:00', '18:00:00', true), -- Friday
    ('wwwwwwww-wwww-wwww-wwww-wwwwwwwwwwww', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 6, '10:00:00', '16:00:00', true), -- Saturday
    
    -- Modern Cuts owner availability
    ('xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 1, '08:00:00', '17:00:00', true), -- Monday
    ('yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 2, '08:00:00', '17:00:00', true), -- Tuesday
    ('zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 3, '08:00:00', '17:00:00', true), -- Wednesday
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 4, '08:00:00', '17:00:00', true), -- Thursday
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 5, '08:00:00', '17:00:00', true), -- Friday
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 6, '09:00:00', '15:00:00', true), -- Saturday
    
    -- Royal Barber Shop owner availability
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 1, '08:30:00', '17:30:00', true), -- Monday
    ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 2, '08:30:00', '17:30:00', true), -- Tuesday
    ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 3, '08:30:00', '17:30:00', true), -- Wednesday
    ('gggggggg-gggg-gggg-gggg-gggggggggggg', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 4, '08:30:00', '17:30:00', true), -- Thursday
    ('hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 5, '08:30:00', '17:30:00', true), -- Friday
    ('iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 6, '09:00:00', '16:00:00', true)  -- Saturday
ON CONFLICT (id) DO NOTHING;
