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
const adminRoutes = require('./routes/admin');
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
app.use('/api/admin', adminRoutes);

// Upload route
app.post('/api/upload/image', auth, upload.single('image'), uploadImage);

// Organization document upload route (requires authentication)
app.post('/api/upload/organization-document', auth, upload.single('document'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No document file provided' });
    }

    // Get project root directory
    const projectRoot = path.join(__dirname, '..');
    
    // Return relative path from project root
    const relativePath = path.relative(projectRoot, req.file.path);
    
    res.status(201).json({
      message: 'Document uploaded successfully',
      documentUrl: relativePath,
      filename: req.file.filename,
    });
  } catch (error) {
    console.error('Error uploading document:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
});

// Organization document upload route for registration (no authentication required)
app.post('/api/upload/registration-document', upload.single('document'), (req, res) => {
  try {
    console.log('Registration document upload request received');
    console.log('File:', req.file);
    
    if (!req.file) {
      console.log('No file provided in request');
      return res.status(400).json({ 
        success: false,
        message: 'No document file provided' 
      });
    }

    // Get project root directory
    const projectRoot = path.join(__dirname, '..');
    
    // Return relative path from project root
    const relativePath = path.relative(projectRoot, req.file.path);
    
    console.log('File uploaded successfully:', relativePath);
    
    res.status(201).json({
      success: true,
      message: 'Document uploaded successfully',
      documentUrl: relativePath,
      filename: req.file.filename,
    });
  } catch (error) {
    console.error('Error uploading document:', error);
    res.status(500).json({ 
      success: false,
      message: 'Internal server error', 
      error: error.message 
    });
  }
});

// Health check endpoint for mobile app connection testing
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    message: 'Food Donation Backend is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

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
  app.listen(PORT, '0.0.0.0', () => {
    const os = require('os');
    
    // Get all network interfaces
    const interfaces = os.networkInterfaces();
    const ips = [];
    
    // Collect all IPv4 addresses (excluding localhost)
    Object.keys(interfaces).forEach(interfaceName => {
      interfaces[interfaceName].forEach(iface => {
        if (iface.family === 'IPv4' && !iface.internal) {
          ips.push(iface.address);
        }
      });
    });
    
    console.log('\n🚀 Food Donation Backend Server Started!');
    console.log('=====================================');
    console.log(`📡 Local URL: http://localhost:${PORT}`);
    console.log(`🌐 API Endpoint: http://localhost:${PORT}/api`);
    
    if (ips.length > 0) {
      console.log('\n📱 For Mobile App Connection:');
      ips.forEach((ip, index) => {
        console.log(`   ${index + 1}. http://${ip}:${PORT}`);
        console.log(`      API: http://${ip}:${PORT}/api`);
      });
      console.log('\n💡 Enter any of the above URLs in the mobile app connection settings');
      console.log('   (Tap the connection icon in the top-right of login screen)');
    } else {
      console.log('\n⚠️  No network interfaces found. Make sure you\'re connected to a network.');
    }
    
    console.log('\n🔧 Health Check: http://localhost:' + PORT + '/api/health');
    console.log('=====================================\n');
  });
}

module.exports = app;
