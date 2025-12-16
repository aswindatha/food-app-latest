const { DataTypes } = require('sequelize');
const { sequelize } = process.env.NODE_ENV === 'test' 
  ? require('../config/test-db') 
  : require('../config/db');
const User = require('./User');
const Donation = require('./Donation');

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
      model: Donation,
      key: 'id',
    },
    onUpdate: 'CASCADE',
    onDelete: 'CASCADE',
  },
  organization_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: User,
      key: 'id',
    },
    onUpdate: 'CASCADE',
    onDelete: 'CASCADE',
  },
  volunteer_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: User,
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

// Define associations
VolunteerRequest.belongsTo(Donation, { as: 'donation', foreignKey: 'donation_id' });
VolunteerRequest.belongsTo(User, { as: 'organization', foreignKey: 'organization_id' });
VolunteerRequest.belongsTo(User, { as: 'volunteer', foreignKey: 'volunteer_id' });

// Add methods to Donation model for volunteer requests
Donation.VolunteerRequests = Donation.hasMany(VolunteerRequest, { 
  as: 'volunteerRequests',
  foreignKey: 'donation_id' 
});

module.exports = VolunteerRequest;
