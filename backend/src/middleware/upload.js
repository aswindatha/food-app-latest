const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Get project root directory (go up from src/middleware to project root)
const projectRoot = path.join(__dirname, '..', '..');

// Ensure assets directory exists in backend/src/assets
const assetsDir = path.join(__dirname, '..', 'assets');
if (!fs.existsSync(assetsDir)) {
  fs.mkdirSync(assetsDir, { recursive: true });
}

// Dynamic import for uuid (ES Module)
let uuidv4;
const initUuid = async () => {
  const { v4 } = await import('uuid');
  uuidv4 = v4;
};
initUuid();

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // For organization documents, create folder with username
    let uploadPath = assetsDir;
    
    if (req.body && req.body.username && req.body.isOrganizationDocument) {
      const userFolder = path.join(assetsDir, req.body.username);
      if (!fs.existsSync(userFolder)) {
        fs.mkdirSync(userFolder, { recursive: true });
      }
      uploadPath = userFolder;
    }
    
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    // Generate unique filename with original extension
    const ext = path.extname(file.originalname);
    const uniqueName = uuidv4 ? `${uuidv4()}${ext}` : `${Date.now()}${ext}`;
    cb(null, uniqueName);
  },
});

const fileFilter = (req, file, cb) => {
  console.log('File mimetype:', file.mimetype);
  console.log('File originalname:', file.originalname);
  console.log('Request URL:', req.originalUrl);
  console.log('Request body:', req.body);
  
  // Accept image files and any document files for organizations
  if (req.body && req.body.isOrganizationDocument) {
    // Accept any file type for organization documents
    console.log('Accepting organization document');
    cb(null, true);
  } else if (req.originalUrl && req.originalUrl.includes('/registration-document')) {
    // Accept any file type for registration documents
    console.log('Accepting registration document');
    cb(null, true);
  } else if (file.mimetype.startsWith('image/')) {
    // Accept image files
    console.log('Accepting image file');
    cb(null, true);
  } else {
    console.log('Rejected file - not an image or organization document');
    cb(new Error('Only image files and organization documents are allowed'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit for documents
  },
});

module.exports = upload;
