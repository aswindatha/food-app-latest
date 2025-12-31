const { Op } = require('sequelize');
const VolunteerRequest = require('../models/VolunteerRequest');
const Donation = require('../models/Donation');
const User = require('../models/User');
const { DeliveryReview } = require('../models');

// Get volunteer requests for a volunteer
const getVolunteerRequests = async (req, res) => {
  try {
    const { status } = req.query;
    
    const whereClause = {
      volunteer_id: req.user.id,
    };

    if (status && ['pending', 'accepted', 'rejected'].includes(status)) {
      whereClause.status = status;
    }

    const requests = await VolunteerRequest.findAll({
      where: whereClause,
      include: [
        { 
          model: Donation,
          as: 'donation',
          attributes: ['id', 'title', 'description', 'donation_type', 'quantity', 'unit'],
          include: [
            { model: User, as: 'donor', attributes: ['id', 'username', 'first_name', 'last_name'] },
            { model: User, as: 'organization', attributes: ['id', 'username', 'first_name', 'last_name'] }
          ]
        },
        { model: User, as: 'organization', attributes: ['id', 'username', 'first_name', 'last_name'] }
      ],
      order: [['created_at', 'DESC']]
    });

    res.json(requests);
  } catch (error) {
    console.error('Error fetching volunteer requests:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Accept or reject a volunteer request
const respondToRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, message } = req.body;

    if (!['accepted', 'rejected'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    const request = await VolunteerRequest.findByPk(id, {
      include: [
        { 
          model: Donation, 
          as: 'donation',
          attributes: ['id', 'title', 'status']
        }
      ]
    });

    if (!request) {
      return res.status(404).json({ message: 'Volunteer request not found' });
    }

    if (request.volunteer_id !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to respond to this request' });
    }

    if (request.status !== 'pending') {
      return res.status(400).json({ message: 'Request has already been responded to' });
    }

    // Update the request status
    await request.update({ 
      status,
      message: message || null
    });

    // If accepted, update the donation
    if (status === 'accepted') {
      await request.donation.update({
        volunteer_id: req.user.id,
        status: 'in_transit'
      });
    }

    // Get the updated request with associations
    const updatedRequest = await VolunteerRequest.findByPk(id, {
      include: [
        { 
          model: Donation, 
          as: 'donation',
          attributes: ['id', 'title', 'status'],
          include: [
            { model: User, as: 'donor', attributes: ['id', 'username', 'first_name', 'last_name'] },
            { model: User, as: 'organization', attributes: ['id', 'username', 'first_name', 'last_name'] }
          ]
        },
        { model: User, as: 'organization', attributes: ['id', 'username', 'first_name', 'last_name'] }
      ]
    });

    // TODO: Emit socket event to notify organization

    res.json({
      message: `Volunteer request ${status} successfully`,
      request: updatedRequest
    });
  } catch (error) {
    console.error('Error responding to volunteer request:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Get volunteer's assigned donations
const getAssignedDonations = async (req, res) => {
  try {
    const { status } = req.query;
    
    const whereClause = {
      volunteer_id: req.user.id,
      status: {
        [Op.in]: ['in_transit', 'completed']
      }
    };

    if (status && ['in_transit', 'completed'].includes(status)) {
      whereClause.status = status;
    }

    const donations = await Donation.findAll({
      where: whereClause,
      include: [
        { model: User, as: 'donor', attributes: ['id', 'username', 'first_name', 'last_name'] },
        { model: User, as: 'organization', attributes: ['id', 'username', 'first_name', 'last_name'] }
      ],
      order: [['updated_at', 'DESC']]
    });

    res.json(donations);
  } catch (error) {
    console.error('Error fetching assigned donations:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Update donation status (mark as completed)
const updateDonationStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['completed'].includes(status)) {
      return res.status(400).json({ message: 'Volunteers can only mark donations as completed' });
    }

    const donation = await Donation.findByPk(id);

    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    if (donation.volunteer_id !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to update this donation' });
    }

    if (donation.status !== 'in_transit') {
      return res.status(400).json({ message: 'Can only complete donations that are in transit' });
    }

    await donation.update({ status });

    // TODO: Emit socket event for real-time update

    res.json({
      message: 'Donation marked as completed successfully',
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

// Get completed deliveries for volunteer
const getCompletedDeliveries = async (req, res) => {
  try {
    const donations = await Donation.findAll({
      where: {
        volunteer_id: req.user.id,
        status: 'completed'
      },
      include: [
        { model: User, as: 'donor', attributes: ['id', 'username', 'first_name', 'last_name'] },
        { model: User, as: 'organization', attributes: ['id', 'username', 'first_name', 'last_name'] },
        { 
          model: DeliveryReview, 
          as: 'reviews',
          required: false,
          where: { volunteer_id: req.user.id }
        }
      ],
      order: [['updated_at', 'DESC']]
    });

    res.json({ success: true, donations });
  } catch (error) {
    console.error('Error fetching completed deliveries:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Submit delivery review
const submitDeliveryReview = async (req, res) => {
  const { id } = req.params;
  const { rating, review_text } = req.body;

  try {
    const donation = await Donation.findByPk(id);

    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    if (donation.volunteer_id !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to review this donation' });
    }

    if (donation.status !== 'completed') {
      return res.status(400).json({ message: 'Can only review completed donations' });
    }

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ message: 'Rating must be between 1 and 5' });
    }

    // Check if review already exists
    const existingReview = await DeliveryReview.findOne({
      where: {
        donation_id: id,
        volunteer_id: req.user.id
      }
    });

    if (existingReview) {
      return res.status(400).json({ message: 'Review already exists for this donation' });
    }

    const review = await DeliveryReview.create({
      donation_id: id,
      volunteer_id: req.user.id,
      rating,
      review_text
    });

    res.status(201).json({ 
      success: true, 
      message: 'Review submitted successfully',
      review 
    });
  } catch (error) {
    console.error('Error submitting review:', error);
    res.status(500).json({ message: 'An error occurred while submitting review' });
  }
};

module.exports = {
  getVolunteerRequests,
  respondToRequest,
  getAssignedDonations,
  updateDonationStatus,
  getCompletedDeliveries,
  submitDeliveryReview,
};
