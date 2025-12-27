const { DataTypes } = require('sequelize');
const { sequelize } = process.env.NODE_ENV === 'test' 
  ? require('../config/test-db') 
  : require('../config/db');

// VolunteerRequest model for tracking volunteer requests
const VolunteerRequest = sequelize.define('VolunteerRequest', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  donation_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'donations',
      key: 'id',
    },
    onUpdate: 'CASCADE',
    onDelete: 'CASCADE',
  },
  organization_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id',
    },
    onUpdate: 'CASCADE',
    onDelete: 'CASCADE',
  },
  volunteer_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id',
    },
    onUpdate: 'CASCADE',
    onDelete: 'CASCADE',
  },
  status: {
    type: DataTypes.ENUM('pending', 'accepted', 'rejected'),
    defaultValue: 'pending',
    allowNull: false,
  },
  message: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
}, {
  tableName: 'volunteer_requests',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  indexes: [
    {
      fields: ['donation_id'],
    },
    {
      fields: ['organization_id'],
    },
    {
      fields: ['volunteer_id'],
    },
  ],
});

module.exports = VolunteerRequest;
