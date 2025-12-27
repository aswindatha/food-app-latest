const { Op } = require('sequelize');
const { sequelize } = require('../config/db');
const Donation = require('../models/Donation');
const User = require('../models/User');
const VolunteerRequest = require('../models/VolunteerRequest');
const Conversation = require('../models/Conversation');

// Helper function to update expired donations
const updateExpiredDonations = async () => {
  try {
    await Donation.update(
      { status: 'expired' },
      {
        where: {
          status: 'available',
          expiry_date: {
            [Op.lt]: new Date()
          }
        }
      }
    );
  } catch (error) {
    console.error('Error updating expired donations:', error);
  }
};

// List available donations for organizations
const getAvailableDonations = async (req, res) => {
  try {
    // Update expired donations first
    await updateExpiredDonations();
    
    const { type } = req.query;
    
    const whereClause = {
      status: 'available',
      organization_id: null,
    };

    if (type && ['FOOD', 'CLOTHES', 'MEDICINE', 'OTHER'].includes(type)) {
      whereClause.donation_type = type;
    }

    const donations = await Donation.findAll({
      where: whereClause,
      include: [
        { model: User, as: 'donor', attributes: ['id', 'username', 'first_name', 'last_name'] },
      ],
      order: [['created_at', 'DESC']],
    });

    res.json(donations);
  } catch (error) {
    console.error('Error fetching available donations:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Claim a donation for an organization
const claimDonation = async (req, res) => {
  try {
    const { id } = req.params;
    
    const donation = await Donation.findByPk(id);
    
    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    if (donation.status !== 'available') {
      return res.status(400).json({ message: 'Donation is not available for claiming' });
    }

    // Start a transaction
    const result = await sequelize.transaction(async (t) => {
      // Update donation status and assign to organization
      await donation.update({
        status: 'claiming',
        organization_id: req.user.id,
      }, { transaction: t });

      // Create a conversation between organization and donor
      const conversation = await Conversation.create({
        participant1_id: req.user.id,
        participant2_id: donation.donor_id,
        participant2_type: 'organization', // The organization is the one initiating
      }, { transaction: t });

      return { donation, conversation };
    });

    // Get the updated donation with associations
    const updatedDonation = await Donation.findByPk(id, {
      include: [
        { model: User, as: 'donor', attributes: ['id', 'username', 'first_name', 'last_name'] },
        { model: User, as: 'organization', attributes: ['id', 'username', 'first_name', 'last_name'] },
      ]
    });

    // TODO: Emit socket event for real-time update
    
    res.json({
      message: 'Donation claimed successfully',
      donation: updatedDonation,
      conversation: result.conversation,
    });
  } catch (error) {
    console.error('Error claiming donation:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Request multiple volunteers for a claimed donation
const requestMultipleVolunteers = async (req, res) => {
  try {
    const { id } = req.params;
    const { volunteerCount, message } = req.body;

    if (!volunteerCount || volunteerCount < 1 || volunteerCount > 10) {
      return res.status(400).json({ message: 'Volunteer count must be between 1 and 10' });
    }

    const donation = await Donation.findByPk(id);

    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    if (donation.organization_id !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to request volunteers for this donation' });
    }

    if (donation.status !== 'claiming' && donation.status !== 'in_transit') {
      return res.status(400).json({ message: 'Can only request volunteers for donations in claiming or in_transit status' });
    }

    // Get available volunteers (exclude those already requested for this donation)
    const existingVolunteerIds = await VolunteerRequest.findAll({
      where: { donation_id: id },
      attributes: ['volunteer_id']
    }).then(requests => requests.map(r => r.volunteer_id));

    const availableVolunteers = await User.findAll({
      where: {
        role: 'volunteer',
        id: { [Op.notIn]: existingVolunteerIds }
      },
      limit: volunteerCount,
      order: [['created_at', 'ASC']]
    });

    if (availableVolunteers.length < volunteerCount) {
      return res.status(400).json({ 
        message: `Only ${availableVolunteers.length} volunteers available, but ${volunteerCount} requested` 
      });
    }

    // Start a transaction
    const result = await sequelize.transaction(async (t) => {
      // Update donation volunteer_count
      console.log('Before update - donation.volunteer_count:', donation.volunteer_count, 'adding:', volunteerCount);
      await donation.update({
        volunteer_count: donation.volunteer_count + volunteerCount
      }, { transaction: t });
      console.log('After update - donation.volunteer_count:', donation.volunteer_count);

      // Create volunteer requests
      const requests = [];
      for (const volunteer of availableVolunteers) {
        const volunteerRequest = await VolunteerRequest.create({
          donation_id: id,
          organization_id: req.user.id,
          volunteer_id: volunteer.id,
          message: message || `Volunteer needed for donation: ${donation.title}`,
          status: 'pending'
        }, { transaction: t });

        requests.push(volunteerRequest);
      }

      return requests;
    });

    // Get the requests with associations
    const requestsWithDetails = await VolunteerRequest.findAll({
      where: { id: { [Op.in]: result.map(r => r.id) } },
      include: [
        { model: User, as: 'volunteer', attributes: ['id', 'username', 'first_name', 'last_name'] },
        { model: Donation, as: 'donation', attributes: ['id', 'title', 'status', 'volunteer_count'] },
      ]
    });

    // TODO: Emit socket event to notify volunteers

    res.status(201).json({
      message: `${volunteerCount} volunteer requests sent successfully`,
      requests: requestsWithDetails,
      updatedDonation: await Donation.findByPk(id, {
        attributes: ['id', 'volunteer_count']
      })
    });
  } catch (error) {
    console.error('Error requesting multiple volunteers:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Request a volunteer for a claimed donation
const requestVolunteer = async (req, res) => {
  try {
    const { id } = req.params;
    const { volunteerId, message } = req.body;

    const donation = await Donation.findByPk(id);
    const volunteer = await User.findByPk(volunteerId);

    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    if (!volunteer || volunteer.role !== 'volunteer') {
      return res.status(400).json({ message: 'Invalid volunteer' });
    }

    if (donation.organization_id !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to request volunteer for this donation' });
    }

    if (donation.status !== 'claiming' && donation.status !== 'in_transit') {
      return res.status(400).json({ message: 'Can only request volunteers for donations in claiming or in_transit status' });
    }

    // Check if a request already exists
    const existingRequest = await VolunteerRequest.findOne({
      where: {
        donation_id: id,
        volunteer_id,
      }
    });

    if (existingRequest) {
      return res.status(400).json({ 
        message: 'A volunteer request already exists for this donation and volunteer',
        request: existingRequest
      });
    }

    // Create volunteer request
    const volunteerRequest = await VolunteerRequest.create({
      donation_id: id,
      organization_id: req.user.id,
      volunteer_id,
      message,
      status: 'pending'
    });

    // Get the request with associations
    const requestWithDetails = await VolunteerRequest.findByPk(volunteerRequest.id, {
      include: [
        { model: User, as: 'volunteer', attributes: ['id', 'username', 'first_name', 'last_name'] },
        { model: Donation, attributes: ['id', 'title', 'status'] },
      ]
    });

    // TODO: Emit socket event to notify volunteer

    res.status(201).json({
      message: 'Volunteer request sent successfully',
      request: requestWithDetails
    });
  } catch (error) {
    console.error('Error requesting volunteer:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Get all claimed donations for an organization
const getClaimedDonations = async (req, res) => {
  try {
    const { status } = req.query;
    
    const whereClause = {
      organization_id: req.user.id,
      status: {
        [Op.in]: ['claiming', 'in_transit', 'completed', 'cancelled']
      }
    };

    if (status && ['claiming', 'in_transit', 'completed', 'cancelled'].includes(status)) {
      whereClause.status = status;
    }

    const donations = await Donation.findAll({
      where: whereClause,
      include: [
        { model: User, as: 'donor', attributes: ['id', 'username', 'first_name', 'last_name'] },
        { model: User, as: 'volunteer', attributes: ['id', 'username', 'first_name', 'last_name'] },
        { 
          model: VolunteerRequest, 
          as: 'volunteerRequests',
          include: [
            { model: User, as: 'volunteer', attributes: ['id', 'username', 'first_name', 'last_name'] }
          ]
        },
      ],
      order: [
        ['status', 'ASC'],
        ['updated_at', 'DESC']
      ],
    });

    res.json(donations);
  } catch (error) {
    console.error('Error fetching claimed donations:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Update donation status (e.g., to in_transit, completed, cancelled)
const updateDonationStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['in_transit', 'completed', 'cancelled'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    const donation = await Donation.findByPk(id);

    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    if (donation.organization_id !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to update this donation' });
    }

    // Validate status transition
    const validTransitions = {
      claiming: ['in_transit', 'cancelled'],
      in_transit: ['completed', 'cancelled'],
    };

    if (!validTransitions[donation.status] || !validTransitions[donation.status].includes(status)) {
      return res.status(400).json({ 
        message: `Cannot change status from ${donation.status} to ${status}` 
      });
    }

    await donation.update({ status });

    // If cancelled, release the donation back to available
    if (status === 'cancelled') {
      await donation.update({
        organization_id: null,
        volunteer_id: null,
        status: 'available'
      });
    }

    // TODO: Emit socket event for real-time update

    res.json({
      message: 'Donation status updated successfully',
      donation: await Donation.findByPk(id, {
        include: [
          { model: User, as: 'donor', attributes: ['id', 'username', 'first_name', 'last_name'] },
          { model: User, as: 'organization', attributes: ['id', 'username', 'first_name', 'last_name'] },
          { model: User, as: 'volunteer', attributes: ['id', 'username', 'first_name', 'last_name'] },
        ]
      })
    });
  } catch (error) {
    console.error('Error updating donation status:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

module.exports = {
  getAvailableDonations,
  claimDonation,
  requestVolunteer,
  requestMultipleVolunteers,
  getClaimedDonations,
  updateDonationStatus,
};
