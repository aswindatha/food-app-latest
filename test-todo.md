# Backend Test Coverage

## Auth Controller

- [x] **register**
  - Status: Tested 
  - Test Coverage:
    - Should register a new user with valid data
    - Should return 400 if username already exists
    - Should return 400 if email already exists
    - Should not return password hash in response
    - Should generate a valid JWT token
    - Should require all mandatory fields (username, email, password, first_name, last_name, role)
  - Test File: `test/controllers/auth.controller.test.js`
  - Last Tested: 2023-12-16

- [x] **login**
  - Status: Tested 
  - Test Coverage:
    - Should login with valid email
    - Should login with valid username
    - Should return 401 with invalid credentials
    - Should return 401 with non-existent user
    - Should return a valid JWT token on successful login
    - Should not return password hash in response
    - Should return 400 if emailOrUsername is missing
    - Should return 400 if password is missing
  - Test File: `test/controllers/auth.controller.test.js`
  - Last Tested: 2023-12-16

- [x] **getCurrentUser**
  - Status: Tested
  - Test Coverage:
    - Should return current user data
    - Should not return password hash
    - Should return 401 if not authenticated
  - Test File: `test/controllers/auth.controller.test.js`
  - Last Tested: 2023-12-16

## Donation Controller

- [x] **createDonation**
  - Status: Tested
  - Test Coverage:
    - Should create a new donation (donor only)
    - Should validate required fields
    - Should set status to 'available' by default
    - Should include donor info in response
    - Should prevent non-donors from creating donations
  - Test File: `test/controllers/donation.controller.test.js`
  - Last Tested: 2023-12-16

- [ ] **getDonorDonations**
  - Status: Not Tested
  - Test Cases:
    - Should return only donor's donations
    - Should be ordered by status
    - Should not show other users' donations

- [ ] **getDonationById**
  - Status: Not Tested
  - Test Cases:
    - Should return donation details
    - Should include donor info
    - Should return 404 if not found
    - Should enforce proper access control

- [ ] **updateDonation**
  - Status: Not Tested
  - Test Cases:
    - Should update donation details (donor only)
    - Should validate input data
    - Should prevent updates to certain fields
    - Should enforce ownership

- [ ] **deleteDonation**
  - Status: Not Tested
  - Test Cases:
    - Should delete donation (donor only)
    - Should prevent deletion of in-progress donations
    - Should return 404 if not found
    - Should enforce ownership

- [ ] **getAvailableDonations**
  - Status: Not Tested
  - Test Cases:
    - Should list only available donations
    - Should support filtering by type
    - Should include donor info

- [ ] **assignVolunteer**
  - Status: Not Tested
  - Test Cases:
    - Should assign volunteer to donation
    - Should update donation status
    - Should validate volunteer role
    - Should enforce organization ownership

- [ ] **markAsDonated**
  - Status: Not Tested
  - Test Cases:
    - Should mark donation as completed
    - Should validate donation status
    - Should enforce permissions

## Organization Controller

- [ ] **getAvailableDonations**
  - Status: Not Tested
  - Test Cases:
    - Should list only unclaimed donations
    - Should support type filtering
    - Should include donor info

- [ ] **claimDonation**
  - Status: Not Tested
  - Test Cases:
    - Should allow organization to claim available donation
    - Should prevent claiming already claimed donations
    - Should update donation status

- [ ] **requestVolunteer**
  - Status: Not Tested
  - Test Cases:
    - Should create volunteer request
    - Should validate volunteer exists
    - Should prevent duplicate requests

- [ ] **getClaimedDonations**
  - Status: Not Tested
  - Test Cases:
    - Should return only organization's claimed donations
    - Should include status filtering
    - Should include related data

- [ ] **updateDonationStatus**
  - Status: Not Tested
  - Test Cases:
    - Should update donation status
    - Should validate status transitions
    - Should enforce organization ownership

## Volunteer Controller

- [ ] **getVolunteerRequests**
  - Status: Not Tested
  - Test Cases:
    - Should return volunteer's requests
    - Should support status filtering
    - Should include donation and organization details

- [ ] **respondToRequest**
  - Status: Not Tested
  - Test Cases:
    - Should accept/reject volunteer requests
    - Should update donation status when accepted
    - Should validate request status
    - Should enforce ownership

- [ ] **getAssignedDonations**
  - Status: Not Tested
  - Test Cases:
    - Should return volunteer's assigned donations
    - Should include donor and organization info
    - Should filter by status

- [ ] **updateDonationStatus**
  - Status: Not Tested
  - Test Cases:
    - Should update donation status (volunteer)
    - Should validate status transitions
    - Should enforce volunteer assignment

## Conversation Controller

- [ ] **getConversations**
  - Status: Not Tested
  - Test Cases:
    - Should return user's conversations
    - Should include participant info
    - Should order by last message date

- [ ] **getOrCreateConversation**
  - Status: Not Tested
  - Test Cases:
    - Should create new conversation if not exists
    - Should return existing conversation
    - Should validate participants

- [ ] **sendMessage**
  - Status: Not Tested
  - Test Cases:
    - Should send message to conversation
    - Should validate conversation membership
    - Should update conversation timestamps

## Test Setup Required

1. Test database configuration
2. Test user accounts (donor, volunteer, organization)
3. Test data factories
4. Mock JWT authentication
5. Test environment variables

## Notes

- All endpoints should be tested for:
  - Authentication/Authorization
  - Input validation
  - Error handling
  - Response format
  - Database state changes