require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { auth } = require('./middleware/auth');
const authRoutes = require('./routes/auth');
const donationRoutes = require('./routes/donations');
const conversationRoutes = require('./routes/conversations');
const organizationRoutes = require('./routes/organization');
const volunteerRoutes = require('./routes/volunteer');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/donations', donationRoutes);
app.use('/api/conversations', conversationRoutes);
app.use('/api/organization', organizationRoutes);
app.use('/api/volunteer', volunteerRoutes);

// Protected route example
app.get('/api/me', auth, (req, res) => {
  res.json(req.user);
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Start server only if not in test mode
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

module.exports = app;
