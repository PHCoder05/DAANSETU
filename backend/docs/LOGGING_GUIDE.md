# 📝 Winston Logging Guide

## Overview

DAANSETU uses **Winston** - the most popular and feature-rich logging library for Node.js!

---

## 🎯 What You Get

### ✅ **Features Implemented**

1. **📺 Colored Console Logs** - Beautiful, readable logs in terminal
2. **📄 File Logging** - All logs saved to files
3. **🔴 Error Files** - Separate file for errors only
4. **📊 Structured Logging** - JSON format for easy parsing
5. **🔄 Daily Rotation** - Logs rotate daily in production
6. **💾 Automatic Cleanup** - Old logs auto-deleted
7. **🎨 Custom Formats** - Different formats for dev/prod
8. **📍 Context Logging** - Rich metadata with every log

---

## 🎨 Log Levels

Winston uses these log levels (in order of priority):

```
error   - 🔴 Errors and exceptions
warn    - 🟡 Warning messages
info    - 🔵 Important information (default)
http    - 🌐 HTTP requests
verbose - 📝 Detailed information
debug   - 🐛 Debug messages
silly   - 🤪 Everything
```

**Default Level:** `info` (shows error, warn, info)

---

## 📁 Log Files

All logs are saved to `/logs` directory:

### Development
```
/logs
  ├── combined.log     # All logs
  ├── error.log        # Errors only
  ├── exceptions.log   # Uncaught exceptions
  └── rejections.log   # Unhandled promise rejections
```

### Production
```
/logs
  ├── combined-2025-10-11.log    # Daily combined logs
  ├── error-2025-10-11.log       # Daily error logs
  ├── exceptions.log
  └── rejections.log
```

**Auto-rotation:** Logs rotate daily, kept for 14 days, zipped after 20MB

---

## 🚀 How to Use

### 1. Import Logger

```javascript
const logger = require('./utils/logger');
```

### 2. Basic Logging

```javascript
// Error
logger.error('Something went wrong!');

// Warning
logger.warn('This might be a problem');

// Info (most common)
logger.info('Server started successfully');

// Debug
logger.debug('Variable value:', someVariable);
```

### 3. Structured Logging (with metadata)

```javascript
logger.info('User logged in', {
  userId: '12345',
  email: 'user@example.com',
  ip: '192.168.1.1'
});

// Output:
// 2025-10-11 10:30:45 [info]: User logged in {
//   "userId": "12345",
//   "email": "user@example.com",
//   "ip": "192.168.1.1"
// }
```

### 4. Helper Functions (Built-in)

#### Log Authentication Events
```javascript
logger.logAuth('login', userId, true, {
  ip: req.ip,
  userAgent: req.get('user-agent')
});
```

#### Log Database Operations
```javascript
logger.logDatabase('insert', 'users', {
  operation: 'create',
  userId: newUser._id
});
```

#### Log Errors with Context
```javascript
try {
  // some code
} catch (error) {
  logger.logError(error, {
    userId: req.user.userId,
    action: 'createDonation'
  });
}
```

---

## 📊 Real Examples

### Example 1: HTTP Request Logging

**Automatically logged by middleware:**

```
2025-10-11 10:30:45 [info]: 🔵 Incoming Request {
  "method": "POST",
  "url": "/api/auth/login",
  "ip": "127.0.0.1",
  "userAgent": "PostmanRuntime/7.32.0",
  "body": {
    "email": "user@example.com",
    "password": "***REDACTED***"
  }
}

2025-10-11 10:30:46 [info]: 🟢 Response Sent {
  "method": "POST",
  "url": "/api/auth/login",
  "statusCode": 200,
  "responseTime": "234ms"
}
```

### Example 2: Error Logging

```javascript
// In your controller
try {
  const donation = await Donation.create(db, donationData);
  logger.info('Donation created', {
    donationId: donation._id,
    donorId: req.user.userId,
    category: donation.category
  });
} catch (error) {
  logger.error('Failed to create donation', {
    error: error.message,
    userId: req.user.userId,
    stack: error.stack
  });
  return errorResponse(res, 500, 'Error creating donation');
}
```

### Example 3: Authentication Logging

```javascript
// Successful login
logger.logAuth('login', user._id, true, {
  email: user.email,
  role: user.role
});

// Failed login
logger.logAuth('login', null, false, {
  email: req.body.email,
  reason: 'Invalid password',
  ip: req.ip
});
```

---

## 🔧 Configuration

### Change Log Level

In `.env`:
```env
LOG_LEVEL=debug    # For development (shows everything)
LOG_LEVEL=info     # For production (recommended)
LOG_LEVEL=error    # Only errors
```

### Disable File Logging

In `utils/logger.js`, comment out file transports.

### Custom Format

```javascript
// Add to logger.js
const customFormat = winston.format.printf(({ level, message, timestamp }) => {
  return `[${timestamp}] ${level.toUpperCase()}: ${message}`;
});
```

---

## 📺 Console Output

### What You See in Terminal

**Colored and formatted:**

```bash
2025-10-11 10:30:45 [info]: 🚀 DAANSETU API Server Started
2025-10-11 10:30:45 [info]: 📡 Port: 3000
2025-10-11 10:30:45 [info]: 🌍 Environment: development
2025-10-11 10:30:46 [info]: 🔵 Incoming Request { "method": "GET", "url": "/health" }
2025-10-11 10:30:46 [info]: 🟢 Response Sent { "statusCode": 200, "responseTime": "5ms" }
```

**Color Code:**
- 🔴 Red = Error
- 🟡 Yellow = Warning
- 🔵 Blue = Info
- 🟢 Green = Success

---

## 🔍 Searching Logs

### Using grep (Linux/Mac)
```bash
# Find all errors
grep "error" logs/combined.log

# Find specific user actions
grep "userId.*12345" logs/combined.log

# Find slow requests (>1000ms)
grep "responseTime.*[0-9]{4,}ms" logs/combined.log
```

### Using PowerShell (Windows)
```powershell
# Find errors
Select-String -Path "logs\combined.log" -Pattern "error"

# Find by user
Select-String -Path "logs\combined.log" -Pattern "userId.*12345"
```

### View Live Logs
```bash
# Linux/Mac
tail -f logs/combined.log

# PowerShell
Get-Content logs\combined.log -Wait -Tail 50
```

---

## 📊 Log Analysis

### Example Log Entry (JSON)

```json
{
  "timestamp": "2025-10-11 10:30:45",
  "level": "info",
  "message": "User logged in",
  "userId": "67089abcd1234567",
  "email": "user@example.com",
  "ip": "127.0.0.1",
  "userAgent": "Mozilla/5.0..."
}
```

### Parsing Logs

```javascript
// Read and parse logs
const fs = require('fs');
const logs = fs.readFileSync('logs/combined.log', 'utf8')
  .split('\n')
  .filter(line => line)
  .map(line => JSON.parse(line));

// Find errors
const errors = logs.filter(log => log.level === 'error');

// Count by level
const counts = logs.reduce((acc, log) => {
  acc[log.level] = (acc[log.level] || 0) + 1;
  return acc;
}, {});
```

---

## 🚨 Error Tracking

### Automatic Error Logging

**Uncaught Exceptions:**
```javascript
// Automatically logged to exceptions.log
throw new Error('Something went wrong!');
```

**Unhandled Rejections:**
```javascript
// Automatically logged to rejections.log
Promise.reject(new Error('Promise failed'));
```

**Global Errors:**
```javascript
// Automatically logged by error handler
app.use((err, req, res, next) => {
  logger.error('Global Error', { error: err });
  res.status(500).json({ error: 'Something went wrong' });
});
```

---

## 🎯 Best Practices

### DO ✅

```javascript
// Include context
logger.info('User registered', {
  userId: user._id,
  email: user.email,
  role: user.role
});

// Log important events
logger.info('Payment processed', {
  amount: payment.amount,
  currency: payment.currency
});

// Use appropriate levels
logger.error('Database connection failed');
logger.warn('API rate limit approaching');
logger.info('New user registered');
logger.debug('Cache hit for key: users:123');
```

### DON'T ❌

```javascript
// Don't log sensitive data
logger.info('User login', {
  password: user.password  // ❌ Never!
});

// Don't log too much in production
logger.debug('Variable dump:', hugeObject);  // ❌ Too verbose

// Don't use console.log
console.log('Something happened');  // ❌ Use logger instead

// Don't log in loops (performance)
for (let i = 0; i < 10000; i++) {
  logger.debug('Processing:', i);  // ❌ Too many logs
}
```

---

## 🔒 Security

### Sensitive Data Protection

**Automatically redacted in logs:**
- `password`
- `token`
- `refreshToken`
- `accessToken`
- `secret`

```javascript
// Request body with password
{ email: 'user@example.com', password: 'secret123' }

// Logged as:
{ email: 'user@example.com', password: '***REDACTED***' }
```

### Add More Sensitive Fields

In `middleware/requestLogger.js`:
```javascript
const sensitiveFields = [
  'password', 
  'token', 
  'creditCard',  // Add this
  'ssn'          // Add this
];
```

---

## 📈 Monitoring

### Log Monitoring Tools

**Free:**
- Papertrail
- Loggly (free tier)
- LogDNA (free tier)

**Paid:**
- Datadog
- Splunk
- New Relic

### Simple Monitoring Script

```javascript
// monitor-logs.js
const fs = require('fs');
const logger = require('./utils/logger');

// Count errors in last hour
const oneHourAgo = Date.now() - (60 * 60 * 1000);
const logs = fs.readFileSync('logs/combined.log', 'utf8')
  .split('\n')
  .filter(line => line)
  .map(line => JSON.parse(line))
  .filter(log => new Date(log.timestamp) > oneHourAgo)
  .filter(log => log.level === 'error');

if (logs.length > 10) {
  logger.warn(`High error rate: ${logs.length} errors in last hour`);
}
```

---

## 🧪 Testing Logs

```javascript
// test-logger.js
const logger = require('./utils/logger');

logger.error('This is an error');
logger.warn('This is a warning');
logger.info('This is info');
logger.debug('This is debug');

logger.info('With metadata', {
  userId: '12345',
  action: 'test',
  data: { foo: 'bar' }
});

logger.logAuth('test', '12345', true);
logger.logDatabase('insert', 'users', { userId: '12345' });
```

Run: `node test-logger.js`

---

## ✅ Quick Checklist

- [x] Winston installed
- [x] Logger configured
- [x] Request logging middleware added
- [x] Error handler uses logger
- [x] Database operations logged
- [x] Authentication events logged
- [x] Sensitive data redacted
- [x] Log files created in /logs
- [x] Gitignore updated
- [x] Daily rotation (production)

---

## 📞 Common Commands

```bash
# View all logs
cat logs/combined.log

# View errors only
cat logs/error.log

# View last 50 lines
tail -50 logs/combined.log

# Follow logs in real-time
tail -f logs/combined.log

# Search for specific text
grep "error" logs/combined.log

# Count errors
grep -c "error" logs/combined.log
```

---

## 🎉 Summary

**You Now Have:**

✅ **Comprehensive Logging** - Every action logged  
✅ **Beautiful Console** - Colored, formatted output  
✅ **File Logging** - All logs saved to files  
✅ **Error Tracking** - Separate error logs  
✅ **Request Logging** - Every API call logged  
✅ **Structured Data** - JSON format for parsing  
✅ **Auto Rotation** - Daily rotation in production  
✅ **Security** - Sensitive data redacted  

**All logs are in:** `/logs` directory

**View logs live:** `tail -f logs/combined.log`

**Your API is now production-ready with enterprise-grade logging! 📝**

