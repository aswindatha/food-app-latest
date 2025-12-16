# Database Structure Documentation

## Database: food_app

### Tables

#### 1. users
Stores user account information.

| Column Name    | Type         | Constraints                      | Description                          |
|----------------|--------------|----------------------------------|--------------------------------------|
| id             | SERIAL       | PRIMARY KEY                      | Auto-incrementing ID                 |
| username       | VARCHAR(50)  | UNIQUE, NOT NULL                 | Username for login                   |
| email          | VARCHAR(100) | UNIQUE, NOT NULL                 | User's email address                 |
| password_hash  | VARCHAR(255) | NOT NULL                         | Hashed password                      |
| first_name     | VARCHAR(50)  | NOT NULL                         | User's first name                    |
| last_name      | VARCHAR(50)  | NOT NULL                         | User's last name                     |
| phone          | VARCHAR(20)  |                                  | User's phone number                  |
| role           | VARCHAR(20)  | NOT NULL                         | user's role (donor, volunteer, organization)|

#### 2. donations
Stores food donation information from donors.

| Column Name      | Type            | Constraints                      | Description                          |
|------------------|-----------------|----------------------------------|--------------------------------------|
| id               | SERIAL          | PRIMARY KEY                      | Auto-incrementing ID                |
| donor_id         | INTEGER         | NOT NULL, FOREIGN KEY(users.id)  | Reference to donor user             |
| title            | VARCHAR(100)    | NOT NULL                         | Donation title/name                 |
| description      | TEXT            |                                  | Detailed description of donation    |
| donation_type    | VARCHAR(50)     | NOT NULL                         | Type of DONATION (FOOD, CLOTHES, etc.) |
| quantity         | INTEGER         | NOT NULL                         | Number of items/units               |
| unit             | VARCHAR(20)     | NOT NULL                         | Unit of measurement (kg, pieces, etc.) |
| expiry_date      | TIMESTAMP       | NOT NULL                         | Food expiration date                |
| pickup_address   | TEXT            | NOT NULL                         | Pickup location address              |
| pickup_time      | TIMESTAMP       |                                  | Preferred pickup time               |
| status           | VARCHAR(20)     | DEFAULT 'current'                | Status: current, donated, expired   |
| volunteer_id     | INTEGER         | FOREIGN KEY(users.id)            | Assigned volunteer (if any)         |
| organization_id  | INTEGER         | FOREIGN KEY(users.id)            | Assigned organization (if any)      |
| created_at       | TIMESTAMP       | DEFAULT CURRENT_TIMESTAMP        | Record creation timestamp           |
| updated_at       | TIMESTAMP       | DEFAULT CURRENT_TIMESTAMP        | Record last update timestamp        |

#### 3. conversations
Stores chat conversations between users.

| Column Name      | Type            | Constraints                      | Description                          |
|------------------|-----------------|----------------------------------|--------------------------------------|
| id               | SERIAL          | PRIMARY KEY                      | Auto-incrementing ID                 |
| participant1_id  | INTEGER         | NOT NULL, FOREIGN KEY(users.id)  | First participant (donor)            |
| participant2_id  | INTEGER         | NOT NULL, FOREIGN KEY(users.id)  | Second participant (volunteer/org)   |
| participant2_type| VARCHAR(20)     | NOT NULL                        | Type: volunteer, organization       |
| last_message     | TEXT            |                                  | Last message in conversation        |
| last_message_at  | TIMESTAMP       |                                  | Timestamp of last message           |
| created_at       | TIMESTAMP       | DEFAULT CURRENT_TIMESTAMP       | Conversation start timestamp        |

#### 4. messages
Stores individual messages in conversations.

| Column Name      | Type            | Constraints                      | Description                          |
|------------------|-----------------|----------------------------------|--------------------------------------|
| id               | SERIAL          | PRIMARY KEY                     | Auto-incrementing ID                  |
| conversation_id  | INTEGER         | NOT NULL, FOREIGN KEY(conversations.id) | Reference to conversation     |
| sender_id        | INTEGER         | NOT NULL, FOREIGN KEY(users.id)  | Message sender                       |
| message_text     | TEXT            | NOT NULL                        | Message content                       |
| is_read          | BOOLEAN         | DEFAULT FALSE                   | Whether message is read               |
| created_at       | TIMESTAMP       | DEFAULT CURRENT_TIMESTAMP       | Message timestamp                     |

