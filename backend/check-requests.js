const { sequelize } = require('./src/config/db');
const { VolunteerRequest, Donation } = require('./src/models');

async function checkRequests() {
  try {
    console.log('Checking volunteer requests...');
    
    const requests = await VolunteerRequest.findAll({
      attributes: ['id', 'donation_id', 'volunteer_id', 'organization_id', 'status'],
      include: [
        { model: Donation, as: 'donation', attributes: ['id', 'title', 'status'] }
      ]
    });
    
    console.log(`\nTotal volunteer requests: ${requests.length}`);
    
    if (requests.length > 0) {
      console.log('\nExisting requests:');
      requests.forEach(req => {
        console.log(`Request ID: ${req.id}, Donation ID: ${req.donation_id}, Volunteer ID: ${req.volunteer_id}, Status: ${req.status}, Donation: ${req.donation?.title}`);
      });
    }
    
    // Check for a specific donation if provided
    const donationId = process.argv[2];
    if (donationId) {
      console.log(`\nChecking requests for donation ID: ${donationId}`);
      const donationRequests = await VolunteerRequest.findAll({
        where: { donation_id: donationId },
        attributes: ['volunteer_id', 'status']
      });
      
      console.log(`Requests for donation ${donationId}:`);
      donationRequests.forEach(req => {
        console.log(`Volunteer ID: ${req.volunteer_id}, Status: ${req.status}`);
      });
      
      const existingVolunteerIds = donationRequests.map(r => r.volunteer_id);
      console.log(`Existing volunteer IDs: [${existingVolunteerIds.join(', ')}]`);
    }
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

checkRequests();
