const multer = require('multer');
const path = require('path');
const fs = require('fs');

/**
 * Flexible Multer Upload Middleware
 * Supports different directories and file types
 */

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        // Determine subfolder based on fieldname or query
        const type = req.query.type || 'general';
        const uploadDir = path.join(__dirname, `../public/uploads/${type}`);
        
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const fileFilter = (req, file, cb) => {
    // Allowed extensions
    const allowedImages = /\.(jpg|jpeg|png|gif)$/;
    const allowedDocs = /\.(pdf|doc|docx|txt)$/;
    
    if (file.originalname.match(allowedImages) || file.originalname.match(allowedDocs)) {
        cb(null, true);
    } else {
        cb(new Error('File type not supported!'), false);
    }
};

const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 10 * 1024 * 1024 // 10MB max
    }
});

module.exports = upload;
