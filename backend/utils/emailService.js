/**
 * Email Service
 * Uses real SMTP when configured, falls back to Ethereal for development
 */
const nodemailer = require('nodemailer');
const config = require('../config/appConfig');
const logger = require('./logger');

let transporter = null;

/**
 * Get or create the email transporter
 * Uses real SMTP if configured, otherwise falls back to Ethereal (dev only)
 */
const getTransporter = async () => {
    if (transporter) {
        return transporter;
    }

    // Check if real SMTP is configured
    const smtpHost = config.email.smtp.host;
    const smtpUser = config.email.smtp.user;
    const smtpPass = config.email.smtp.pass;

    if (smtpHost && smtpUser && smtpPass) {
        // Use real SMTP
        transporter = nodemailer.createTransport({
            host: smtpHost,
            port: config.email.smtp.port || 587,
            secure: config.email.smtp.port === 465, // true for 465, false for other ports
            auth: {
                user: smtpUser,
                pass: smtpPass
            }
        });

        logger.info('� Email service using SMTP: ' + smtpHost);
    } else {
        // Fallback to Ethereal for development
        logger.warn('⚠️ SMTP not configured, using Ethereal (test emails only)');

        const testAccount = await nodemailer.createTestAccount();
        transporter = nodemailer.createTransport({
            host: 'smtp.ethereal.email',
            port: 587,
            secure: false,
            auth: {
                user: testAccount.user,
                pass: testAccount.pass
            }
        });

        logger.info('📧 Ethereal test account: ' + testAccount.user);
    }

    return transporter;
};

/**
 * Send an email
 * @param {string} to - Recipient email
 * @param {string} subject - Email subject
 * @param {string} html - Email body (HTML)
 * @returns {Promise<object>} - Send result with messageId and previewUrl (if Ethereal)
 */
const sendEmail = async (to, subject, html) => {
    try {
        const transport = await getTransporter();

        const mailOptions = {
            from: config.email.from,
            to,
            subject,
            html
        };

        const info = await transport.sendMail(mailOptions);

        logger.info(`✅ Email sent to ${to}: ${info.messageId}`);

        // Return preview URL if using Ethereal (test mode)
        const previewUrl = nodemailer.getTestMessageUrl(info);
        if (previewUrl) {
            logger.info(`🔗 Preview: ${previewUrl}`);
        }

        return {
            success: true,
            messageId: info.messageId,
            previewUrl: previewUrl || null
        };
    } catch (error) {
        logger.error('❌ Email send failed:', error.message);
        throw error;
    }
};

/**
 * Verify SMTP connection
 */
const verifyConnection = async () => {
    try {
        const transport = await getTransporter();
        await transport.verify();
        logger.info('✅ Email service connection verified');
        return true;
    } catch (error) {
        logger.error('❌ Email service connection failed:', error.message);
        return false;
    }
};

module.exports = {
    sendEmail,
    verifyConnection,
    getTransporter
};
