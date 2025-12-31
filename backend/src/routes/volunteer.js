const express = require('express');
const router = express.Router();
const { auth, authorize } = require('../middleware/auth');
const volunteerController = require('../controllers/volunteerController');

// All volunteer routes require authentication and volunteer role
router.use(auth);
router.use(authorize('volunteer'));

// Get volunteer requests
router.get('/requests', volunteerController.getVolunteerRequests);

// Accept or reject a volunteer request
router.put('/requests/:id/respond', volunteerController.respondToRequest);

// Get assigned donations
router.get('/donations/assigned', volunteerController.getAssignedDonations);

// Update donation status (mark as completed)
router.put('/donations/:id/status', volunteerController.updateDonationStatus);

// Get completed deliveries
router.get('/donations/completed', volunteerController.getCompletedDeliveries);

// Submit delivery review
router.post('/donations/:id/review', volunteerController.submitDeliveryReview);

module.exports = router;
