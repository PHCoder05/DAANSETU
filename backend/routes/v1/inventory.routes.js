const express = require('express');
const router = express.Router();
const inventoryController = require('../../controllers/inventoryController');
const { authenticate } = require('../../middleware/auth');
const { mongoIdValidation, validate } = require('../../utils/validators');
const { body } = require('express-validator');

/**
 * @swagger
 * /api/v1/ngo/inventory:
 *   get:
 *     summary: Get NGO's current inventory
 *     tags: [Inventory]
 *     security:
 *       - bearerAuth: []
 */
router.get('/', authenticate, inventoryController.getInventory);

/**
 * @swagger
 * /api/v1/ngo/inventory/{id}/distribute:
 *   post:
 *     summary: Distribute item to beneficiaries
 *     tags: [Inventory]
 *     security:
 *       - bearerAuth: []
 */
router.post(
  '/:id/distribute',
  authenticate,
  mongoIdValidation('id'),
  [
    body('beneficiaryName').notEmpty().withMessage('Beneficiary name is required'),
    body('location').notEmpty().withMessage('Location is required'),
    body('quantity').isInt({ min: 1 }).withMessage('Quantity must be at least 1'),
    validate
  ],
  inventoryController.distributeItem
);

/**
 * @swagger
 * /api/v1/ngo/inventory/{id}/status:
 *   put:
 *     summary: Update item status
 *     tags: [Inventory]
 *     security:
 *       - bearerAuth: []
 */
router.put(
  '/:id/status',
  authenticate,
  mongoIdValidation('id'),
  [
    body('status').notEmpty().withMessage('Status is required'),
    validate
  ],
  inventoryController.updateItemStatus
);

module.exports = router;
