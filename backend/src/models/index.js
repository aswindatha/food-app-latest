const { sequelize } = require('../config/db');

// Import model definitions
const User = require('./User');
const Donation = require('./Donation');
const VolunteerRequest = require('./VolunteerRequest');
const Conversation = require('./Conversation');
const Message = require('./Message');
const DonationProof = require('./donationProof')(sequelize);
const DeliveryReview = require('./deliveryReview')(sequelize);

// Set up all model associations
function setupAssociations() {
  // User associations
  User.hasMany(Donation, { as: 'donatedItems', foreignKey: 'donor_id' });

  // Donation associations
  Donation.belongsTo(User, { as: 'donor', foreignKey: 'donor_id' });
  Donation.belongsTo(User, { as: 'volunteer', foreignKey: 'volunteer_id' });
  Donation.belongsTo(User, { as: 'organization', foreignKey: 'organization_id' });
  Donation.hasMany(VolunteerRequest, { 
    as: 'volunteerRequests',
    foreignKey: 'donation_id' 
  });

  // VolunteerRequest associations
  VolunteerRequest.belongsTo(Donation, { as: 'donation', foreignKey: 'donation_id' });
  VolunteerRequest.belongsTo(User, { as: 'organization', foreignKey: 'organization_id' });
  VolunteerRequest.belongsTo(User, { as: 'volunteer', foreignKey: 'volunteer_id' });

  // Conversation associations
  Conversation.belongsTo(User, { as: 'participant1', foreignKey: 'participant1_id' });
  Conversation.belongsTo(User, { as: 'participant2', foreignKey: 'participant2_id' });
  User.hasMany(Conversation, { as: 'conversationsAsParticipant1', foreignKey: 'participant1_id' });
  User.hasMany(Conversation, { as: 'conversationsAsParticipant2', foreignKey: 'participant2_id' });

  // Message associations
  Message.belongsTo(Conversation, { foreignKey: 'conversation_id' });
  Message.belongsTo(User, { as: 'sender', foreignKey: 'sender_id' });
  Conversation.hasMany(Message, { as: 'messages', foreignKey: 'conversation_id' });
  User.hasMany(Message, { as: 'sentMessages', foreignKey: 'sender_id' });

  // DonationProof associations
  DonationProof.belongsTo(Donation, { foreignKey: 'donation_id', as: 'donation' });
  DonationProof.belongsTo(User, { foreignKey: 'organization_id', as: 'organization' });
  Donation.hasMany(DonationProof, { as: 'proofs', foreignKey: 'donation_id' });
  User.hasMany(DonationProof, { as: 'proofs', foreignKey: 'organization_id' });

  // DeliveryReview associations
  DeliveryReview.belongsTo(Donation, { foreignKey: 'donation_id', as: 'donation' });
  DeliveryReview.belongsTo(User, { foreignKey: 'volunteer_id', as: 'volunteer' });
  Donation.hasMany(DeliveryReview, { as: 'reviews', foreignKey: 'donation_id' });
  User.hasMany(DeliveryReview, { as: 'reviews', foreignKey: 'volunteer_id' });
}

// Call setup function
setupAssociations();

module.exports = {
  User,
  Donation,
  VolunteerRequest,
  Conversation,
  Message,
  DonationProof,
  DeliveryReview
};
