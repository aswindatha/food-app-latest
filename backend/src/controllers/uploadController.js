const path = require('path');
const upload = require('../middleware/upload');

// Get project root directory
const projectRoot = path.join(__dirname, '..', '..');

// Upload image and return URL
const uploadImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No image file provided' });
    }

    // Return relative path from project root
    const relativePath = path.relative(projectRoot, req.file.path);
    
    res.status(201).json({
      message: 'Image uploaded successfully',
      imageUrl: relativePath,
      filename: req.file.filename,
    });
  } catch (error) {
    console.error('Error uploading image:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};

module.exports = {
  uploadImage,
};
