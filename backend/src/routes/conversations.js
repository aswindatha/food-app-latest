const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const conversationController = require('../controllers/conversationController');

// All conversation routes require authentication
router.use(auth);

// Get all conversations for the authenticated user
router.get('/', conversationController.getUserConversations);

// Get available users to start conversations with
router.get('/available-users', conversationController.getAvailableUsers);

// Get unread messages count
router.get('/unread-count', conversationController.getUnreadCount);

// Create a new conversation
router.post('/', conversationController.createConversation);

// Get a single conversation with messages
router.get('/:id', conversationController.getConversationById);

// Send a message in a conversation
router.post('/:id/messages', conversationController.sendMessage);

module.exports = router;
