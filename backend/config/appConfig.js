/**
 * App Configuration
 * Central place for all app-wide configuration values
 * Follows DRY principle - define once, use everywhere
 */

// Read from package.json for version
const packageJson = require('../package.json');

const config = {
    // App Info
    app: {
        name: process.env.APP_NAME || 'DAANSETU',
        version: packageJson.version || '1.0.0',
        description: packageJson.description || 'Donation Management Platform',
        environment: process.env.NODE_ENV || 'development'
    },

    // Server
    server: {
        host: process.env.HOST || '0.0.0.0',
        port: parseInt(process.env.PORT, 10) || 5000,
        corsOrigin: process.env.CORS_ORIGIN || '*',
        // Get the public URL (for logs, swagger)
        get publicUrl() {
            return process.env.API_URL?.replace('/api', '') ||
                `http://${process.env.HOST || 'localhost'}:${this.port}`;
        }
    },

    // Database
    database: {
        uri: process.env.MONGODB_URI,
        name: process.env.DB_NAME || 'daansetu'
    },

    // JWT
    jwt: {
        secret: process.env.JWT_SECRET,
        refreshSecret: process.env.JWT_REFRESH_SECRET,
        expiresIn: process.env.JWT_EXPIRES_IN || '15m',
        refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d'
    },

    // API
    api: {
        version: 'v1',
        get baseUrl() {
            return process.env.API_URL || `${config.server.publicUrl}/api`;
        },
        get fullUrl() {
            return `${this.baseUrl}/${this.version}`;
        }
    },

    // URLs (configurable via env)
    urls: {
        frontend: process.env.FRONTEND_URL || 'https://daansetu.vercel.app',
        get passwordReset() {
            return process.env.PASSWORD_RESET_URL || `${this.frontend}/reset-password`;
        },
        get emailVerification() {
            return `${this.frontend}/verify-email`;
        }
    },

    // Email
    email: {
        from: process.env.EMAIL_FROM || `"${process.env.APP_NAME || 'DAANSETU'} Support" <support@daansetu.com>`,
        smtp: {
            host: process.env.SMTP_HOST,
            port: parseInt(process.env.SMTP_PORT, 10) || 587,
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS
        }
    },

    // Upload
    upload: {
        maxSize: process.env.MAX_FILE_SIZE || '10mb',
        path: process.env.UPLOAD_PATH || './public/uploads'
    },

    // Logging
    logging: {
        level: process.env.LOG_LEVEL || 'debug'
    },

    // Admin
    admin: {
        setupKey: process.env.ADMIN_SETUP_KEY || 'change-this-setup-key-in-production',
        defaultEmail: process.env.ADMIN_EMAIL || 'admin@daansetu.org'
    }
};

// Freeze to prevent accidental modifications
Object.freeze(config);
Object.freeze(config.app);
Object.freeze(config.server);
Object.freeze(config.database);
Object.freeze(config.jwt);
Object.freeze(config.api);
Object.freeze(config.urls);
Object.freeze(config.email);
Object.freeze(config.upload);
Object.freeze(config.logging);
Object.freeze(config.admin);

module.exports = config;
