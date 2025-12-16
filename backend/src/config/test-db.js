const { Sequelize, DataTypes } = require('sequelize');
require('dotenv').config();

// Use SQLite for testing
const sequelize = new Sequelize('sqlite::memory:', {
  logging: false, // Disable logging for tests
  define: {
    timestamps: true,
    underscored: true,
  },
});

module.exports = { sequelize, DataTypes };
