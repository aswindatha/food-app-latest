const { Op } = require('sequelize');
const { User, Donation, VolunteerRequest, DeliveryReview } = require('../models');

// Get admin dashboard stats
const getDashboardStats = async (req, res) => {
  try {
    // Get total counts
    const totalUsers = await User.count();
    const totalDonations = await Donation.count();
    const totalVolunteerRequests = await VolunteerRequest.count();
    const totalReviews = await DeliveryReview.count();

    // Get donation status breakdown
    const donationStatuses = await Donation.findAll({
      attributes: [
        'status',
        [require('sequelize').fn('COUNT', require('sequelize').col('id')), 'count']
      ],
      group: ['status']
    });

    // Get user role breakdown
    const userRoles = await User.findAll({
      attributes: [
        'role',
        [require('sequelize').fn('COUNT', require('sequelize').col('id')), 'count']
      ],
      group: ['role']
    });

    // Get recent donations
    const recentDonations = await Donation.findAll({
      limit: 10,
      order: [['created_at', 'DESC']],
      include: [
        { model: User, as: 'donor', attributes: ['username', 'first_name', 'last_name'] },
        { model: User, as: 'volunteer', attributes: ['username', 'first_name', 'last_name'] }
      ]
    });

    // Get monthly donation trends (last 6 months)
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    
    const monthlyTrends = await Donation.findAll({
      attributes: [
        [require('sequelize').fn('YEAR', require('sequelize').col('created_at')), 'year'],
        [require('sequelize').fn('MONTH', require('sequelize').col('created_at')), 'month'],
        [require('sequelize').fn('COUNT', require('sequelize').col('id')), 'count']
      ],
      where: {
        created_at: { [Op.gte]: sixMonthsAgo }
      },
      group: [
        [require('sequelize').fn('YEAR', require('sequelize').col('created_at'))],
        [require('sequelize').fn('MONTH', require('sequelize').col('created_at'))]
      ],
      order: [
        [require('sequelize').fn('YEAR', require('sequelize').col('created_at')), 'ASC'],
        [require('sequelize').fn('MONTH', require('sequelize').col('created_at')), 'ASC']
      ]
    });

    res.json({
      success: true,
      data: {
        overview: {
          totalUsers,
          totalDonations,
          totalVolunteerRequests,
          totalReviews
        },
        donationStatuses: donationStatuses.map(item => ({
          status: item.status,
          count: parseInt(item.dataValues.count)
        })),
        userRoles: userRoles.map(item => ({
          role: item.role,
          count: parseInt(item.dataValues.count)
        })),
        recentDonations: recentDonations.map(donation => ({
          id: donation.id,
          title: donation.title,
          status: donation.status,
          quantity: donation.quantity,
          unit: donation.unit,
          createdAt: donation.created_at,
          donor: donation.donor,
          volunteer: donation.volunteer
        })),
        monthlyTrends: monthlyTrends.map(item => ({
          year: parseInt(item.dataValues.year),
          month: parseInt(item.dataValues.month),
          count: parseInt(item.dataValues.count)
        }))
      }
    });
  } catch (error) {
    console.error('Error getting dashboard stats:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Get all users with filtering and sorting
const getAllUsers = async (req, res) => {
  try {
    const { page = 1, limit = 10, sortBy = 'created_at', sortOrder = 'DESC', role, search } = req.query;
    
    const offset = (parseInt(page) - 1) * parseInt(limit);
    
    const whereClause = {};
    
    if (role) {
      whereClause.role = role;
    }
    
    if (search) {
      whereClause[Op.or] = [
        { username: { [Op.like]: `%${search}%` } },
        { email: { [Op.like]: `%${search}%` } },
        { first_name: { [Op.like]: `%${search}%` } },
        { last_name: { [Op.like]: `%${search}%` } }
      ];
    }

    const users = await User.findAndCountAll({
      where: whereClause,
      attributes: { exclude: ['password_hash'] },
      limit: parseInt(limit),
      offset,
      order: [[sortBy, sortOrder.toUpperCase()]],
      include: [
        {
          model: Donation,
          as: 'donatedItems',
          attributes: ['id']
        }
      ]
    });

    res.json({
      success: true,
      data: {
        users: users.rows,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(users.count / parseInt(limit)),
          totalItems: users.count,
          itemsPerPage: parseInt(limit)
        }
      }
    });
  } catch (error) {
    console.error('Error getting users:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Get all donations with filtering and sorting
const getAllDonations = async (req, res) => {
  try {
    const { page = 1, limit = 10, sortBy = 'created_at', sortOrder = 'DESC', status, search } = req.query;
    
    const offset = (parseInt(page) - 1) * parseInt(limit);
    
    const whereClause = {};
    
    if (status) {
      whereClause.status = status;
    }
    
    if (search) {
      whereClause[Op.or] = [
        { title: { [Op.like]: `%${search}%` } },
        { description: { [Op.like]: `%${search}%` } },
        { donation_type: { [Op.like]: `%${search}%` } }
      ];
    }

    const donations = await Donation.findAndCountAll({
      where: whereClause,
      limit: parseInt(limit),
      offset,
      order: [[sortBy, sortOrder.toUpperCase()]],
      include: [
        { model: User, as: 'donor', attributes: ['username', 'first_name', 'last_name'] },
        { model: User, as: 'volunteer', attributes: ['username', 'first_name', 'last_name'] },
        { model: User, as: 'organization', attributes: ['username', 'first_name', 'last_name'] }
      ]
    });

    res.json({
      success: true,
      data: {
        donations: donations.rows,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(donations.count / parseInt(limit)),
          totalItems: donations.count,
          itemsPerPage: parseInt(limit)
        }
      }
    });
  } catch (error) {
    console.error('Error getting donations:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Update user details
const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { username, email, first_name, last_name, role, phone } = req.body;
    
    const user = await User.findByPk(id);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Update user fields
    const updateData = {};
    if (username) updateData.username = username;
    if (email) updateData.email = email;
    if (first_name) updateData.first_name = first_name;
    if (last_name) updateData.last_name = last_name;
    if (role) updateData.role = role;
    if (phone) updateData.phone = phone;

    await user.update(updateData);

    res.json({
      success: true,
      message: 'User updated successfully',
      data: { id: user.id, ...updateData }
    });
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Update donation details
const updateDonation = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, donation_type, quantity, unit, expiry_date, pickup_address, pickup_time, status } = req.body;
    
    const donation = await Donation.findByPk(id);
    
    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    // Update donation fields
    const updateData = {};
    if (title) updateData.title = title;
    if (description) updateData.description = description;
    if (donation_type) updateData.donation_type = donation_type;
    if (quantity) updateData.quantity = quantity;
    if (unit) updateData.unit = unit;
    if (expiry_date) updateData.expiry_date = expiry_date;
    if (pickup_address) updateData.pickup_address = pickup_address;
    if (pickup_time) updateData.pickup_time = pickup_time;
    if (status) updateData.status = status;

    await donation.update(updateData);

    res.json({
      success: true,
      message: 'Donation updated successfully',
      data: { id: donation.id, ...updateData }
    });
  } catch (error) {
    console.error('Error updating donation:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Delete user
const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;
    
    const user = await User.findByPk(id);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    await user.destroy();

    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

// Delete donation
const deleteDonation = async (req, res) => {
  try {
    const { id } = req.params;
    
    const donation = await Donation.findByPk(id);
    
    if (!donation) {
      return res.status(404).json({ message: 'Donation not found' });
    }

    await donation.destroy();

    res.json({
      success: true,
      message: 'Donation deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting donation:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

module.exports = {
  getDashboardStats,
  getAllUsers,
  getAllDonations,
  updateUser,
  updateDonation,
  deleteUser,
  deleteDonation
};
