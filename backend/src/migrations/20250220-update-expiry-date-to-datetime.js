'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    try {
      // Change expiry_date from DATE to DATETIME
      await queryInterface.changeColumn('donations', 'expiry_date', {
        type: Sequelize.DATE,
        allowNull: false,
      });
      console.log('Successfully changed expiry_date to DATETIME');
    } catch (error) {
      console.error('Error changing expiry_date column:', error);
      throw error;
    }
  },

  down: async (queryInterface, Sequelize) => {
    try {
      // Revert back to DATE type
      await queryInterface.changeColumn('donations', 'expiry_date', {
        type: Sequelize.DATEONLY,
        allowNull: false,
      });
      console.log('Successfully reverted expiry_date to DATE');
    } catch (error) {
      console.error('Error reverting expiry_date column:', error);
      throw error;
    }
  }
};
