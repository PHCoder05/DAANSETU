# DAANSETU API Development Guidelines

This document defines best practices for API development to ensure **data isolation** and prevent security issues.

---

## Core Principles

1. **Deny by default** - All data is private unless explicitly made public
2. **Automatic filtering** - Use helpers that filter by ownership
3. **Response sanitization** - Always sanitize before returning data
4. **Ownership validation** - Check access before revealing details

---

## Required Imports

```javascript
const { checkOwnership, buildSecureFilter } = require('../utils/helpers');
const { sanitizeDonation, sanitizeUser } = require('../utils/responseSanitizer');
```

---

## Standard Patterns

### 1. Getting a Single Resource

```javascript
const getResourceById = async (req, res) => {
  const resource = await Resource.findById(db, id);
  
  if (!resource) {
    return errorResponse(res, 404, 'Not found');
  }
  
  // ✅ Always check ownership
  const access = checkOwnership(resource, req.user);
  
  // ✅ Always sanitize response
  const sanitized = sanitizeDonation(resource, req.user);
  
  return successResponse(res, 200, 'Success', { resource: sanitized });
};
```

### 2. Listing Resources

```javascript
const getResources = async (req, res) => {
  // ✅ Use buildSecureFilter for automatic ownership filtering
  const filter = buildSecureFilter(
    { status: req.query.status },
    req.user,
    { requireOwnership: true }
  );
  
  const resources = await Resource.find(db, filter);
  
  // ✅ Sanitize all items in the list
  const sanitized = resources.map(r => sanitizeDonation(r, req.user));
  
  return successResponse(res, 200, 'Success', { resources: sanitized });
};
```

### 3. Updating Resources

```javascript
const updateResource = async (req, res) => {
  const resource = await Resource.findById(db, id);
  
  // ✅ Check if user owns the resource
  if (!req.ownership.isOwner(resource)) {
    return errorResponse(res, 403, 'Access denied');
  }
  
  // Proceed with update...
};
```

---

## Available Helpers

| Helper | Purpose |
|--------|---------|
| `checkOwnership(resource, user)` | Check if user can access resource |
| `buildSecureFilter(filter, user)` | Add ownership constraints to queries |
| `req.ownership.isOwner(resource)` | Quick owner check (middleware) |
| `req.ownership.isClaimer(resource)` | Quick claimer check (middleware) |
| `req.ownership.canAccess(resource)` | Full access check (middleware) |
| `sanitizeDonation(donation, user)` | Remove sensitive donation fields |
| `sanitizeUser(user)` | Remove passwords/tokens from user |

---

## ⚠️ What NOT to Do

```javascript
// ❌ BAD: Returning data without sanitization
return successResponse(res, 200, 'Success', { donation });

// ✅ GOOD: Always sanitize
return successResponse(res, 200, 'Success', { 
  donation: sanitizeDonation(donation, req.user) 
});
```

```javascript
// ❌ BAD: List query without ownership filter
const donations = await Donation.find({ status: 'claimed' });

// ✅ GOOD: Use secure filter
const filter = buildSecureFilter({ status: 'claimed' }, req.user);
const donations = await Donation.find(filter);
```

---

## Checklist for New Endpoints

- [ ] Used `checkOwnership()` or `req.ownership.canAccess()`
- [ ] Used `buildSecureFilter()` for list queries
- [ ] Used `sanitizeDonation()` / `sanitizeUser()` on responses
- [ ] Tested with different user roles (donor, ngo, admin)
- [ ] Tested with unauthorized users
