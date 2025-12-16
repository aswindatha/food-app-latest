'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    // Update donation status enum
    await queryInterface.changeColumn('donations', 'status', {
      type: Sequelize.ENUM('available', 'claiming', 'in_transit', 'completed', 'cancelled'),
      defaultValue: 'available',
      allowNull: false
    });

    // Create volunteer_requests table
    await queryInterface.createTable('volunteer_requests', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      donation_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'donations',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      organization_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      volunteer_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      status: {
        type: Sequelize.ENUM('pending', 'accepted', 'rejected'),
        defaultValue: 'pending',
        allowNull: false,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
    });

    // Add index for faster lookups
    await queryInterface.addIndex('volunteer_requests', ['donation_id']);
    await queryInterface.addIndex('volunteer_requests', ['organization_id']);
    await queryInterface.addIndex('volunteer_requests', ['volunteer_id']);
  },

  down: async (queryInterface, Sequelize) => {
    // Revert status enum
    await queryInterface.changeColumn('donations', 'status', {
      type: Sequelize.STRING(20),
      defaultValue: 'current',
      allowNull: false
    });

    // Drop volunteer_requests table
    await queryInterface.dropTable('volunteer_requests');
  }
};
