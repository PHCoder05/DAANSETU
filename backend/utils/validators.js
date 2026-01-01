const { body, param, query, validationResult } = require('express-validator');

// Validation error handler
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation error',
      errors: errors.array()
    });
  }
  next();
};

// User validation rules
const registerValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email address'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long'),
  body('name')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters'),
  body('role')
    .isIn(['donor', 'ngo'])
    .withMessage('Role must be either donor or ngo'),
  body('phone')
    .optional()
    .isMobilePhone()
    .withMessage('Please provide a valid phone number'),
  validate
];

const loginValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email address'),
  body('password')
    .notEmpty()
    .withMessage('Password is required'),
  validate
];

// Donation validation rules
const createDonationValidation = [
  body('title')
    .trim()
    .isLength({ min: 5, max: 200 })
    .withMessage('Title must be between 5 and 200 characters'),
  body('description')
    .trim()
    .isLength({ min: 10, max: 2000 })
    .withMessage('Description must be between 10 and 2000 characters'),
  body('category')
    .isIn(['food', 'clothes', 'books', 'medical', 'electronics', 'furniture', 'other'])
    .withMessage('Invalid category'),
  body('quantity')
    .optional()
    .isNumeric()
    .withMessage('Quantity must be a number'),
  body('pickupLocation')
    .notEmpty()
    .withMessage('Pickup location is required'),
  body('pickupLocation.lat')
    .isFloat({ min: -90, max: 90 })
    .withMessage('Invalid latitude'),
  body('pickupLocation.lng')
    .isFloat({ min: -180, max: 180 })
    .withMessage('Invalid longitude'),
  body('pickupLocation.address')
    .trim()
    .notEmpty()
    .withMessage('Address is required'),
  validate
];

const updateDonationValidation = [
  body('title')
    .optional()
    .trim()
    .isLength({ min: 5, max: 200 })
    .withMessage('Title must be between 5 and 200 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ min: 10, max: 2000 })
    .withMessage('Description must be between 10 and 2000 characters'),
  body('category')
    .optional()
    .isIn(['food', 'clothes', 'books', 'medical', 'electronics', 'furniture', 'other'])
    .withMessage('Invalid category'),
  validate
];

// Request validation rules
const createRequestValidation = [
  body('donationId')
    .isMongoId()
    .withMessage('Invalid donation ID'),
  body('message')
    .optional()
    .trim()
    .isLength({ max: 1000 })
    .withMessage('Message must not exceed 1000 characters'),
  body('beneficiariesCount')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Beneficiaries count must be a positive number'),
  validate
];

// NGO validation rules
const updateNGODetailsValidation = [
  body('ngoDetails.registrationNumber')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Registration number cannot be empty'),
  body('ngoDetails.description')
    .optional()
    .trim()
    .isLength({ min: 50, max: 2000 })
    .withMessage('Description must be between 50 and 2000 characters'),
  body('ngoDetails.website')
    .optional()
    .isURL()
    .withMessage('Please provide a valid website URL'),
  body('ngoDetails.establishedYear')
    .optional()
    .isInt({ min: 1900, max: new Date().getFullYear() })
    .withMessage('Invalid established year'),
  validate
];

// Admin validation rules
const verifyNGOValidation = [
  param('userId')
    .isMongoId()
    .withMessage('Invalid user ID'),
  body('status')
    .isIn(['verified', 'rejected'])
    .withMessage('Status must be either verified or rejected'),
  body('reason')
    .optional()
    .trim(),
  validate
];

// Pagination validation
const paginationValidation = [
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100'),
  validate
];

// MongoDB ID validation
const mongoIdValidation = (paramName = 'id') => [
  param(paramName)
    .isMongoId()
    .withMessage('Invalid ID format'),
  validate
];

module.exports = {
  validate,
  registerValidation,
  loginValidation,
  createDonationValidation,
  updateDonationValidation,
  createRequestValidation,
  updateNGODetailsValidation,
  verifyNGOValidation,
  paginationValidation,
  mongoIdValidation
};

