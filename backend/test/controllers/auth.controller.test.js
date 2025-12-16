const request = require('supertest');
const app = require('../../src');
const User = require('../../src/models/User');
const { createTestUser, createTestUserWithPassword, clearDatabase } = require('../setup');

// Set JWT secret for testing
process.env.JWT_SECRET = 'test-secret-key';

describe('Auth Controller', () => {
  describe('POST /api/auth/register', () => {
    const testUser = {
      username: 'testuser',
      email: 'test@example.com',
      password: 'password123',
      first_name: 'Test',
      last_name: 'User',
      role: 'donor'
    };

    beforeEach(async () => {
      // Clear database before each test
      await clearDatabase();
    });

    it('should register a new user with valid data', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send(testUser);

      expect(res.statusCode).toEqual(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body).toHaveProperty('username', testUser.username);
      expect(res.body).toHaveProperty('email', testUser.email);
      expect(res.body).toHaveProperty('first_name', testUser.first_name);
      expect(res.body).toHaveProperty('last_name', testUser.last_name);
      expect(res.body).toHaveProperty('role', testUser.role);
      expect(res.body).toHaveProperty('token');
      expect(res.body).not.toHaveProperty('password');
      expect(res.body).not.toHaveProperty('password_hash');

      // Verify user exists in database
      const dbUser = await User.findByPk(res.body.id);
      expect(dbUser).not.toBeNull();
      expect(dbUser.username).toBe(testUser.username);
    });

    it('should return 400 if username already exists', async () => {
      // Create a user first
      await createTestUserWithPassword(testUser);

      // Try to create another user with same username
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          ...testUser,
          email: 'another@example.com' // Different email, same username
        });

      expect(res.statusCode).toEqual(400);
      expect(res.body).toHaveProperty('error', 'User with this email or username already exists');
    });

    it('should return 400 if email already exists', async () => {
      // Create a user first
      await createTestUserWithPassword(testUser);

      // Try to create another user with same email
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          ...testUser,
          username: 'differentuser' // Different username, same email
        });

      expect(res.statusCode).toEqual(400);
      expect(res.body).toHaveProperty('error', 'User with this email or username already exists');
    });

    it('should not return password hash in response', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send(testUser);

      expect(res.statusCode).toEqual(201);
      expect(res.body).not.toHaveProperty('password');
      expect(res.body).not.toHaveProperty('password_hash');
    });

    it('should generate a valid JWT token', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send(testUser);

      expect(res.statusCode).toEqual(201);
      expect(res.body).toHaveProperty('token');
      
      // Verify token is valid
      const jwt = require('jsonwebtoken');
      const decoded = jwt.verify(res.body.token, process.env.JWT_SECRET);
      expect(decoded).toHaveProperty('id', res.body.id);
      expect(decoded).toHaveProperty('role', testUser.role);
    });

    it('should require all required fields', async () => {
      const requiredFields = ['username', 'email', 'password', 'first_name', 'last_name', 'role'];
      
      for (const field of requiredFields) {
        const userData = { ...testUser };
        delete userData[field];
        
        const res = await request(app)
          .post('/api/auth/register')
          .send(userData);
          
        expect(res.statusCode).toEqual(400);
      }
    });
  });

  describe('POST /api/auth/login', () => {
    const testUser = {
      username: 'testuser',
      email: 'test@example.com',
      password: 'password123',
      first_name: 'Test',
      last_name: 'User',
      role: 'donor'
    };

    beforeEach(async () => {
      // Clear database before each test
      await clearDatabase();
      // Create a test user for login tests
      await createTestUserWithPassword(testUser);
    });

    it('should login with valid email', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          emailOrUsername: testUser.email,
          password: testUser.password
        });

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('id');
      expect(res.body).toHaveProperty('username', testUser.username);
      expect(res.body).toHaveProperty('email', testUser.email);
      expect(res.body).toHaveProperty('first_name', testUser.first_name);
      expect(res.body).toHaveProperty('last_name', testUser.last_name);
      expect(res.body).toHaveProperty('role', testUser.role);
      expect(res.body).toHaveProperty('token');
      expect(res.body).not.toHaveProperty('password');
      expect(res.body).not.toHaveProperty('password_hash');
    });

    it('should login with valid username', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          emailOrUsername: testUser.username,
          password: testUser.password
        });

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('username', testUser.username);
      expect(res.body).toHaveProperty('token');
    });

    it('should return 401 with invalid credentials', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          emailOrUsername: testUser.email,
          password: 'wrongpassword'
        });

      expect(res.statusCode).toEqual(401);
      expect(res.body).toHaveProperty('error', 'Invalid credentials');
    });

    it('should return 401 with non-existent user', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          emailOrUsername: 'nonexistent@example.com',
          password: 'password123'
        });

      expect(res.statusCode).toEqual(401);
      expect(res.body).toHaveProperty('error', 'Invalid credentials');
    });

    it('should return a valid JWT token on successful login', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          emailOrUsername: testUser.email,
          password: testUser.password
        });

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('token');
      
      // Verify token is valid
      const jwt = require('jsonwebtoken');
      const decoded = jwt.verify(res.body.token, process.env.JWT_SECRET);
      expect(decoded).toHaveProperty('id', res.body.id);
      expect(decoded).toHaveProperty('role', testUser.role);
    });

    it('should not return password hash in response', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          emailOrUsername: testUser.email,
          password: testUser.password
        });

      expect(res.statusCode).toEqual(200);
      expect(res.body).not.toHaveProperty('password');
      expect(res.body).not.toHaveProperty('password_hash');
    });

    it('should return 400 if emailOrUsername is missing', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          password: testUser.password
        });

      expect(res.statusCode).toEqual(400);
      expect(res.body).toHaveProperty('error', 'Please provide email/username and password');
    });

    it('should return 400 if password is missing', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          emailOrUsername: testUser.email
        });

      expect(res.statusCode).toEqual(400);
      expect(res.body).toHaveProperty('error', 'Please provide email/username and password');
    });
  });

  describe('GET /api/auth/me', () => {
    const testUser = {
      username: 'currentuser',
      email: 'current@example.com',
      password: 'currentpass123',
      first_name: 'Current',
      last_name: 'User',
      role: 'donor'
    };

    let authToken;

    beforeEach(async () => {
      await clearDatabase();
      
      // Register a new user
      const registerResponse = await request(app)
        .post('/api/auth/register')
        .send(testUser);

      if (registerResponse.statusCode !== 201) {
        console.error('Failed to register test user:', registerResponse.body);
        throw new Error('Failed to create test user');
      }

      // Login to get the auth token
      const loginRes = await request(app)
        .post('/api/auth/login')
        .send({
          emailOrUsername: testUser.email,
          password: testUser.password
        });

      if (loginRes.statusCode !== 200) {
        console.error('Failed to login test user:', loginRes.body);
        throw new Error('Failed to login test user');
      }

      authToken = loginRes.body.token;
      console.log('Test user registered and logged in successfully');
    });

    it('should return current user data when authenticated', async () => {
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${authToken}`);
      
      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('id');
      expect(res.body).toHaveProperty('username', testUser.username);
      expect(res.body).toHaveProperty('email', testUser.email);
      expect(res.body).toHaveProperty('first_name', testUser.first_name);
      expect(res.body).toHaveProperty('last_name', testUser.last_name);
      expect(res.body).toHaveProperty('role', testUser.role);
    });

    it('should not return password hash in response', async () => {
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${authToken}`);
      
      expect(res.statusCode).toEqual(200);
      expect(res.body).not.toHaveProperty('password');
      expect(res.body).not.toHaveProperty('password_hash');
    });

    it('should return 401 if not authenticated', async () => {
      const res = await request(app)
        .get('/api/auth/me');
        // No Authorization header

      expect(res.statusCode).toEqual(401);
      expect(res.body).toHaveProperty('error');
    });
  });
});
