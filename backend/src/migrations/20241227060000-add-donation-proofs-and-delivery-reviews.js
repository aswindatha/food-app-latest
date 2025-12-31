'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    // Create donation_proofs table
    await queryInterface.createTable('donation_proofs', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true
      },
      donation_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'donations',
          key: 'id'
        },
        onDelete: 'CASCADE'
      },
      organization_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id'
        },
        onDelete: 'CASCADE'
      },
      image_url: {
        type: Sequelize.TEXT,
        allowNull: false
      },
      description: {
        type: Sequelize.TEXT,
        allowNull: true
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      }
    });

    // Create delivery_reviews table
    await queryInterface.createTable('delivery_reviews', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true
      },
      donation_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'donations',
          key: 'id'
        },
        onDelete: 'CASCADE'
      },
      volunteer_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id'
        },
        onDelete: 'CASCADE'
      },
      rating: {
        type: Sequelize.INTEGER,
        allowNull: false,
        validate: {
          min: 1,
          max: 5
        }
      },
      review_text: {
        type: Sequelize.TEXT,
        allowNull: true
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      }
    });

    // Add indexes
    await queryInterface.addIndex('donation_proofs', ['donation_id']);
    await queryInterface.addIndex('donation_proofs', ['organization_id']);
    await queryInterface.addIndex('delivery_reviews', ['donation_id']);
    await queryInterface.addIndex('delivery_reviews', ['volunteer_id']);
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('delivery_reviews');
    await queryInterface.dropTable('donation_proofs');
  }
};
