'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    // Update donation status enum
    await queryInterface.changeColumn('donations', 'status', {
      type: Sequelize.ENUM('available', 'claiming', 'in_transit', 'completed', 'cancelled', 'expired'),
      defaultValue: 'available',
      allowNull: false
    });

    // Add volunteer_count column to donations table
    await queryInterface.addColumn('donations', 'volunteer_count', {
      type: Sequelize.INTEGER,
      defaultValue: 0,
      allowNull: false,
      comment: 'Number of volunteers requested for this donation'
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
      message: {
        type: Sequelize.TEXT,
        allowNull: true,
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

    // Add indexes for volunteer_requests table
    await queryInterface.addIndex('volunteer_requests', ['donation_id']);
    await queryInterface.addIndex('volunteer_requests', ['organization_id']);
    await queryInterface.addIndex('volunteer_requests', ['volunteer_id']);
  },

  down: async (queryInterface, Sequelize) => {
    // Drop volunteer_requests table
    await queryInterface.dropTable('volunteer_requests');

    // Remove volunteer_count column
    await queryInterface.removeColumn('donations', 'volunteer_count');

    // Revert status enum
    await queryInterface.changeColumn('donations', 'status', {
      type: Sequelize.STRING(20),
      defaultValue: 'current',
      allowNull: false
    });
  }
};
