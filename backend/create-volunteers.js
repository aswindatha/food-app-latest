const { sequelize } = require('./src/config/db');
const { User } = require('./src/models');

async function createVolunteers() {
  try {
    const volunteers = [
      { username: 'volunteer2', email: 'volunteer2@example.com', password_hash: 'password123', first_name: 'John', last_name: 'Doe', role: 'volunteer' },
      { username: 'volunteer3', email: 'volunteer3@example.com', password_hash: 'password123', first_name: 'Jane', last_name: 'Smith', role: 'volunteer' },
      { username: 'volunteer4', email: 'volunteer4@example.com', password_hash: 'password123', first_name: 'Mike', last_name: 'Johnson', role: 'volunteer' }
    ];
    
    for (const volunteerData of volunteers) {
      try {
        const volunteer = await User.create(volunteerData);
        console.log(`Created volunteer: ${volunteer.username} (ID: ${volunteer.id})`);
      } catch (error) {
        if (error.name === 'SequelizeUniqueConstraintError') {
          console.log(`Volunteer ${volunteerData.username} already exists`);
        } else {
          console.error(`Error creating volunteer ${volunteerData.username}:`, error.message);
        }
      }
    }
    
    console.log('\nChecking total volunteers now...');
    const allVolunteers = await User.findAll({
      where: { role: 'volunteer' },
      attributes: ['id', 'username', 'email']
    });
    
    console.log(`Total volunteers: ${allVolunteers.length}`);
    allVolunteers.forEach(v => {
      console.log(`ID: ${v.id}, Username: ${v.username}, Email: ${v.email}`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

createVolunteers();
