const { sequelize } = require('./src/config/db');
const { User, Donation, VolunteerRequest, Conversation, Message } = require('./src/models');

async function syncDatabase() {
  try {
    console.log('Syncing database...');
    
    // Force sync to drop and recreate tables (for development)
    await sequelize.sync({ force: false, alter: true });
    
    console.log('Database synced successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error syncing database:', error);
    process.exit(1);
  }
}

syncDatabase();
