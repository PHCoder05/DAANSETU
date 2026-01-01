const express = require('express');
const router = express.Router();
const searchController = require('../../controllers/searchController');
const { optionalAuth } = require('../../middleware/auth');

/**
 * @swagger
 * /api/search/donations:
 *   get:
 *     summary: Advanced search for donations
 *     tags: [Search]
 *     parameters:
 *       - in: query
 *         name: q
 *         schema:
 *           type: string
 *         description: Search query (title, description, tags)
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *           enum: [food, clothes, books, medical, electronics, furniture, other]
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [available, claimed, in-transit, delivered]
 *       - in: query
 *         name: priority
 *         schema:
 *           type: string
 *           enum: [low, normal, high, urgent]
 *       - in: query
 *         name: minQuantity
 *         schema:
 *           type: number
 *       - in: query
 *         name: maxQuantity
 *         schema:
 *           type: number
 *       - in: query
 *         name: location
 *         schema:
 *           type: string
 *         description: "Lat,Lng (e.g., 40.7128,-74.0060)"
 *       - in: query
 *         name: radius
 *         schema:
 *           type: number
 *         description: Search radius in km (default 50)
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Search results
 */
router.get('/donations', optionalAuth, searchController.searchDonations);

/**
 * @swagger
 * /api/search/ngos:
 *   get:
 *     summary: Search for NGOs
 *     tags: [Search]
 *     parameters:
 *       - in: query
 *         name: q
 *         schema:
 *           type: string
 *         description: Search query (name, description)
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: NGO search results
 */
router.get('/ngos', optionalAuth, searchController.searchNGOs);

/**
 * @swagger
 * /api/search/categories:
 *   get:
 *     summary: Get all donation categories with counts
 *     tags: [Search]
 *     responses:
 *       200:
 *         description: List of categories with donation counts
 */
router.get('/categories', searchController.getCategories);

module.exports = router;

