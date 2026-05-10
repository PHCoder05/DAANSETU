const { getDB } = require('../config/db');
const { ObjectId } = require('mongodb');
const Donation = require('../models/Donation');
const { successResponse, errorResponse } = require('../utils/helpers');

/**
 * Get NGO's current inventory (delivered but not fully distributed)
 */
const getInventory = async (req, res) => {
  try {
    const db = getDB();
    
    // Inventory items are donations claimed by this NGO that are 'delivered' or 'distributed' (partially)
    const filter = {
      claimedBy: new ObjectId(req.user.userId),
      status: { $in: ['delivered', 'distributed'] },
      active: true
    };

    const items = await db.collection('donations').find(filter).sort({ deliveryDate: -1 }).toArray();

    // Map to the format expected by the web/mobile app
    const inventory = items.map(item => ({
      id: item._id,
      donationId: item._id,
      title: item.title,
      category: item.category,
      quantity: item.quantity,
      condition: item.condition,
      receivedAt: item.deliveryDate || item.updatedAt,
      status: item.status === 'delivered' ? 'in_stock' : 'distributed',
      distributionHistory: item.distributionHistory || []
    }));

    return successResponse(res, 200, 'Inventory retrieved', { data: inventory, total: inventory.length });
  } catch (error) {
    return errorResponse(res, 500, 'Error fetching inventory', error.message);
  }
};

/**
 * Distribute an item to beneficiaries
 */
const distributeItem = async (req, res) => {
  try {
    const { id } = req.params;
    const { beneficiaryName, location, quantity, proofImage } = req.body;
    
    const db = getDB();
    const donation = await Donation.findById(db, id);

    if (!donation) return errorResponse(res, 404, 'Inventory item not found');
    if (donation.claimedBy.toString() !== req.user.userId) {
      return errorResponse(res, 403, 'Permission denied');
    }

    if (quantity > donation.quantity) {
      return errorResponse(res, 400, 'Insufficient stock');
    }

    if (!proofImage) {
      return errorResponse(res, 400, 'Photo evidence of handover is required');
    }

    const distributionEntry = {
      id: new ObjectId().toString(),
      beneficiaryName,
      location,
      quantity,
      proofImage,
      distributedAt: new Date()
    };

    const newQuantity = donation.quantity - quantity;
    const newStatus = newQuantity === 0 ? 'distributed' : 'distributed'; // Stay in distributed if partially done

    await db.collection('donations').updateOne(
      { _id: new ObjectId(id) },
      { 
        $set: { 
          quantity: newQuantity,
          status: newStatus,
          updatedAt: new Date()
        },
        $push: { distributionHistory: distributionEntry }
      }
    );

    return successResponse(res, 200, 'Item distributed successfully');
  } catch (error) {
    return errorResponse(res, 500, 'Error processing distribution', error.message);
  }
};

/**
 * Update inventory status
 */
const updateItemStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    const db = getDB();
    await db.collection('donations').updateOne(
      { _id: new ObjectId(id) },
      { $set: { status: status === "disposed" ? "cancelled" : (status === "distributed" ? "distributed" : status), active: status !== "disposed", updatedAt: new Date() } }
    );

    const updated = await db.collection('donations').findOne({ _id: new ObjectId(id) });
    return successResponse(res, 200, 'Status updated', updated);
  } catch (error) {
    return errorResponse(res, 500, 'Error updating status', error.message);
  }
};

module.exports = {
  getInventory,
  distributeItem,
  updateItemStatus
};
