const PDFDocument = require('pdfkit');
const Donation = require('../models/Donation');
const User = require('../models/User');

/**
 * Service to generate professional tax receipts for donations
 */
class ReceiptService {
  /**
   * Generates a PDF tax receipt for a specific donation
   * @param {Object} db - MongoDB database instance
   * @param {string} donationId - ID of the donation
   * @returns {Promise<Buffer>} - PDF document buffer
   */
  static async generateDonationReceipt(db, donationId) {
    // 1. Fetch donation with full details
    const donation = await db.collection('donations').aggregate([
      { $match: { _id: require('mongodb').ObjectId(donationId) } },
      {
        $lookup: {
          from: 'users',
          localField: 'donorId',
          foreignField: '_id',
          as: 'donor'
        }
      },
      { $unwind: '$donor' },
      {
        $lookup: {
          from: 'users',
          localField: 'claimedBy',
          foreignField: '_id',
          as: 'ngo'
        }
      },
      { $unwind: { path: '$ngo', preserveNullAndEmptyArrays: true } }
    ]).next();

    if (!donation) throw new Error('Donation not found');
    if (donation.status !== 'delivered' && donation.status !== 'distributed') {
      throw new Error('Receipts can only be generated for delivered or distributed donations');
    }

    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({
        margin: 50,
        size: 'A4',
        info: {
          Title: `Tax Receipt - ${donation.title}`,
          Author: 'Daansetu Platform',
        }
      });

      const chunks = [];
      doc.on('data', (chunk) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', (err) => reject(err));

      // --- HEADER ---
      this._generateHeader(doc);
      
      // --- CONTENT ---
      this._generateDonorInfo(doc, donation.donor);
      this._generateNgoInfo(doc, donation.ngo);
      this._generateDonationTable(doc, donation);
      
      // --- FOOTER ---
      this._generateFooter(doc);

      doc.end();
    });
  }

  static _generateHeader(doc) {
    doc
      .fillColor('#444444')
      .fontSize(20)
      .text('DAANSETU', 110, 57)
      .fontSize(10)
      .text('Donation Accountability & Trust Platform', 110, 80)
      .fontSize(16)
      .fillColor('#E53E3E') // App Theme Primary Red
      .text('DONATION RECEIPT (Section 80G)', 200, 50, { align: 'right' })
      .moveDown();
      
    doc.strokeColor('#aaaaaa').lineWidth(1).moveTo(50, 100).lineTo(550, 100).stroke();
  }

  static _generateDonorInfo(doc, donor) {
    doc
      .fillColor('#444444')
      .fontSize(12)
      .font('Helvetica-Bold')
      .text('DONOR DETAILS', 50, 120)
      .font('Helvetica')
      .fontSize(10)
      .text(`Name: ${donor.name}`, 50, 140)
      .text(`Email: ${donor.email}`, 50, 155)
      .text(`Phone: ${donor.phone || 'N/A'}`, 50, 170)
      .moveDown();
  }

  static _generateNgoInfo(doc, ngo) {
    if (!ngo) return;

    doc
      .fillColor('#444444')
      .fontSize(12)
      .font('Helvetica-Bold')
      .text('RECIPIENT NGO DETAILS', 300, 120)
      .font('Helvetica')
      .fontSize(10)
      .text(`Organization: ${ngo.name}`, 300, 140)
      .text(`Registration No: ${ngo.ngoDetails?.registrationNumber || 'N/A'}`, 300, 155)
      .text(`Address: ${ngo.location?.address || 'N/A'}`, 300, 170)
      .moveDown();
  }

  static _generateDonationTable(doc, donation) {
    let i;
    const tableTop = 220;

    doc.font('Helvetica-Bold');
    this._generateTableRow(doc, tableTop, 'Item Description', 'Category', 'Quantity', 'Status');
    this._generateHr(doc, tableTop + 20);
    doc.font('Helvetica');

    this._generateTableRow(
      doc,
      tableTop + 30,
      donation.title,
      donation.category,
      `${donation.quantity} ${donation.unit || ''}`,
      donation.status.toUpperCase()
    );

    this._generateHr(doc, tableTop + 50);
  }

  static _generateFooter(doc) {
    const footerY = 700;

    // --- WATERMARK (Simulated) ---
    doc.save()
       .opacity(0.03)
       .fillColor('#000000')
       .fontSize(100)
       .rotate(-45, { origin: [300, 400] })
       .text('DAANSETU', 100, 400)
       .restore();

    doc
      .fontSize(10)
      .fillColor('#777777')
      .text(
        'This is a digitally generated receipt. No physical signature is required under IT Act 2000.',
        50,
        footerY,
        { align: 'center', width: 500 }
      )
      .moveDown()
      .fontSize(8)
      .text(
        'Daansetu facilitates transparency but is not liable for individual NGO tax compliance. Please verify with your tax consultant.',
        50,
        footerY + 20,
        { align: 'center', width: 500 }
      );
      
    // --- VERIFIED STAMP & SIGNATURE ---
    const stampX = 420;
    const stampY = 600;

    doc
      .strokeColor('#38A169') // Success Green
      .lineWidth(2)
      .rect(stampX, stampY, 110, 45)
      .stroke();

    doc
      .fillColor('#38A169')
      .fontSize(10)
      .font('Helvetica-Bold')
      .text('VERIFIED BY', stampX + 5, stampY + 10, { width: 100, align: 'center' })
      .fontSize(12)
      .text('DAANSETU', stampX + 5, stampY + 25, { width: 100, align: 'center' });

    // Signature Line
    doc.strokeColor('#cccccc').lineWidth(1).moveTo(50, 640).lineTo(200, 640).stroke();
    doc.fillColor('#777777').fontSize(8).text('NGO Authorized Signatory', 50, 645);
  }

  static _generateTableRow(doc, y, item, category, qty, status) {
    doc
      .fontSize(10)
      .text(item, 50, y)
      .text(category, 200, y)
      .text(qty, 350, y, { width: 90, align: 'right' })
      .text(status, 450, y, { width: 100, align: 'right' });
  }

  static _generateHr(doc, y) {
    doc
      .strokeColor('#eeeeee')
      .lineWidth(1)
      .moveTo(50, y)
      .lineTo(550, y)
      .stroke();
  }
}

module.exports = ReceiptService;
