# Food Donation App API Documentation

## Authentication Endpoints

### POST /api/auth/register
**Purpose**: Register a new user in the system  
**Request Payload**: 
```json
{
  "username": "string",
  "email": "string", 
  "password": "string",
  "first_name": "string",
  "last_name": "string",
  "role": "donor|organization|volunteer"
}
```
**Response Payload**: 
```json
{
  "id": "number",
  "username": "string",
  "email": "string",
  "first_name": "string", 
  "last_name": "string",
  "role": "string",
  "token": "string"
}
```
**UI Integration**: Registration page for all user types  
**Business Logic**: Validates input, checks for existing users, creates account with hashed password, generates JWT token

### POST /api/auth/login
**Purpose**: Authenticate user and return JWT token  
**Request Payload**:
```json
{
  "emailOrUsername": "string",
  "password": "string"
}
```
**Response Payload**:
```json
{
  "id": "number",
  "username": "string", 
  "email": "string",
  "first_name": "string",
  "last_name": "string", 
  "role": "string",
  "token": "string"
}
```
**UI Integration**: Login page for all users  
**Business Logic**: Finds user by email/username, validates password, generates JWT token

### GET /api/auth/me
**Purpose**: Get current authenticated user information  
**Request Payload**: None (requires JWT token in headers)  
**Response Payload**:
```json
{
  "id": "number",
  "username": "string",
  "email": "string", 
  "first_name": "string",
  "last_name": "string",
  "role": "string"
}
```
**UI Integration**: User profile display and authentication checks  
**Business Logic**: Validates JWT token, returns user data without password

---

## Donation Endpoints

### POST /api/donations
**Purpose**: Create a new food donation listing  
**Request Payload**:
```json
{
  "title": "string",
  "description": "string", 
  "donation_type": "string",
  "quantity": "number",
  "unit": "string",
  "expiry_date": "date",
  "pickup_address": "string",
  "pickup_time": "string",
  "image_url": "string"
}
```
**Response Payload**:
```json
{
  "id": "number",
  "donor_id": "number",
  "title": "string",
  "description": "string",
  "donation_type": "string", 
  "quantity": "number",
  "unit": "string",
  "expiry_date": "date",
  "pickup_address": "string",
  "pickup_time": "string",
  "image_url": "string",
  "status": "available",
  "donor": {
    "id": "number",
    "username": "string",
    "first_name": "string",
    "last_name": "string"
  }
}
```
**UI Integration**: Donor's create donation form  
**Business Logic**: Validates donor role, creates donation record, sets status to 'available'

### GET /api/donations/my-donations
**Purpose**: Get all donations created by the authenticated donor  
**Request Payload**: None (requires authentication)  
**Response Payload**: Array of donation objects with donor details  
**UI Integration**: Donor's dashboard showing their listings  
**Business Logic**: Filters donations by donor_id, includes donor information

### GET /api/donations/available
**Purpose**: Get all available donations for volunteers and organizations  
**Request Payload**: None (requires authentication)  
**Response Payload**: Array of available donation objects with donor details  
**UI Integration**: Available donations browse page for volunteers/organizations  
**Business Logic**: Filters donations with 'available' status, excludes user's own donations

### GET /api/donations/:id
**Purpose**: Get details of a specific donation  
**Request Payload**: None (requires authentication)  
**Response Payload**: Single donation object with donor details  
**UI Integration**: Donation detail view page  
**Business Logic**: Finds donation by ID, includes donor information

### PUT /api/donations/:id
**Purpose**: Update donation information (only by donor)  
**Request Payload**: Same structure as create donation  
**Response Payload**: Updated donation object  
**UI Integration**: Donor's edit donation form  
**Business Logic**: Validates donor ownership, updates donation record

### DELETE /api/donations/:id
**Purpose**: Delete a donation (only by donor)  
**Request Payload**: None (requires authentication)  
**Response Payload**: Success message  
**UI Integration**: Donor's delete donation action  
**Business Logic**: Validates donor ownership, deletes donation record

### POST /api/donations/:id/assign-volunteer
**Purpose**: Assign a volunteer to a donation  
**Request Payload**:
```json
{
  "volunteer_id": "number"
}
```
**Response Payload**: Updated donation object  
**UI Integration**: Volunteer assignment interface  
**Business Logic**: Updates donation with assigned volunteer, changes status

### POST /api/donations/:id/mark-donated
**Purpose**: Mark donation as completed/donated  
**Request Payload**: None (requires authentication)  
**Response Payload**: Updated donation object  
**UI Integration**: Donation completion workflow  
**Business Logic**: Updates donation status to 'donated', records completion

---

## Organization Endpoints

### GET /api/organization/donations/available
**Purpose**: Get available donations for organizations to claim  
**Request Payload**: None (requires organization role)  
**Response Payload**: Array of available donations  
**UI Integration**: Organization's browse donations page  
**Business Logic**: Shows 'available' donations, excludes claimed ones

### POST /api/organization/donations/:id/claim
**Purpose**: Claim a donation for the organization  
**Request Payload**: None (requires organization role)  
**Response Payload**: Updated donation object  
**UI Integration**: Organization's claim donation action  
**Business Logic**: Updates donation with organization_id, changes status to 'claimed'

### GET /api/organization/donations/claimed
**Purpose**: Get all donations claimed by the organization  
**Request Payload**: None (requires organization role)  
**Response Payload**: Array of claimed donation objects  
**UI Integration**: Organization's claimed donations dashboard  
**Business Logic**: Filters donations by organization_id

### POST /api/organization/donations/:id/request-volunteer
**Purpose**: Request a volunteer for a claimed donation  
**Request Payload**:
```json
{
  "volunteer_id": "number"
}
```
**Response Payload**: Success message  
**UI Integration**: Organization's volunteer request interface  
**Business Logic**: Creates volunteer request record, notifies volunteer

### PUT /api/organization/donations/:id/status
**Purpose**: Update donation status (in_transit, completed, cancelled)  
**Request Payload**:
```json
{
  "status": "in_transit|completed|cancelled"
}
```
**Response Payload**: Updated donation object  
**UI Integration**: Organization's donation status management  
**Business Logic**: Validates status transition, updates donation record

---

## Volunteer Endpoints

### GET /api/volunteer/requests
**Purpose**: Get volunteer requests for the authenticated volunteer  
**Request Payload**: None (requires volunteer role)  
**Response Payload**: Array of volunteer request objects  
**UI Integration**: Volunteer's requests dashboard  
**Business Logic**: Filters volunteer requests by volunteer_id

### PUT /api/volunteer/requests/:id/respond
**Purpose**: Accept or reject a volunteer request  
**Request Payload**:
```json
{
  "status": "accepted|rejected"
}
```
**Response Payload**: Updated volunteer request object  
**UI Integration**: Volunteer's request response interface  
**Business Logic**: Updates request status, triggers donation assignment if accepted

### GET /api/volunteer/donations/assigned
**Purpose**: Get donations assigned to the volunteer  
**Request Payload**: None (requires volunteer role)  
**Response Payload**: Array of assigned donation objects  
**UI Integration**: Volunteer's assigned donations dashboard  
**Business Logic**: Filters donations by assigned volunteer_id

### PUT /api/volunteer/donations/:id/status
**Purpose**: Update assigned donation status (mark as completed)  
**Request Payload**:
```json
{
  "status": "completed"
}
```
**Response Payload**: Updated donation object  
**UI Integration**: Volunteer's donation completion workflow  
**Business Logic**: Validates volunteer assignment, updates donation status

---

## Conversation Endpoints

### GET /api/conversations
**Purpose**: Get all conversations for the authenticated user  
**Request Payload**: None (requires authentication)  
**Response Payload**: Array of conversation objects  
**UI Integration**: User's conversations list  
**Business Logic**: Filters conversations by user participation

### GET /api/conversations/available-users
**Purpose**: Get available users to start conversations with  
**Request Payload**: None (requires authentication)  
**Response Payload**: Array of user objects  
**UI Integration**: Start new conversation interface  
**Business Logic**: Returns users excluding current user and existing conversations

### GET /api/conversations/unread-count
**Purpose**: Get count of unread messages for the user  
**Request Payload**: None (requires authentication)  
**Response Payload**:
```json
{
  "unread_count": "number"
}
```
**UI Integration**: Unread messages indicator  
**Business Logic**: Counts unread messages in user's conversations

### POST /api/conversations
**Purpose**: Create a new conversation  
**Request Payload**:
```json
{
  "participant_id": "number"
}
```
**Response Payload**: New conversation object  
**UI Integration**: Start conversation action  
**Business Logic**: Creates conversation record with participants

### GET /api/conversations/:id
**Purpose**: Get conversation details with messages  
**Request Payload**: None (requires authentication)  
**Response Payload**: Conversation object with messages array  
**UI Integration**: Conversation detail view  
**Business Logic**: Returns conversation and all messages, marks as read

### POST /api/conversations/:id/messages
**Purpose**: Send a message in a conversation  
**Request Payload**:
```json
{
  "content": "string"
}
```
**Response Payload**: New message object  
**UI Integration**: Message sending interface  
**Business Logic**: Creates message record, updates conversation timestamps

---

## Overall Business Logic Flow

1. **User Registration**: Users register with specific roles (donor, organization, volunteer) and receive JWT tokens
2. **Donation Creation**: Donors create food donations with details, quantity, and pickup information
3. **Donation Discovery**: Organizations and volunteers browse available donations
4. **Donation Claiming**: Organizations claim donations they can use
5. **Volunteer Coordination**: Organizations request volunteers for claimed donations
6. **Volunteer Assignment**: Volunteers accept/reject requests and get assigned to donations
7. **Donation Fulfillment**: Volunteers pick up and deliver donations, marking them as completed
8. **Communication**: Users can message each other through the conversation system for coordination
9. **Status Tracking**: All parties can track donation status through their respective dashboards

## Database Configuration

The application now uses **MySQL** database with the following configuration:
- Host: localhost
- Port: 3306  
- User: root
- Password: root
- Database: food_app (or food_app_test for testing)

## Authentication

All protected endpoints require a valid JWT token sent in the Authorization header:
```
Authorization: Bearer <token>
```

Role-based access control is implemented for:
- Organization endpoints: require 'organization' role
- Volunteer endpoints: require 'volunteer' role  
- Donation creation: requires 'donor' role
