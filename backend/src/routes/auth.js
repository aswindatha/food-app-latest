const express = require('express');
const router = express.Router();
const { register, login, getCurrentUser, changePassword } = require('../controllers/authController');
const { auth } = require('../middleware/auth');

// @route   POST /api/auth/register
// @desc    Register a new user
// @access  Public
router.post('/register', register);

// @route   POST /api/auth/login
// @desc    Login user
// @access  Public
router.post('/login', login);

// @route   GET /api/auth/me
// @desc    Get current user
// @access  Private
router.get('/me', auth, getCurrentUser);

// @route   POST /api/auth/change-password
// @desc    Change user password
// @access  Private
router.post('/change-password', auth, changePassword);

module.exports = router;
