-- Seed data for development and testing
-- This file populates the database with sample data

-- Insert sample salons
INSERT INTO salons (id, owner_id, name, description, address, phone, email, logo_url, banner_url, rating, review_count, categories, opening_hours, latitude, longitude)
VALUES 
  (
    'salon_1',
    (SELECT id FROM profiles WHERE role = 'salon_owner' LIMIT 1),
    'Menz Cut Premium',
    'Premium men''s grooming salon with modern facilities and expert stylists',
    '123 Main Street, Downtown',
    '+1-555-0101',
    'info@menzcut.com',
    'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400',
    'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=800',
    4.8,
    127,
    ARRAY['Haircut', 'Beard Trim', 'Styling'],
    '{"Monday": "9:00-18:00", "Tuesday": "9:00-18:00", "Wednesday": "9:00-18:00", "Thursday": "9:00-18:00", "Friday": "9:00-19:00", "Saturday": "9:00-17:00", "Sunday": "10:00-16:00"}',
    40.7128,
    -74.0060
  ),
  (
    'salon_2',
    (SELECT id FROM profiles WHERE role = 'salon_owner' LIMIT 1),
    'Classic Cuts',
    'Traditional barbershop with a modern twist',
    '456 Oak Avenue, Midtown',
    '+1-555-0102',
    'hello@classiccuts.com',
    'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400',
    'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=800',
    4.6,
    89,
    ARRAY['Haircut', 'Beard Trim', 'Mustache'],
    '{"Monday": "8:00-17:00", "Tuesday": "8:00-17:00", "Wednesday": "8:00-17:00", "Thursday": "8:00-17:00", "Friday": "8:00-18:00", "Saturday": "8:00-16:00", "Sunday": "Closed"}',
    40.7589,
    -73.9851
  )
ON CONFLICT (id) DO NOTHING;

-- Insert sample services
INSERT INTO services (id, salon_id, name, description, price, duration_minutes, category, image_url, is_active)
VALUES 
  -- Services for Menz Cut Premium
  ('service_1', 'salon_1', 'Premium Haircut', 'Professional haircut with styling consultation', 45.00, 60, 'Haircut', 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400', true),
  ('service_2', 'salon_1', 'Beard Trim & Shape', 'Professional beard trimming and shaping', 25.00, 30, 'Beard Trim', 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400', true),
  ('service_3', 'salon_1', 'Haircut + Beard', 'Complete grooming package', 60.00, 75, 'Package', 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400', true),
  ('service_4', 'salon_1', 'Styling Session', 'Professional styling for special occasions', 35.00, 45, 'Styling', 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400', true),
  
  -- Services for Classic Cuts
  ('service_5', 'salon_2', 'Classic Haircut', 'Traditional barber haircut', 30.00, 45, 'Haircut', 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400', true),
  ('service_6', 'salon_2', 'Beard Trim', 'Professional beard trimming', 20.00, 25, 'Beard Trim', 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400', true),
  ('service_7', 'salon_2', 'Mustache Trim', 'Precise mustache trimming', 15.00, 20, 'Mustache', 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400', true),
  ('service_8', 'salon_2', 'Hot Towel Shave', 'Traditional hot towel shave experience', 40.00, 50, 'Shave', 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400', true)
ON CONFLICT (id) DO NOTHING;

-- Insert sample appointments
INSERT INTO appointments (id, customer_id, salon_id, service_id, start_at, end_at, status, notes, total_price, payment_status)
VALUES 
  (
    'appointment_1',
    (SELECT id FROM profiles WHERE role = 'customer' LIMIT 1),
    'salon_1',
    'service_1',
    NOW() + INTERVAL '2 hours',
    NOW() + INTERVAL '3 hours',
    'confirmed',
    'First time customer, please be gentle',
    45.00,
    'pending'
  ),
  (
    'appointment_2',
    (SELECT id FROM profiles WHERE role = 'customer' LIMIT 1),
    'salon_1',
    'service_2',
    NOW() + INTERVAL '1 day',
    NOW() + INTERVAL '1 day' + INTERVAL '30 minutes',
    'pending',
    'Need beard shaped for job interview',
    25.00,
    'pending'
  ),
  (
    'appointment_3',
    (SELECT id FROM profiles WHERE role = 'customer' LIMIT 1),
    'salon_2',
    'service_5',
    NOW() + INTERVAL '3 days',
    NOW() + INTERVAL '3 days' + INTERVAL '45 minutes',
    'confirmed',
    'Regular customer, prefer shorter on sides',
    30.00,
    'paid'
  )
ON CONFLICT (id) DO NOTHING;

-- Insert sample messages
INSERT INTO messages (id, thread_id, sender_id, receiver_id, text, attachments, status, is_read)
VALUES 
  (
    'message_1',
    'thread_1',
    (SELECT id FROM profiles WHERE role = 'customer' LIMIT 1),
    (SELECT id FROM profiles WHERE role = 'salon_owner' LIMIT 1),
    'Hi, I''d like to book an appointment for tomorrow',
    '[]',
    'sent',
    false
  ),
  (
    'message_2',
    'thread_1',
    (SELECT id FROM profiles WHERE role = 'salon_owner' LIMIT 1),
    (SELECT id FROM profiles WHERE role = 'customer' LIMIT 1),
    'Sure! What time works best for you?',
    '[]',
    'sent',
    true
  ),
  (
    'message_3',
    'thread_1',
    (SELECT id FROM profiles WHERE role = 'customer' LIMIT 1),
    (SELECT id FROM profiles WHERE role = 'salon_owner' LIMIT 1),
    'How about 2 PM?',
    '[]',
    'sent',
    false
  )
ON CONFLICT (id) DO NOTHING;

-- Insert sample notifications
INSERT INTO notifications (id, user_id, type, title, message, data, is_read)
VALUES 
  (
    'notification_1',
    (SELECT id FROM profiles WHERE role = 'salon_owner' LIMIT 1),
    'appointment',
    'New Appointment Request',
    'You have a new appointment request from John Doe',
    '{"appointment_id": "appointment_1"}',
    false
  ),
  (
    'notification_2',
    (SELECT id FROM profiles WHERE role = 'customer' LIMIT 1),
    'message',
    'New Message',
    'You have a new message from Menz Cut Premium',
    '{"message_id": "message_2", "thread_id": "thread_1"}',
    true
  ),
  (
    'notification_3',
    (SELECT id FROM profiles WHERE role = 'customer' LIMIT 1),
    'appointment',
    'Appointment Confirmed',
    'Your appointment has been confirmed for tomorrow at 2 PM',
    '{"appointment_id": "appointment_1"}',
    false
  )
ON CONFLICT (id) DO NOTHING;

-- Insert sample AI suggestions
INSERT INTO ai_suggestions (id, user_id, suggestion_type, title, description, content, salon_id, service_id, image_url, confidence_score, tags, is_booked)
VALUES 
  (
    'ai_suggestion_1',
    (SELECT id FROM profiles WHERE role = 'customer' LIMIT 1),
    'haircut',
    'Modern Fade',
    'A clean, modern fade that suits your face shape',
    '{"type": "haircut", "style": "fade", "length": "short", "maintenance": "low"}',
    'salon_1',
    'service_1',
    'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400',
    0.85,
    ARRAY['modern', 'short', 'low-maintenance'],
    false
  ),
  (
    'ai_suggestion_2',
    (SELECT id FROM profiles WHERE role = 'customer' LIMIT 1),
    'styling',
    'Professional Look',
    'A professional style perfect for business meetings',
    '{"type": "styling", "style": "professional", "occasions": ["business", "formal"]}',
    'salon_1',
    'service_4',
    'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400',
    0.78,
    ARRAY['professional', 'business', 'formal'],
    false
  )
ON CONFLICT (id) DO NOTHING;
