-- Seed Data for Food App
-- Created: 2025-12-15
-- Purpose: Initial data for roles, users, donations, and conversations

-- Insert roles
INSERT INTO roles (name, description) VALUES
('donor', 'Individual or business that donates food items'),
('volunteer', 'Person who volunteers to collect and deliver food'),
('organization', 'Organization that manages food distribution'),
('administrator', 'System administrator with full access');

-- Insert sample users with password 'password123' (bcrypt hash)
-- Note: These are sample passwords - in production, use proper password hashing
INSERT INTO users (username, email, password_hash, first_name, last_name, phone, role_id, email_verified) VALUES
-- Donor users
('john_donor', 'john.donor@email.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'John', 'Donor', '+1234567890', 1, TRUE),
('sarah_foodie', 'sarah.foodie@email.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Sarah', 'Miller', '+0987654321', 1, TRUE),

-- Volunteer users
('mike_helper', 'mike.helper@email.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Mike', 'Johnson', '+1122334455', 2, TRUE),
('emma_volunteer', 'emma.volunteer@email.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Emma', 'Davis', '+5544332211', 2, TRUE),

-- Organization users
('food_bank_org', 'contact@foodbank.org', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Food', 'Bank', '+1800FOODHELP', 3, TRUE),
('community_center', 'info@community.org', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Community', 'Center', '+1555123456', 3, TRUE),

-- Administrator user
('admin', 'admin@foodapp.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Super', 'Admin', '+1999888777', 4, TRUE);

-- Insert sample donations for John Donor
INSERT INTO donations (donor_id, title, description, food_type, quantity, unit, expiry_date, pickup_address, pickup_time, status) VALUES
-- Current donations
(1, 'Fresh Vegetables', 'Mixed seasonal vegetables including carrots, tomatoes, and lettuce', 'perishable', 50, 'kg', CURRENT_TIMESTAMP + INTERVAL '3 days', '123 Main Street, City, State 12345', CURRENT_TIMESTAMP + INTERVAL '1 day', 'current'),
(1, 'Canned Goods', 'Various canned foods including beans, corn, and tomatoes', 'non-perishable', 100, 'cans', CURRENT_TIMESTAMP + INTERVAL '180 days', '123 Main Street, City, State 12345', CURRENT_TIMESTAMP + INTERVAL '2 days', 'current'),

-- Donated items
(1, 'Bread and Pastries', 'Freshly baked bread and assorted pastries', 'perishable', 20, 'pieces', CURRENT_TIMESTAMP - INTERVAL '1 day', '123 Main Street, City, State 12345', CURRENT_TIMESTAMP - INTERVAL '2 days', 'donated'),

-- Expired items
(1, 'Dairy Products', 'Milk and cheese that expired yesterday', 'perishable', 10, 'liters', CURRENT_TIMESTAMP - INTERVAL '1 day', '123 Main Street, City, State 12345', CURRENT_TIMESTAMP - INTERVAL '3 days', 'expired');

-- Insert sample donations for Sarah Foodie
INSERT INTO donations (donor_id, title, description, food_type, quantity, unit, expiry_date, pickup_address, pickup_time, status) VALUES
(2, 'Rice and Grains', 'Various types of rice and grain products', 'non-perishable', 75, 'kg', CURRENT_TIMESTAMP + INTERVAL '365 days', '456 Oak Avenue, City, State 67890', CURRENT_TIMESTAMP + INTERVAL '1 day', 'current'),
(2, 'Fresh Fruits', 'Apples, oranges, and bananas', 'perishable', 30, 'kg', CURRENT_TIMESTAMP + INTERVAL '5 days', '456 Oak Avenue, City, State 67890', CURRENT_TIMESTAMP + INTERVAL '3 days', 'current');

-- Insert sample conversations
INSERT INTO conversations (participant1_id, participant2_id, participant2_type, last_message, last_message_at) VALUES
-- John Donor conversations
(1, 3, 'volunteer', 'Great! I can pick up the vegetables tomorrow at 10 AM', CURRENT_TIMESTAMP - INTERVAL '1 hour'),
(1, 5, 'organization', 'Thank you for your donation. We can arrange pickup for your location', CURRENT_TIMESTAMP - INTERVAL '3 hours'),

-- Sarah Foodie conversations
(2, 4, 'volunteer', 'I am available to help with the rice donation', CURRENT_TIMESTAMP - INTERVAL '30 minutes'),
(2, 6, 'organization', 'We would love to receive the fresh fruits', CURRENT_TIMESTAMP - INTERVAL '2 hours');

-- Insert sample messages
INSERT INTO messages (conversation_id, sender_id, message_text, is_read) VALUES
-- Conversation 1: John Donor -> Mike Helper
(1, 1, 'Hi, I have some fresh vegetables available for donation', TRUE),
(1, 3, 'That sounds great! What type of vegetables do you have?', TRUE),
(1, 1, 'I have carrots, tomatoes, and lettuce - about 50kg total', TRUE),
(1, 3, 'Perfect! When would be a good time for pickup?', TRUE),
(1, 1, 'Tomorrow around 10 AM would work well', TRUE),
(1, 3, 'Great! I can pick up the vegetables tomorrow at 10 AM', FALSE),

-- Conversation 2: John Donor -> Food Bank Org
(2, 1, 'Hello, I have canned goods available for donation', TRUE),
(2, 5, 'Thank you for reaching out. How many cans do you have?', TRUE),
(2, 1, 'I have about 100 cans of various types', TRUE),
(2, 5, 'That would be very helpful for our food bank', TRUE),
(2, 5, 'Thank you for your donation. We can arrange pickup for your location', TRUE),

-- Conversation 3: Sarah Foodie -> Emma Volunteer
(3, 2, 'Hi Emma, I need help delivering some rice donations', TRUE),
(3, 4, 'I am available to help with the rice donation', FALSE),

-- Conversation 4: Sarah Foodie -> Community Center
(4, 2, 'We have fresh fruits available this week', TRUE),
(4, 6, 'We would love to receive the fresh fruits', TRUE),
(4, 2, 'Great! When can you pick them up?', TRUE),
(4, 6, 'We can send our volunteer team on Wednesday', TRUE);

-- Display inserted data
SELECT 'Roles created:' as info;
SELECT * FROM roles;

SELECT 'Sample users created:' as info;
SELECT u.id, u.username, u.email, u.first_name, u.last_name, r.name as role_name 
FROM users u 
JOIN roles r ON u.role_id = r.id 
ORDER BY r.name, u.username;

SELECT 'Sample donations created:' as info;
SELECT d.id, d.title, d.status, u.username as donor_name, d.expiry_date
FROM donations d
JOIN users u ON d.donor_id = u.id
ORDER BY d.status, d.expiry_date;

SELECT 'Sample conversations created:' as info;
SELECT c.id, u1.username as participant1, u2.username as participant2, c.participant2_type, c.last_message_at
FROM conversations c
JOIN users u1 ON c.participant1_id = u1.id
JOIN users u2 ON c.participant2_id = u2.id
ORDER BY c.last_message_at DESC;