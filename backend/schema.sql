-- Food Donation App Database Schema
-- This file creates the database structure and inserts sample data
USE food_app;

-- Drop tables if they exist (for clean re-creation)
DROP TABLE IF EXISTS delivery_reviews;
DROP TABLE IF EXISTS donation_proofs;
DROP TABLE IF EXISTS volunteer_requests;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS conversations;
DROP TABLE IF EXISTS donations;
DROP TABLE IF EXISTS users;

-- Create Users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    document_path VARCHAR(500),
    latitude DECIMAL(10,8),
    longitude DECIMAL(10,8),
    role VARCHAR(20) NOT NULL CHECK (role IN ('donor', 'volunteer', 'organization', 'admin')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create Donations table
CREATE TABLE donations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    donor_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    donation_type VARCHAR(50) NOT NULL CHECK (donation_type IN ('FOOD', 'CLOTHES', 'MEDICINE', 'OTHER')),
    quantity INT NOT NULL CHECK (quantity >= 1),
    unit VARCHAR(20) NOT NULL,
    expiry_date DATE NOT NULL,
    cooking_time DATETIME, -- For food items, time when food was cooked
    pickup_address TEXT NOT NULL,
    pickup_time DATETIME,
    status VARCHAR(20) DEFAULT 'available' CHECK (status IN ('available', 'claiming', 'in_transit', 'completed', 'cancelled', 'expired')),
    organization_id INT,
    volunteer_id INT,
    volunteer_count INT DEFAULT 0 NOT NULL,
    image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (donor_id) REFERENCES users(id) ON DELETE
 CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE SET NULL,
    FOREIGN KEY (volunteer_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE SET NULL
);

-- Create Conversations table
CREATE TABLE conversations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    participant1_id INT NOT NULL,
    participant2_id INT NOT NULL,
    participant2_type VARCHAR(20) NOT NULL CHECK (participant2_type IN ('donor', 'volunteer', 'organization')),
    last_message TEXT,
    last_message_at DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (participant1_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (participant2_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Create Messages table
CREATE TABLE messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    conversation_id INT NOT NULL,
    sender_id INT NOT NULL,
    message_text TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Create Volunteer Requests table
CREATE TABLE volunteer_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    donation_id INT NOT NULL,
    organization_id INT NOT NULL,
    volunteer_id INT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (donation_id) REFERENCES donations(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (volunteer_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Create Donation Proofs table
CREATE TABLE donation_proofs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    donation_id INT NOT NULL,
    organization_id INT NOT NULL,
    image_url TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (donation_id) REFERENCES donations(id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create Delivery Reviews table
CREATE TABLE delivery_reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    donation_id INT NOT NULL,
    volunteer_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (donation_id) REFERENCES donations(id) ON DELETE CASCADE,
    FOREIGN KEY (volunteer_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Insert sample data

-- Sample Users
INSERT INTO users (username, email, password_hash, first_name, last_name, phone, address, document_path, latitude, longitude, role) VALUES
('johndonor', 'john@example.com', '$2a$10$example_hash_1', 'John', 'Donor', '555-0101', NULL, NULL, NULL, NULL, 'donor'),
('foodbank_org', 'contact@foodbank.org', '$2a$10$example_hash_3', 'Food', 'Bank', '555-0103', '123 Main St, Downtown', '/assets/foodbank_org/verification.pdf', 40.7128, -74.0060, 'organization'),
('helpinghands', 'info@helpinghands.org', '$2a$10$example_hash_4', 'Helping', 'Hands', '555-0104', '456 Oak Ave, Westside', '/assets/helpinghands/license.pdf', 40.7580, -73.9855, 'organization'),
('mikedonor', 'mike@example.com', '$2a$10$example_hash_5', 'Mike', 'Johnson', '555-0105', NULL, NULL, NULL, NULL, 'donor'),
('volunteer1', 'volunteer1@example.com', '$2a$10$example_hash_6', 'Volunteer', 'One', '555-0106', NULL, NULL, NULL, NULL, 'volunteer'),
('admin', 'admin@foodapp.com', '$2a$10$example_hash_admin', 'Admin', 'User', '555-0100', NULL, NULL, NULL, NULL, 'admin');

-- Sample Donations
INSERT INTO donations (donor_id, title, description, donation_type, quantity, unit, expiry_date, cooking_time, pickup_address, pickup_time, status, organization_id, volunteer_id, volunteer_count, image_url) VALUES
(1, 'Fresh Vegetables', 'Mixed fresh vegetables including carrots, tomatoes, and lettuce', 'FOOD', 50, 'kg', '2025-02-25', '2025-02-19 09:00:00', '123 Main St, Downtown', '2025-02-19 10:00:00', 'available', NULL, NULL, 0, 'https://example.com/vegetables.jpg'),
(1, 'Canned Goods', 'Various canned foods including beans, soups, and vegetables', 'FOOD', 100, 'cans', '2025-12-31', '2025-02-19 13:00:00', '123 Main St, Downtown', '2025-02-19 14:00:00', 'in_transit', 3, 6, 1, 'https://example.com/canned.jpg'),
(5, 'Winter Clothes', 'Warm winter clothes including jackets and sweaters', 'CLOTHES', 25, 'pieces', '2025-11-30', NULL, '456 Oak Ave, Westside', '2025-02-20 09:00:00', 'available', NULL, NULL, 0, 'https://example.com/clothes.jpg'),
(5, 'Medicine Supplies', 'Basic medical supplies including bandages and antiseptics', 'MEDICINE', 10, 'boxes', '2025-08-15', NULL, '456 Oak Ave, Westside', '2025-02-20 11:00:00', 'completed', 4, 6, 1, 'https://example.com/medicine.jpg'),
(1, 'Bread and Pastries', 'Fresh bread and pastries from local bakery', 'FOOD', 30, 'loaves', '2025-02-22', '2025-02-19 15:30:00', '123 Main St, Downtown', '2025-02-19 16:00:00', 'available', NULL, NULL, 0, 'https://example.com/bread.jpg');

-- Sample Conversations
INSERT INTO conversations (participant1_id, participant2_id, participant2_type, last_message, last_message_at) VALUES
(1, 3, 'organization', 'Is the food still available for pickup?', '2025-02-18 10:30:00'),
(3, 1, 'donor', 'Yes, it is. When can you pick it up?', '2025-02-18 11:00:00'),
(5, 4, 'organization', 'Thank you for the medicine supplies!', '2025-02-17 15:45:00');

-- Sample Messages
INSERT INTO messages (conversation_id, sender_id, message_text, is_read, created_at) VALUES
(1, 3, 'Is the food still available for pickup?', TRUE, '2025-02-18 10:30:00'),
(1, 1, 'Yes, it is. When can you pick it up?', TRUE, '2025-02-18 11:00:00'),
(1, 3, 'We can pick it up tomorrow at 10 AM', FALSE, '2025-02-18 11:30:00'),
(2, 4, 'Thank you for the medicine supplies!', TRUE, '2025-02-17 15:45:00'),
(2, 5, 'You''re welcome! Glad they could help.', TRUE, '2025-02-17 16:00:00');

-- Sample Donation Proofs
INSERT INTO donation_proofs (donation_id, organization_id, image_url, description, created_at) VALUES
(4, 4, 'https://example.com/proof_medicine.jpg', 'Medicine supplies received and organized in our storage', '2025-02-17 17:00:00');

-- Sample Delivery Reviews
INSERT INTO delivery_reviews (donation_id, volunteer_id, rating, review_text, created_at) VALUES
(4, 6, 5, 'Excellent quality medicine supplies, well packaged and delivered on time. Thank you!', '2025-02-17 18:00:00');

-- Sample Volunteer Requests
INSERT INTO volunteer_requests (donation_id, organization_id, volunteer_id, status, message, created_at) VALUES
(2, 3, 6, 'accepted', 'I can help deliver these canned goods to your organization', '2025-02-18 09:00:00'),
(4, 4, 6, 'accepted', 'Available to pick up and deliver medicine supplies', '2025-02-16 14:00:00');

-- Create indexes for better performance
CREATE INDEX idx_donations_donor_id ON donations(donor_id);
CREATE INDEX idx_donations_status ON donations(status);
CREATE INDEX idx_donations_type ON donations(donation_type);
CREATE INDEX idx_donations_volunteer_id ON donations(volunteer_id);
CREATE INDEX idx_donations_organization_id ON donations(organization_id);
CREATE INDEX idx_conversations_participant1 ON conversations(participant1_id);
CREATE INDEX idx_conversations_participant2 ON conversations(participant2_id);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_volunteer_requests_donation_id ON volunteer_requests(donation_id);
CREATE INDEX idx_volunteer_requests_organization_id ON volunteer_requests(organization_id);
CREATE INDEX idx_volunteer_requests_volunteer_id ON volunteer_requests(volunteer_id);
CREATE INDEX idx_donation_proofs_donation_id ON donation_proofs(donation_id);
CREATE INDEX idx_donation_proofs_organization_id ON donation_proofs(organization_id);
CREATE INDEX idx_delivery_reviews_donation_id ON delivery_reviews(donation_id);
CREATE INDEX idx_delivery_reviews_volunteer_id ON delivery_reviews(volunteer_id);

-- Display summary of data inserted
SELECT 'Database schema created successfully!' as message;
SELECT COUNT(*) as total_users FROM users;
SELECT COUNT(*) as total_donations FROM donations;
SELECT COUNT(*) as total_conversations FROM conversations;
SELECT COUNT(*) as total_messages FROM messages;
SELECT COUNT(*) as total_volunteer_requests FROM volunteer_requests;
SELECT COUNT(*) as total_donation_proofs FROM donation_proofs;
SELECT COUNT(*) as total_delivery_reviews FROM delivery_reviews;
