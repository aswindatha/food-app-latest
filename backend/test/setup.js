const { sequelize } = require('../src/config/test-db');
const User = require('../src/models/User');

// Set environment to test
process.env.NODE_ENV = 'test';

// Setup test database
const setupTestDB = async () => {
  try {
    // Sync all models
    await sequelize.sync({ force: true });
    console.log('Test database synced');
  } catch (error) {
    console.error('Error setting up test database:', error);
    throw error;
  }
};

// Clean up after tests
const cleanupTestDB = async () => {
  try {
    // Close database connection
    await sequelize.close();
    console.log('Test database connection closed');
  } catch (error) {
    console.error('Error cleaning up test database:', error);
    throw error;
  }
};

// Global test hooks
beforeAll(async () => {
  try {
    await setupTestDB();
  } catch (error) {
    console.error('Error in beforeAll:', error);
    throw error;
  }
}, 30000); // Increase timeout for database setup

afterAll(async () => {
  try {
    await cleanupTestDB();
  } catch (error) {
    console.error('Error in afterAll:', error);
    throw error;
  }
}, 30000); // Increase timeout for database teardown

// Helper function to clear all tables
const clearDatabase = async () => {
  try {
    // Drop and recreate all tables
    await sequelize.sync({ force: true });
  } catch (error) {
    console.error('Error clearing database:', error);
    throw error;
  }
};

// Helper functions for tests
const createTestUser = async (userData = {}) => {
  const defaultUser = {
    username: `testuser_${Date.now()}`,
    email: `test_${Date.now()}@example.com`,
    password: 'password123',
    first_name: 'Test',
    last_name: 'User',
    role: 'donor'
  };
  
  try {
    const user = await User.create({ ...defaultUser, ...userData });
    return user.toJSON();
  } catch (error) {
    console.error('Error creating test user:', error);
    throw error;
  }
};

// Helper function to create user with plain password (for login tests)
const createTestUserWithPassword = async (userData = {}) => {
  const defaultUser = {
    username: `testuser_${Date.now()}`,
    email: `test_${Date.now()}@example.com`,
    password_hash: 'password123', // Will be hashed by the model hook
    first_name: 'Test',
    last_name: 'User',
    role: 'donor'
  };
  
  try {
    const user = await User.create({ ...defaultUser, ...userData });
    return user.toJSON();
  } catch (error) {
    console.error('Error creating test user with password:', error);
    throw error;
  }
};

module.exports = {
  createTestUser,
  createTestUserWithPassword,
  clearDatabase
};
