const { sequelize } = require('./src/config/db');
const { User } = require('./src/models');

async function checkUsers() {
  try {
    const users = await User.findAll({
      attributes: ['id', 'username', 'email', 'role', 'created_at']
    });
    
    console.log('All users in database:');
    users.forEach(user => {
      console.log(`ID: ${user.id}, Username: ${user.username}, Role: ${user.role}, Email: ${user.email}`);
    });
    
    const volunteers = users.filter(u => u.role === 'volunteer');
    console.log(`\nTotal volunteers: ${volunteers.length}`);
    
    if (volunteers.length > 0) {
      console.log('\nVolunteer details:');
      volunteers.forEach(v => {
        console.log(`ID: ${v.id}, Username: ${v.username}`);
      });
    }
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

checkUsers();
