# Database Structure Documentation

## Overview
This document outlines the database schema for the Food Donation Platform, including tables, relationships, and sample data.

## Database: food_app

### Tables

#### 1. roles
Stores user roles and their permissions.

| Column Name  | Type         | Constraints           | Description                          |
|--------------|--------------|-----------------------|--------------------------------------|
| id           | SERIAL       | PRIMARY KEY          | Auto-incrementing ID                |
| name         | VARCHAR(50)  | UNIQUE, NOT NULL     | Role name (donor, volunteer, etc.)  |
| description  | TEXT         |                       | Role description                    |
| created_at   | TIMESTAMP    | DEFAULT CURRENT_TIMESTAMP | Record creation timestamp          |
| updated_at   | TIMESTAMP    | DEFAULT CURRENT_TIMESTAMP | Record last update timestamp       |

#### 2. users
Stores user account information.

| Column Name    | Type         | Constraints                      | Description                          |
|----------------|--------------|----------------------------------|--------------------------------------|
| id             | SERIAL       | PRIMARY KEY                     | Auto-incrementing ID                |
| username       | VARCHAR(50)  | UNIQUE, NOT NULL                | Username for login                  |
| email          | VARCHAR(100) | UNIQUE, NOT NULL                | User's email address                |
| password_hash  | VARCHAR(255) | NOT NULL                        | Hashed password                     |
| first_name     | VARCHAR(50)  | NOT NULL                        | User's first name                   |
| last_name      | VARCHAR(50)  | NOT NULL                        | User's last name                    |
| phone          | VARCHAR(20)  |                                 | User's phone number                 |
| role_id        | INTEGER      | NOT NULL, FOREIGN KEY(roles.id) | Reference to user's role            |
| is_active      | BOOLEAN      | DEFAULT TRUE                    | Whether the account is active       |
| email_verified | BOOLEAN      | DEFAULT FALSE                   | Whether email is verified           |
| last_login     | TIMESTAMP    |                                 | Timestamp of last login             |
| created_at     | TIMESTAMP    | DEFAULT CURRENT_TIMESTAMP       | Record creation timestamp           |
| updated_at     | TIMESTAMP    | DEFAULT CURRENT_TIMESTAMP       | Record last update timestamp        |

#### 3. user_sessions
Manages user authentication sessions.

| Column Name  | Type         | Constraints                      | Description                          |
|--------------|--------------|----------------------------------|--------------------------------------|
| id           | SERIAL       | PRIMARY KEY                     | Auto-incrementing ID                |
| user_id      | INTEGER      | NOT NULL, FOREIGN KEY(users.id)  | Reference to user                   |
| session_token| VARCHAR(255) | UNIQUE, NOT NULL                | Authentication token                |
| expires_at   | TIMESTAMP    | NOT NULL                        | Token expiration timestamp          |
| created_at   | TIMESTAMP    | DEFAULT CURRENT_TIMESTAMP       | Session creation timestamp          |

#### 4. donations
Stores food donation information from donors.

| Column Name      | Type            | Constraints                      | Description                          |
|------------------|-----------------|----------------------------------|--------------------------------------|
| id               | SERIAL          | PRIMARY KEY                     | Auto-incrementing ID                |
| donor_id         | INTEGER         | NOT NULL, FOREIGN KEY(users.id)  | Reference to donor user             |
| title            | VARCHAR(100)    | NOT NULL                        | Donation title/name                 |
| description      | TEXT            |                                 | Detailed description of donation    |
| food_type        | VARCHAR(50)     | NOT NULL                        | Type of food (perishable, non-perishable, etc.) |
| quantity         | INTEGER         | NOT NULL                        | Number of items/units               |
| unit             | VARCHAR(20)     | NOT NULL                        | Unit of measurement (kg, pieces, etc.) |
| expiry_date      | TIMESTAMP       | NOT NULL                        | Food expiration date                |
| pickup_address   | TEXT            | NOT NULL                        | Pickup location address              |
| pickup_time      | TIMESTAMP       |                                 | Preferred pickup time               |
| status           | VARCHAR(20)     | DEFAULT 'current'               | Status: current, donated, expired   |
| volunteer_id     | INTEGER         | FOREIGN KEY(users.id)           | Assigned volunteer (if any)         |
| organization_id  | INTEGER         | FOREIGN KEY(users.id)           | Assigned organization (if any)      |
| created_at       | TIMESTAMP       | DEFAULT CURRENT_TIMESTAMP       | Record creation timestamp           |
| updated_at       | TIMESTAMP       | DEFAULT CURRENT_TIMESTAMP       | Record last update timestamp        |

#### 5. conversations
Stores chat conversations between users.

| Column Name      | Type            | Constraints                      | Description                          |
|------------------|-----------------|----------------------------------|--------------------------------------|
| id               | SERIAL          | PRIMARY KEY                     | Auto-incrementing ID                |
| participant1_id  | INTEGER         | NOT NULL, FOREIGN KEY(users.id)  | First participant (donor)            |
| participant2_id  | INTEGER         | NOT NULL, FOREIGN KEY(users.id)  | Second participant (volunteer/org)   |
| participant2_type| VARCHAR(20)     | NOT NULL                        | Type: volunteer, organization       |
| last_message     | TEXT            |                                 | Last message in conversation        |
| last_message_at  | TIMESTAMP       |                                 | Timestamp of last message           |
| created_at       | TIMESTAMP       | DEFAULT CURRENT_TIMESTAMP       | Conversation start timestamp        |

#### 6. messages
Stores individual messages in conversations.

| Column Name      | Type            | Constraints                      | Description                          |
|------------------|-----------------|----------------------------------|--------------------------------------|
| id               | SERIAL          | PRIMARY KEY                     | Auto-incrementing ID                |
| conversation_id  | INTEGER         | NOT NULL, FOREIGN KEY(conversations.id) | Reference to conversation         |
| sender_id        | INTEGER         | NOT NULL, FOREIGN KEY(users.id)  | Message sender                      |
| message_text     | TEXT            | NOT NULL                        | Message content                    |
| is_read          | BOOLEAN         | DEFAULT FALSE                   | Whether message is read             |
| created_at       | TIMESTAMP       | DEFAULT CURRENT_TIMESTAMP       | Message timestamp                  |

### Indexes

```sql
-- Users table indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role_id ON users(role_id);

-- Sessions table indexes
CREATE INDEX idx_sessions_token ON user_sessions(session_token);
CREATE INDEX idx_sessions_user_id ON user_sessions(user_id);

-- Donations table indexes
CREATE INDEX idx_donations_donor_id ON donations(donor_id);
CREATE INDEX idx_donations_status ON donations(status);
CREATE INDEX idx_donations_expiry_date ON donations(expiry_date);
CREATE INDEX idx_donations_volunteer_id ON donations(volunteer_id);
CREATE INDEX idx_donations_organization_id ON donations(organization_id);

-- Conversations table indexes
CREATE INDEX idx_conversations_participant1 ON conversations(participant1_id);
CREATE INDEX idx_conversations_participant2 ON conversations(participant2_id);
CREATE INDEX idx_conversations_last_message ON conversations(last_message_at);

-- Messages table indexes
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_created ON messages(created_at);
```

### Triggers

#### Update Timestamp Trigger
Automatically updates the `updated_at` column when a record is modified.

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to users table
CREATE TRIGGER update_users_updated_at 
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Apply to roles table
CREATE TRIGGER update_roles_updated_at 
BEFORE UPDATE ON roles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Apply to donations table
CREATE TRIGGER update_donations_updated_at 
BEFORE UPDATE ON donations
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## Initial Data

### Roles
| ID | Name         | Description                                   |
|----|--------------|-----------------------------------------------|
| 1  | donor        | Individual or business that donates food      |
| 2  | volunteer    | Person who collects and delivers food         |
| 3  | organization | Organization that manages food distribution   |
| 4  | administrator| System administrator with full access         |

### Sample Users
All sample users have the password: `password123`

| Username         | Email                     | Role        |
|------------------|---------------------------|-------------|
| john_donor      | john.donor@email.com      | Donor       |
| sarah_foodie    | sarah.foodie@email.com    | Donor       |
| mike_helper     | mike.helper@email.com     | Volunteer   |
| emma_volunteer  | emma.volunteer@email.com  | Volunteer   |
| food_bank_org   | contact@foodbank.org      | Organization|
| community_center| info@community.org        | Organization|
| admin           | admin@foodapp.com         | Administrator|

## Extensions

```sql
-- Enable UUID generation for session tokens
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

## Security Notes

1. All passwords are hashed using BCrypt before storage.
2. Session tokens are generated using UUID v4.
3. Indexes are in place for performance optimization.
4. Foreign key constraints maintain referential integrity.
5. Timestamps are automatically managed by the database.

## Maintenance

To reset the database (development only):

```sql
-- Drop all tables (in correct order to respect foreign keys)
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS donations CASCADE;
DROP TABLE IF EXISTS user_sessions CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- Recreate schema and seed data
\i schema.sql
\i seed-data.sql