const { sequelize } = require('./src/config/db');
const { Donation, VolunteerRequest, User } = require('./src/models');

async function checkDonations() {
  try {
    console.log('Checking donations and their volunteer status...');
    
    const donations = await Donation.findAll({
      attributes: ['id', 'title', 'status', 'organization_id', 'volunteer_count'],
      include: [
        { 
          model: VolunteerRequest, 
          as: 'volunteerRequests',
          attributes: ['volunteer_id', 'status'],
          include: [
            { model: User, as: 'volunteer', attributes: ['id', 'username'] }
          ]
        }
      ]
    });
    
    console.log(`\nTotal donations: ${donations.length}`);
    
    donations.forEach(donation => {
      console.log(`\nDonation ID: ${donation.id}, Title: ${donation.title}, Status: ${donation.status}, Volunteer Count: ${donation.volunteer_count}`);
      console.log(`Organization ID: ${donation.organization_id}`);
      
      if (donation.volunteerRequests && donation.volunteerRequests.length > 0) {
        console.log('  Volunteer requests:');
        donation.volunteerRequests.forEach(req => {
          console.log(`    - Volunteer ID: ${req.volunteer_id}, Username: ${req.volunteer?.username}, Status: ${req.status}`);
        });
      } else {
        console.log('  No volunteer requests');
      }
    });
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

checkDonations();
