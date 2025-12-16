const Donation = require('../models/Donation');
const User = require('../models/User');
const Conversation = require('../models/Conversation');
const Message = require('../models/Message');

// Create a new donation
const createDonation = async (req, res) => {
  try {
    // Only donors can create donations
    if (req.user.role !== 'donor') {
      return res.status(403).json({ message: 'Only donors can create donations' });
    }

    const {
      title,
      description,
      donation_type,
      quantity,
      unit,
      expiry_date,
      pickup_address,
      pickup_time,
      image_url
    } = req.body;

    // Validate required fields
    if (!title || !donation_type || !quantity || !unit || !expiry_date || !pickup_address) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const donation = await Donation.create({
      donor_id: req.user.id,
      title,
      description,
      donation_type,
      quantity,
      unit,
      expiry_date,
      pickup_address,
      pickup_time,
      image_url,
      status: 'available' // New donations start as available
    });

    // Include donor information in response
    const donationWithDetails = await Donation.findByPk(donation.id, {
      include: [
        { model: User, as: 'donor', attributes: ['id', 'username', 'first_name', 'last_name'] }
      ]
    });

    res.status(201).json(donationWithDetails);
  } catch (error) {
    console.error('Error creating donation:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Get all donations for a donor (ordered by status)
const getDonorDonations = async (req, res) => {
  try {
    const donations = await Donation.findAll({
      where: { donor_id: req.user.id },
      include: [
        { model: User, as: 'donor', attributes: ['id', 'username', 'first_name', 'last_name'] },
        { model: User, as: 'volunteer', attributes: ['id', 'username', 'first_name', 'last_name'] },
        { model: User, as: 'organization', attributes: ['id', 'username', 'first_name', 'last_name'] }
      ],
      order: [
        ['status', 'ASC'], // available first, then claiming, in_transit, completed, cancelled
        ['created_at', 'DESC']
      ]
    });

    res.json(donations);
  } catch (error) {
    console.error('Error fetching donor donations:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Get a single donation by ID
const getDonationById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const donation = await Donation.findByPk(id, {
      include: [
        { model: User, as: 'donor', attributes: ['id', 'username', 'first_name', 'last_name'] },
        { model: User, as: 'volunteer', attributes: ['id', 'username', 'first_name', 'last_name'] },
        { model: User, as: 'organization', attributes: ['id', 'username', 'first_name', 'last_name'] }
      ]
    });

    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    // Check if user is authorized to view this donation
    if (donation.donor_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Not authorized to view this donation' });
    }

    res.json(donation);
  } catch (error) {
    console.error('Error fetching donation:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Update a donation
const updateDonation = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      title,
      description,
      donation_type,
      quantity,
      unit,
      expiry_date,
      pickup_address,
      pickup_time,
      image_url
    } = req.body;

    const donation = await Donation.findByPk(id);

    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    // Check if user is authorized to edit this donation
    if (donation.donor_id !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to edit this donation' });
    }

    // Check if donation can be edited (not donated or expired)
    if (donation.status !== 'current') {
      return res.status(400).json({ message: 'Cannot edit donated or expired donations' });
    }

    // Update donation
    await donation.update({
      title,
      description,
      donation_type,
      quantity,
      unit,
      expiry_date,
      pickup_address,
      pickup_time,
      image_url
    });

    // Return updated donation with details
    const updatedDonation = await Donation.findByPk(id, {
      include: [
        { model: User, as: 'donor', attributes: ['id', 'username', 'first_name', 'last_name'] }
      ]
    });

    res.json(updatedDonation);
  } catch (error) {
    console.error('Error updating donation:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Delete a donation
const deleteDonation = async (req, res) => {
  try {
    const { id } = req.params;

    const donation = await Donation.findByPk(id);

    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    // Check if user is authorized to delete this donation
    if (donation.donor_id !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to delete this donation' });
    }

    // Check if donation can be deleted (not donated or expired)
    if (donation.status !== 'current') {
      return res.status(400).json({ message: 'Cannot delete donated or expired donations' });
    }

    await donation.destroy();

    res.json({ message: 'Donation deleted successfully' });
  } catch (error) {
    console.error('Error deleting donation:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Get all available donations for volunteers and organizations
const getAvailableDonations = async (req, res) => {
  try {
    const donations = await Donation.findAll({
      where: { 
        status: 'available',
        organization_id: null
      },
      include: [
        { model: User, as: 'donor', attributes: ['id', 'username', 'first_name', 'last_name'] }
      ],
      order: [['created_at', 'DESC']]
    });

    res.json(donations);
  } catch (error) {
    console.error('Error fetching available donations:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Assign volunteer to donation
const assignVolunteer = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (req.user.role !== 'volunteer') {
      return res.status(403).json({ message: 'Only volunteers can be assigned to donations' });
    }

    const donation = await Donation.findByPk(id);

    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    if (donation.status !== 'current') {
      return res.status(400).json({ message: 'Cannot assign to non-current donations' });
    }

    await donation.update({ volunteer_id: req.user.id });

    res.json({ message: 'Volunteer assigned successfully' });
  } catch (error) {
    console.error('Error assigning volunteer:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Mark donation as donated
const markAsDonated = async (req, res) => {
  try {
    const { id } = req.params;
    
    const donation = await Donation.findByPk(id);

    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    // Check if user is authorized (donor, assigned volunteer, or admin)
    const isAuthorized = donation.donor_id === req.user.id || 
                        donation.volunteer_id === req.user.id || 
                        req.user.role === 'admin';

    if (!isAuthorized) {
      return res.status(403).json({ message: 'Not authorized to mark this donation as donated' });
    }

    await donation.update({ status: 'donated' });

    res.json({ message: 'Donation marked as donated' });
  } catch (error) {
    console.error('Error marking donation as donated:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

module.exports = {
  createDonation,
  getDonorDonations,
  getDonationById,
  updateDonation,
  deleteDonation,
  getAvailableDonations,
  assignVolunteer,
  markAsDonated,
};
