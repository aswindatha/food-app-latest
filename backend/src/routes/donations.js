const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const donationController = require('../controllers/donationController');

// All donation routes require authentication
router.use(auth);

// Create a new donation
router.post('/', donationController.createDonation);

// Get all donations for the authenticated donor
router.get('/my-donations', donationController.getDonorDonations);

// Get all available donations (for volunteers and organizations)
router.get('/available', donationController.getAvailableDonations);

// Get a single donation by ID
router.get('/:id', donationController.getDonationById);

// Update a donation
router.put('/:id', donationController.updateDonation);

// Delete a donation
router.delete('/:id', donationController.deleteDonation);

// Assign volunteer to donation
router.post('/:id/assign-volunteer', donationController.assignVolunteer);

// Mark donation as donated
router.post('/:id/mark-donated', donationController.markAsDonated);

module.exports = router;
