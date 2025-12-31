const express = require('express');
const router = express.Router();
const { auth, authorize } = require('../middleware/auth');
const adminController = require('../controllers/adminController');

// All admin routes require authentication and admin role
router.use(auth);
router.use(authorize('admin'));

// Dashboard stats and analytics
router.get('/dashboard/stats', adminController.getDashboardStats);

// User management
router.get('/users', adminController.getAllUsers);
router.put('/users/:id', adminController.updateUser);
router.delete('/users/:id', adminController.deleteUser);

// Donation management
router.get('/donations', adminController.getAllDonations);
router.put('/donations/:id', adminController.updateDonation);
router.delete('/donations/:id', adminController.deleteDonation);

module.exports = router;
