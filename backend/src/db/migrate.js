const { Sequelize } = require('sequelize');
require('dotenv').config();

async function runMigration() {
  // Connect directly to the target database
  const { sequelize } = require('../config/db');
  const User = require('../models/User');
  const Donation = require('../models/Donation');
  const Conversation = require('../models/Conversation');
  const Message = require('../models/Message');
  const VolunteerRequest = require('../models/VolunteerRequest');
  
  try {
    // Test the connection
    await sequelize.authenticate();
    console.log('Database connection has been established successfully.');
    
    // Sync all models with force: true to drop and recreate tables
    console.log('Syncing database models...');
    await sequelize.sync({ force: true });
    console.log('Database synced successfully');
    
    // Add sample data
    console.log('Adding sample data...');
    await addSampleData();
    console.log('Sample data added successfully');
    
  } catch (error) {
    console.error('Error during migration:', error);
    process.exit(1);
  } finally {
    await sequelize.close();
    console.log('Migration completed');
  }
}

async function addSampleData() {
  const User = require('../models/User');
  const Donation = require('../models/Donation');
  const bcrypt = require('bcryptjs');
  
  const users = [
    {
      username: 'donor1',
      email: 'donor1@example.com',
      password_hash: await bcrypt.hash('password123', 10),
      first_name: 'John',
      last_name: 'Doe',
      role: 'donor'
    },
    {
      username: 'volunteer1',
      email: 'volunteer1@example.com',
      password_hash: await bcrypt.hash('password123', 10),
      first_name: 'Jane',
      last_name: 'Smith',
      role: 'volunteer'
    },
    {
      username: 'org1',
      email: 'org1@example.com',
      password_hash: await bcrypt.hash('password123', 10),
      first_name: 'Food',
      last_name: 'Bank',
      role: 'organization'
    }
  ];
  
  try {
    const createdUsers = await User.bulkCreate(users);
    console.log('Successfully added sample users');
    
    // Add sample donations
    const donations = [
      {
        donor_id: createdUsers[0].id, // John Doe (donor)
        title: 'Fresh Vegetables',
        description: 'Fresh organic vegetables from my garden',
        donation_type: 'FOOD',
        quantity: 5,
        unit: 'kg',
        expiry_date: new Date(Date.now() + 6 * 60 * 60 * 1000), // 6 hours from now
        pickup_address: '123 Main St, City, State 12345',
        pickup_time: new Date(Date.now() + 2 * 60 * 60 * 1000), // 2 hours from now
        status: 'available'
      },
      {
        donor_id: createdUsers[0].id, // John Doe (donor)
        title: 'Canned Goods',
        description: 'Various canned foods including beans, tomatoes, and soup',
        donation_type: 'FOOD',
        quantity: 20,
        unit: 'cans',
        expiry_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
        pickup_address: '123 Main St, City, State 12345',
        pickup_time: new Date(Date.now() + 24 * 60 * 60 * 1000), // 1 day from now
        status: 'available'
      },
      {
        donor_id: createdUsers[0].id, // John Doe (donor)
        title: 'Bread and Pastries',
        description: 'Freshly baked bread and pastries from local bakery',
        donation_type: 'FOOD',
        quantity: 15,
        unit: 'items',
        expiry_date: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000), // 2 days from now
        pickup_address: '456 Oak Ave, City, State 12345',
        pickup_time: new Date(Date.now() + 6 * 60 * 60 * 1000), // 6 hours from now
        status: 'completed',
        volunteer_id: createdUsers[1].id // Jane Smith (volunteer)
      }
    ];
    
    await Donation.bulkCreate(donations);
    console.log('Successfully added sample donations');
    
  } catch (error) {
    console.error('Error adding sample data:', error);
    throw error;
  }
}

runMigration().catch(console.error);
