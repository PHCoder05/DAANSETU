const express = require('express');
const cors = require('cors');
const compression = require('compression');
const swaggerUi = require('swagger-ui-express');
const { connectDB } = require('./config/db');
const swaggerSpec = require('./config/swagger');
const config = require('./config/appConfig');
const logger = require('./utils/logger');
const requestLogger = require('./middleware/requestLogger');
const { requestId } = require('./middleware/requestId');
const { dataIsolation } = require('./middleware/dataIsolation');
const { helmetMiddleware, generalLimiter } = require('./middleware/security');
const { sanitizeInput, trimStrings } = require('./middleware/sanitize');
const { startScheduler, stopScheduler } = require('./utils/scheduler');
const healthRoutes = require('./routes/v1/health.routes');

// ═══════════════════════════════════════════════════════════════════
// IMPORT VERSIONED ROUTES
// ═══════════════════════════════════════════════════════════════════
const v1Routes = require('./routes/v1');

// Create Express app
const app = express();

// ═══════════════════════════════════════════════════════════════════
// SECURITY & PERFORMANCE MIDDLEWARE (First!)
// ═══════════════════════════════════════════════════════════════════
app.use(helmetMiddleware);  // Security headers
app.use(compression());     // GZIP compression for faster responses
app.use(requestId);         // Request ID for tracing/debugging

// ═══════════════════════════════════════════════════════════════════
// GLOBAL MIDDLEWARE
// ═══════════════════════════════════════════════════════════════════
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Input sanitization - prevents MongoDB injection and XSS
app.use(sanitizeInput);   // Block $ operators and dot notation
app.use(trimStrings);     // Trim whitespace from strings

// Request logging middleware with Winston
app.use(requestLogger);

// Rate limiting - apply to all API routes
app.use('/api', generalLimiter);

// Data isolation middleware - attaches ownership helpers to every request
app.use(dataIsolation);

// Serve static files
app.use('/uploads', express.static('public/uploads'));

// Swagger Documentation
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: `${config.app.name} API Documentation`
}));

// ═══════════════════════════════════════════════════════════════════
// HEALTH CHECK ENDPOINTS (deep checks)
// ═══════════════════════════════════════════════════════════════════
app.use('/health', healthRoutes);

// Simple root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: `${config.app.name} API Server`,
    version: config.app.version,
    status: 'running',
    environment: config.app.environment,
    documentation: '/api-docs',
    health: '/health/ready',
    api: {
      current: `/api/${config.api.version}`,
      versions: [config.api.version]
    }
  });
});

// ═══════════════════════════════════════════════════════════════════
// API ROUTES - VERSIONED
// ═══════════════════════════════════════════════════════════════════

// V1 API Routes
app.use('/api/v1', v1Routes);

// Backward compatibility: /api/* redirects to /api/v1/*
// This ensures existing clients continue to work
app.use('/api', v1Routes);


// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// Global error handler
app.use((err, req, res, next) => {
  // Log error with context
  logger.error('❌ Global Error Handler', {
    error: {
      name: err.name,
      message: err.message,
      stack: err.stack
    },
    request: {
      method: req.method,
      url: req.originalUrl,
      ip: req.ip
    }
  });

  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

const http = require('http');
const socketIo = require('socket.io');
const chatSocket = require('./sockets/chatSocket');

// Start server
const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    // Connect to MongoDB
    await connectDB();

    // Create HTTP server
    const server = http.createServer(app);

    // Initialize Socket.io
    const io = socketIo(server, {
      cors: {
        origin: process.env.CORS_ORIGIN || '*',
        methods: ["GET", "POST"],
        credentials: true
      }
    });

    // Setup Chat Sockets
    chatSocket(io);

    // Start Server
    server.listen(PORT, () => {
      const publicUrl = config.server.publicUrl;

      logger.info(`🚀 ${config.app.name} API Server Started`);
      logger.info(`📡 Port: ${PORT}`);
      logger.info(`🌍 Environment: ${config.app.environment}`);
      logger.info(`📄 Swagger Docs: ${publicUrl}/api-docs`);
      logger.info('✨ Ready to accept requests!');

      // Start scheduled jobs (donation expiry, cleanup, etc.)
      startScheduler();

      // Console output for visibility
      console.log(`\n🚀 ${config.app.name} API Server is running!`);
      console.log(`📡 Port: ${PORT}`);
      console.log(`🌍 Environment: ${config.app.environment}`);
      console.log(`\n📚 API Documentation:`);
      console.log(`   Swagger UI: ${publicUrl}/api-docs`);
      console.log(`   Health Check: ${publicUrl}/health`);
      console.log(`\n✨ Ready to accept requests!\n`);
      console.log(`📝 All logs are saved to /logs directory`);
      console.log(`   - combined.log (all logs)`);
      console.log(`   - error.log (errors only)\n`);
    });
  } catch (error) {
    logger.error('❌ Failed to start server', { error: error.message, stack: error.stack });
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error('💥 Uncaught Exception', { error: error.message, stack: error.stack });
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (error) => {
  logger.error('💥 Unhandled Rejection', { error: error.message, stack: error.stack });
  console.error('Unhandled Rejection:', error);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.warn('⚠️ SIGTERM received. Shutting down gracefully...');
  console.log('SIGTERM received. Shutting down gracefully...');
  stopScheduler();
  const { closeDB } = require('./config/db');
  await closeDB();
  process.exit(0);
});

process.on('SIGINT', async () => {
  logger.warn('⚠️ SIGINT received. Shutting down gracefully...');
  console.log('\nSIGINT received. Shutting down gracefully...');
  stopScheduler();
  const { closeDB } = require('./config/db');
  await closeDB();
  process.exit(0);
});

// Start the server
startServer();

module.exports = app;

