const { sequelize } = require('./src/config/db');
const { Donation, User, VolunteerRequest } = require('./src/models');

async function createInTransitDonation() {
  try {
    // Get a donor user
    const donor = await User.findOne({ where: { role: 'donor' } });
    const org = await User.findOne({ where: { role: 'organization' } });
    const volunteer = await User.findOne({ where: { role: 'volunteer' } });

    if (!donor || !org || !volunteer) {
      console.log('Missing users. Creating test donation...');
      return;
    }

    // Create a donation in transit status
    const donation = await Donation.create({
      donor_id: donor.id,
      title: 'Test In Transit Donation',
      description: 'This is a test donation in transit',
      donation_type: 'FOOD',
      quantity: 5,
      unit: 'kg',
      expiry_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
      pickup_address: 'Test Address',
      status: 'in_transit',
      organization_id: org.id,
      volunteer_id: volunteer.id
    });

    console.log('Created in-transit donation:', donation.id);

    // Create volunteer requests for testing dropdown
    const volunteer2 = await User.findOne({ where: { role: 'volunteer', id: { [require('sequelize').Op.ne]: volunteer.id } } });
    
    if (volunteer2) {
      await VolunteerRequest.create({
        donation_id: donation.id,
        organization_id: org.id,
        volunteer_id: volunteer2.id,
        status: 'accepted'
      });
      
      await VolunteerRequest.create({
        donation_id: donation.id,
        organization_id: org.id,
        volunteer_id: volunteer.id,
        status: 'accepted'
      });

      console.log('Created volunteer requests for dropdown testing');
    }

    console.log('Test data created successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

createInTransitDonation();
