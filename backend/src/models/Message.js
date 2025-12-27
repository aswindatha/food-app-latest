const { DataTypes } = require('sequelize');
const { sequelize } = process.env.NODE_ENV === 'test' 
  ? require('../config/test-db') 
  : require('../config/db');
const User = require('./User');
const Conversation = require('./Conversation');

const Message = sequelize.define('Message', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  conversation_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: Conversation,
      key: 'id',
    },
    onUpdate: 'CASCADE',
    onDelete: 'CASCADE',
  },
  sender_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: User,
      key: 'id',
    },
    onUpdate: 'CASCADE',
    onDelete: 'CASCADE',
  },
  message_text: {
    type: DataTypes.TEXT,
    allowNull: false,
    validate: {
      notEmpty: true,
    },
  },
  is_read: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
}, {
  tableName: 'messages',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false,
});

module.exports = Message;
