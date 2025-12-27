const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const User = require('../models/User');
const { Op } = require('sequelize');

// Get all conversations for a user
const getUserConversations = async (req, res) => {
  try {
    const conversations = await Conversation.findAll({
      where: {
        [Op.or]: [
          { participant1_id: req.user.id },
          { participant2_id: req.user.id }
        ]
      },
      include: [
        { model: User, as: 'participant1', attributes: ['id', 'username', 'first_name', 'last_name', 'role'] },
        { model: User, as: 'participant2', attributes: ['id', 'username', 'first_name', 'last_name', 'role'] }
      ],
      order: [['last_message_at', 'DESC']]
    });

    res.json(conversations);
  } catch (error) {
    console.error('Error fetching conversations:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Get a single conversation with messages
const getConversationById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const conversation = await Conversation.findByPk(id, {
      include: [
        { model: User, as: 'participant1', attributes: ['id', 'username', 'first_name', 'last_name', 'role'] },
        { model: User, as: 'participant2', attributes: ['id', 'username', 'first_name', 'last_name', 'role'] }
      ]
    });

    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    // Check if user is part of this conversation
    if (conversation.participant1_id !== req.user.id && conversation.participant2_id !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to view this conversation' });
    }

    // Get messages for this conversation
    const messages = await Message.findAll({
      where: { conversation_id: id },
      include: [
        { model: User, as: 'sender', attributes: ['id', 'username', 'first_name', 'last_name'] }
      ],
      order: [['created_at', 'ASC']]
    });

    // Mark messages as read for this user
    await Message.update(
      { is_read: true },
      {
        where: {
          conversation_id: id,
          sender_id: { [Op.ne]: req.user.id },
          is_read: false
        }
      }
    );

    res.json({
      conversation,
      messages
    });
  } catch (error) {
    console.error('Error fetching conversation:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Create a new conversation
const createConversation = async (req, res) => {
  try {
    const { participant2_id, participant2_type } = req.body;

    if (!participant2_id || !participant2_type) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Check if participant2_type is valid
    if (!['donor', 'volunteer', 'organization'].includes(participant2_type)) {
      return res.status(400).json({ message: 'Invalid participant2_type' });
    }

    // Check if participant2 exists and has the correct role
    const participant2 = await User.findByPk(participant2_id);
    if (!participant2) {
      return res.status(404).json({ message: 'Participant not found' });
    }

    if (participant2.role !== participant2_type) {
      return res.status(400).json({ message: 'Participant role does not match participant2_type' });
    }

    // Check if conversation already exists
    const existingConversation = await Conversation.findOne({
      where: {
        [Op.or]: [
          { 
            participant1_id: req.user.id, 
            participant2_id: participant2_id 
          },
          { 
            participant1_id: participant2_id, 
            participant2_id: req.user.id 
          }
        ]
      }
    });

    if (existingConversation) {
      // Return existing conversation with participant details
      const conversationWithDetails = await Conversation.findByPk(existingConversation.id, {
        include: [
          { model: User, as: 'participant1', attributes: ['id', 'username', 'first_name', 'last_name', 'role'] },
          { model: User, as: 'participant2', attributes: ['id', 'username', 'first_name', 'last_name', 'role'] }
        ]
      });
      return res.status(200).json(conversationWithDetails);
    }

    // Create new conversation
    const conversation = await Conversation.create({
      participant1_id: req.user.id,
      participant2_id,
      participant2_type
    });

    // Include participant details in response
    const conversationWithDetails = await Conversation.findByPk(conversation.id, {
      include: [
        { model: User, as: 'participant1', attributes: ['id', 'username', 'first_name', 'last_name', 'role'] },
        { model: User, as: 'participant2', attributes: ['id', 'username', 'first_name', 'last_name', 'role'] }
      ]
    });

    res.status(201).json(conversationWithDetails);
  } catch (error) {
    console.error('Error creating conversation:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Send a message
const sendMessage = async (req, res) => {
  try {
    const { id } = req.params;
    const { message_text } = req.body;

    if (!message_text) {
      return res.status(400).json({ message: 'Message text is required' });
    }

    // Check if conversation exists and user is part of it
    const conversation = await Conversation.findByPk(id);
    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    if (conversation.participant1_id !== req.user.id && conversation.participant2_id !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to send message in this conversation' });
    }

    // Create message
    const message = await Message.create({
      conversation_id: id,
      sender_id: req.user.id,
      message_text
    });

    // Update conversation's last message
    await conversation.update({
      last_message: message_text,
      last_message_at: message.created_at
    });

    // Return message with sender details
    const messageWithDetails = await Message.findByPk(message.id, {
      include: [
        { model: User, as: 'sender', attributes: ['id', 'username', 'first_name', 'last_name'] }
      ]
    });

    res.status(201).json(messageWithDetails);
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Get unread messages count for a user
const getUnreadCount = async (req, res) => {
  try {
    const unreadCount = await Message.count({
      include: [
        {
          model: Conversation,
          where: {
            [Op.or]: [
              { participant1_id: req.user.id },
              { participant2_id: req.user.id }
            ]
          }
        }
      ],
      where: {
        sender_id: { [Op.ne]: req.user.id },
        is_read: false
      }
    });

    res.json({ unreadCount });
  } catch (error) {
    console.error('Error fetching unread count:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Get volunteers and organizations for starting conversations
const getAvailableUsers = async (req, res) => {
  try {
    const { role } = req.query;
    
    let whereClause = {};
    if (role && ['volunteer', 'organization'].includes(role)) {
      whereClause.role = role;
    } else {
      whereClause.role = { [Op.in]: ['volunteer', 'organization'] };
    }

    const users = await User.findAll({
      where: whereClause,
      attributes: ['id', 'username', 'first_name', 'last_name', 'role'],
      order: [['username', 'ASC']]
    });

    res.json(users);
  } catch (error) {
    console.error('Error fetching available users:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

module.exports = {
  getUserConversations,
  getConversationById,
  createConversation,
  sendMessage,
  getUnreadCount,
  getAvailableUsers,
};
