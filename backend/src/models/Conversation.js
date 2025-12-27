const { DataTypes } = require('sequelize');
const { sequelize } = process.env.NODE_ENV === 'test' 
  ? require('../config/test-db') 
  : require('../config/db');

const Conversation = sequelize.define('Conversation', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  participant1_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id',
    },
    onUpdate: 'CASCADE',
    onDelete: 'CASCADE',
  },
  participant2_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id',
    },
    onUpdate: 'CASCADE',
    onDelete: 'CASCADE',
  },
  participant2_type: {
    type: DataTypes.STRING(20),
    allowNull: false,
    validate: {
      isIn: [['donor', 'volunteer', 'organization']],
    },
  },
  last_message: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  last_message_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  tableName: 'conversations',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false,
});

module.exports = Conversation;
