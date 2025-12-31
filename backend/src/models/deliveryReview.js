const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const DeliveryReview = sequelize.define('DeliveryReview', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    donation_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'donations',
        key: 'id'
      },
      onDelete: 'CASCADE'
    },
    volunteer_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      },
      onDelete: 'CASCADE'
    },
    rating: {
      type: DataTypes.INTEGER,
      allowNull: false,
      validate: {
        min: {
          args: [1],
          msg: 'Rating must be at least 1'
        },
        max: {
          args: [5],
          msg: 'Rating must be at most 5'
        }
      }
    },
    review_text: {
      type: DataTypes.TEXT,
      allowNull: true
    }
  }, {
    tableName: 'delivery_reviews',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  DeliveryReview.associate = (models) => {
    DeliveryReview.belongsTo(models.Donation, { foreignKey: 'donation_id', as: 'donation' });
    DeliveryReview.belongsTo(models.User, { foreignKey: 'volunteer_id', as: 'volunteer' });
  };

  return DeliveryReview;
};
