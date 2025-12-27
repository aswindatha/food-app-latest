const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure assets directory exists
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
    cb(null, assetsDir);
  },
  filename: (req, file, cb) => {
    // Generate unique filename with original extension
    const ext = path.extname(file.originalname);
    const uniqueName = uuidv4 ? `${uuidv4()}${ext}` : `${Date.now()}${ext}`;
    cb(null, uniqueName);
  },
});

const fileFilter = (req, file, cb) => {
  // Accept only image files
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
});

module.exports = upload;
