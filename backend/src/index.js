require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const multer = require('multer');
const { auth } = require('./middleware/auth');
const authRoutes = require('./routes/auth');
const donationRoutes = require('./routes/donations');
const conversationRoutes = require('./routes/conversations');
const organizationRoutes = require('./routes/organization');
const volunteerRoutes = require('./routes/volunteer');
const { uploadImage } = require('./controllers/uploadController');
const upload = require('./middleware/upload');

// Import models to set up associations
require('./models');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Serve static files from assets directory
app.use('/assets', express.static(path.join(__dirname, 'assets')));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/donations', donationRoutes);
app.use('/api/conversations', conversationRoutes);
app.use('/api/organization', organizationRoutes);
app.use('/api/volunteer', volunteerRoutes);

// Upload route
app.post('/api/upload/image', auth, upload.single('image'), uploadImage);

// Protected route example
app.get('/api/me', auth, (req, res) => {
  res.json(req.user);
});

// Multer error handling
app.use((err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({ message: 'File too large (max 5MB)' });
    }
    if (err.code === 'LIMIT_FILE_COUNT') {
      return res.status(400).json({ message: 'Too many files' });
    }
    return res.status(400).json({ message: err.message });
  }
  if (err.message === 'Only image files are allowed') {
    return res.status(400).json({ message: err.message });
  }
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
