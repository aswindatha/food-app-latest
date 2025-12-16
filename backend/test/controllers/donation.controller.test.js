const request = require('supertest');
const app = require('../../src/index');
const { createTestUser, clearDatabase } = require('../setup');

// Set JWT secret for testing
process.env.JWT_SECRET = 'test-secret-key';

describe('Donation Controller', () => {
  describe('POST /api/donations', () => {
    let donorAuthToken;
    let nonDonorAuthToken;
    
    // Get a date 7 days from now for the expiry date
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 7);
    const expiryDate = futureDate.toISOString().split('T')[0]; // Format as YYYY-MM-DD
    
    const testDonation = {
      title: 'Test Food Donation',
      description: 'Fresh fruits and vegetables',
      donation_type: 'FOOD', // Must be one of: 'FOOD', 'CLOTHES', 'MEDICINE', 'OTHER'
      quantity: 5,
      unit: 'kg',
      expiry_date: expiryDate,
      pickup_address: '123 Test St, Test City',
      pickup_time: '10:00',
      image_url: 'https://example.com/image.jpg'
    };
    
    console.log('Test donation data:', JSON.stringify(testDonation, null, 2));

    beforeAll(async () => {
      await clearDatabase();
      
      // Register a donor user
      const donorRegister = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'donoruser',
          email: 'donor@example.com',
          password: 'donorpass123',
          first_name: 'Donor',
          last_name: 'User',
          role: 'donor'
        });
      
      // Register a non-donor user (volunteer)
      const nonDonorRegister = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'volunteeruser',
          email: 'volunteer@example.com',
          password: 'volunteerpass123',
          first_name: 'Volunteer',
          last_name: 'User',
          role: 'volunteer'
        });
      
      if (donorRegister.statusCode !== 201 || nonDonorRegister.statusCode !== 201) {
        throw new Error('Failed to create test users');
      }
      
      // Login to get auth tokens
      const donorLogin = await request(app)
        .post('/api/auth/login')
        .send({ emailOrUsername: 'donor@example.com', password: 'donorpass123' });
      
      const nonDonorLogin = await request(app)
        .post('/api/auth/login')
        .send({ emailOrUsername: 'volunteer@example.com', password: 'volunteerpass123' });
      
      donorAuthToken = donorLogin.body.token;
      nonDonorAuthToken = nonDonorLogin.body.token;
    });

    afterAll(async () => {
      await clearDatabase();
    });

    it('should create a new donation (donor only)', async () => {
      const res = await request(app)
        .post('/api/donations')
        .set('Authorization', `Bearer ${donorAuthToken}`)
        .send(testDonation);
      
      expect(res.statusCode).toEqual(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body.title).toBe(testDonation.title);
      expect(res.body.status).toBe('available');
      expect(res.body.donor).toBeDefined();
    });

    it('should validate required fields', async () => {
      const requiredFields = ['title', 'donation_type', 'quantity', 'unit', 'expiry_date', 'pickup_address'];
      
      for (const field of requiredFields) {
        const incompleteDonation = { ...testDonation };
        delete incompleteDonation[field];
        
        const res = await request(app)
          .post('/api/donations')
          .set('Authorization', `Bearer ${donorAuthToken}`)
          .send(incompleteDonation);
        
        expect(res.statusCode).toEqual(400);
        expect(res.body).toHaveProperty('message', 'Missing required fields');
      }
    });

    it('should set status to available by default', async () => {
      // Explicitly set status to something else to ensure it's overridden
      const donationWithStatus = { ...testDonation, status: 'pending' };
      
      const res = await request(app)
        .post('/api/donations')
        .set('Authorization', `Bearer ${donorAuthToken}`)
        .send(donationWithStatus);
      
      expect(res.statusCode).toEqual(201);
      expect(res.body.status).toBe('available');
    });

    it('should include donor info in response', async () => {
      const res = await request(app)
        .post('/api/donations')
        .set('Authorization', `Bearer ${donorAuthToken}`)
        .send(testDonation);
      
      expect(res.statusCode).toEqual(201);
      expect(res.body.donor).toBeDefined();
      expect(res.body.donor).toHaveProperty('id');
      expect(res.body.donor).toHaveProperty('username', 'donoruser');
      expect(res.body.donor).toHaveProperty('first_name', 'Donor');
      expect(res.body.donor).toHaveProperty('last_name', 'User');
      // Should not include sensitive fields
      expect(res.body.donor).not.toHaveProperty('password');
      expect(res.body.donor).not.toHaveProperty('password_hash');
    });

    it('should prevent non-donors from creating donations', async () => {
      const res = await request(app)
        .post('/api/donations')
        .set('Authorization', `Bearer ${nonDonorAuthToken}`)
        .send(testDonation);
      
      expect(res.statusCode).toEqual(403);
      expect(res.body).toHaveProperty('message', 'Only donors can create donations');
    });
  });
});
