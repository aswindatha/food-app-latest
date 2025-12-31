const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const DonationProof = sequelize.define('DonationProof', {
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
    organization_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      },
      onDelete: 'CASCADE'
    },
    image_url: {
      type: DataTypes.TEXT,
      allowNull: false,
      validate: {
        isUrl: {
          msg: 'Image URL must be a valid URL'
        }
      }
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true
    }
  }, {
    tableName: 'donation_proofs',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  // Define associations
  DonationProof.associate = (models) => {
    DonationProof.belongsTo(models.Donation, { foreignKey: 'donation_id', as: 'donation' });
    DonationProof.belongsTo(models.User, { foreignKey: 'organization_id', as: 'organization' });
  };

  return DonationProof;
};
