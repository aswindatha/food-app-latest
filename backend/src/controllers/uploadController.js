const path = require('path');
const upload = require('../middleware/upload');

// Upload image and return URL
const uploadImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No image file provided' });
    }

    // Return relative URL that can be served statically
    const imageUrl = `/assets/${req.file.filename}`;
    
    res.status(201).json({
      message: 'Image uploaded successfully',
      imageUrl,
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
