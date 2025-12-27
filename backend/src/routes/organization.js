const express = require('express');
const router = express.Router();
const { auth, authorize } = require('../middleware/auth');
const organizationController = require('../controllers/organizationController');

// All organization routes require authentication and organization role
router.use(auth);
router.use(authorize('organization'));

// Get available donations for organizations
router.get('/donations/available', organizationController.getAvailableDonations);

// Claim a donation
router.post('/donations/:id/claim', organizationController.claimDonation);

// Get all claimed donations for the organization
router.get('/donations/claimed', organizationController.getClaimedDonations);

// Request a volunteer for a claimed donation
router.post('/donations/:id/request-volunteer', organizationController.requestVolunteer);

// Request multiple volunteers for a claimed donation
router.post('/donations/:id/request-multiple-volunteers', organizationController.requestMultipleVolunteers);

// Update donation status (in_transit, completed, cancelled)
router.put('/donations/:id/status', organizationController.updateDonationStatus);

module.exports = router;
