# ✅ User Verification Process Guide

## Overview

DAANSETU implements a **multi-stage verification system** to ensure:
- Legitimate users
- Verified NGOs before they can claim donations
- Platform security and trust
- Proper role-based access control

---

## 👥 User Roles & Verification Stages

### 1. **Donor** (Role: `donor`)

#### Registration Stage
```
User Registers → Account Created → Basic Email Verification (Optional) → Can Create Donations
```

**Verification Requirements:**
- ✅ Valid email
- ✅ Strong password
- ✅ Basic profile information

**Immediate Permissions:**
- Create donations
- Update own donations
- View all donations
- View NGOs
- Respond to requests

**No Admin Approval Required!**

**Implementation:**
```json
{
  "email": "donor@example.com",
  "password": "password123",
  "name": "John Doe",
  "role": "donor",
  "phone": "+1234567890",
  "location": {
    "lat": 40.7128,
    "lng": -74.0060,
    "address": "New York, NY"
  }
}
```

---

### 2. **NGO** (Role: `ngo`)

#### Multi-Stage Verification

```
Registration → Pending → Admin Review → Verified/Rejected → Can Claim Donations
```

**Stage 1: Registration**
```json
{
  "email": "ngo@example.com",
  "password": "password123",
  "name": "Hope Foundation",
  "role": "ngo",
  "phone": "+1234567891",
  "location": {
    "lat": 40.7580,
    "lng": -73.9855,
    "address": "New York, NY"
  },
  "ngoDetails": {
    "registrationNumber": "NGO12345",
    "description": "Helping communities in need since 2020",
    "website": "https://hope.org",
    "categories": ["food", "clothes"],
    "establishedYear": 2020
  }
}
```

**Account Status After Registration:**
```javascript
{
  verified: false,
  ngoDetails: {
    verificationStatus: 'pending',
    // other details...
  }
}
```

**Permissions at This Stage:**
- ❌ Cannot claim donations
- ❌ Cannot request donations (can request but won't be prioritized)
- ✅ Can view available donations
- ✅ Can update profile
- ✅ Can add more documentation

**Stage 2: Pending (Awaiting Admin Review)**

NGO waits for admin to review their application.

**What Admins Check:**
- Registration number validity
- Organization legitimacy
- Contact information
- Website and social proof
- Categories of work
- Uploaded documents (if any)

**Stage 3: Admin Decision**

**Option A: Verification Approved**
```bash
PUT /api/admin/ngos/:userId/verify
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "status": "verified",
  "reason": "All documents verified"
}
```

**Account Status After Approval:**
```javascript
{
  verified: true,
  ngoDetails: {
    verificationStatus: 'verified',
    // other details...
  }
}
```

**New Permissions:**
- ✅ Can claim donations
- ✅ Can request donations with priority
- ✅ Requests are highlighted to donors
- ✅ Full platform access

**Option B: Verification Rejected**
```bash
PUT /api/admin/ngos/:userId/verify
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "status": "rejected",
  "reason": "Invalid registration number. Please provide valid documentation."
}
```

**Account Status After Rejection:**
```javascript
{
  verified: false,
  ngoDetails: {
    verificationStatus: 'rejected',
    verificationReason: 'Invalid registration number...',
    // other details...
  }
}
```

**What Happens:**
- ❌ Cannot claim donations
- ❌ Requests are not prioritized
- ✅ Can re-submit with correct information
- ✅ Can contact support

---

### 3. **Admin** (Role: `admin`)

#### First-Time Setup

**Stage 1: Check if Setup is Needed**
```bash
GET /api/setup/check
```

**Response if no admin exists:**
```json
{
  "success": true,
  "data": {
    "setupRequired": true,
    "message": "First-time setup required. Create an admin account."
  }
}
```

**Stage 2: Create First Admin**
```bash
POST /api/setup/admin
Content-Type: application/json

{
  "email": "admin@daansetu.org",
  "password": "SecureAdminPassword123!",
  "name": "Admin Name",
  "setupKey": "your-setup-key-from-env"
}
```

**Setup Key:** Set in `.env` file:
```env
ADMIN_SETUP_KEY=change-this-setup-key-in-production
```

**Response:**
```json
{
  "success": true,
  "message": "Admin account created successfully",
  "data": {
    "user": {
      "_id": "...",
      "email": "admin@daansetu.org",
      "role": "admin",
      "verified": true
    },
    "accessToken": "...",
    "refreshToken": "..."
  }
}
```

**Admin Permissions:**
- ✅ Verify/reject NGOs
- ✅ View all users
- ✅ Activate/deactivate accounts
- ✅ Delete users
- ✅ View platform statistics
- ✅ Access all data

**Security:**
- ⚠️ Setup endpoint only works when NO admin exists
- ⚠️ Requires secret setup key
- ⚠️ Should be disabled in production after first use

---

## 🔄 Verification Workflows

### NGO Verification Workflow

```
┌─────────────┐
│  NGO Signs  │
│     Up      │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│  Account Created    │
│  Status: Pending    │
│  verified: false    │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Notification Sent  │
│  to Admin           │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Admin Reviews      │
│  Documents & Info   │
└──────┬──────────────┘
       │
       ├─────────────────┬─────────────────┐
       ▼                 ▼                 ▼
┌──────────┐    ┌───────────┐    ┌────────────┐
│ Verified │    │ Rejected  │    │ Need More  │
└────┬─────┘    └─────┬─────┘    │    Info    │
     │                │           └──────┬─────┘
     │                │                  │
     ▼                ▼                  │
┌──────────┐    ┌───────────┐          │
│ Can Claim│    │ Re-submit │◄─────────┘
│ Donations│    │ Required  │
└──────────┘    └───────────┘
```

### Donation Claim Workflow

```
┌──────────────┐
│ NGO Attempts │
│  to Claim    │
└──────┬───────┘
       │
       ▼
    ┌──────┐
    │Check:│
    │NGO   │
    │Role? │
    └──┬───┘
       │
       ├────────────────┬────────────────┐
       ▼                ▼                ▼
   ┌────┐         ┌─────────┐    ┌──────────┐
   │Yes │         │   No    │    │  Check:  │
   └─┬──┘         └────┬────┘    │ Verified?│
     │                 │          └────┬─────┘
     │                 │               │
     │                 ▼               ├──────────┬──────────┐
     │          ┌──────────┐          ▼          ▼          ▼
     │          │  403     │      ┌────┐    ┌──────┐  ┌──────┐
     │          │Forbidden │      │Yes │    │  No  │  │Reject│
     │          └──────────┘      └─┬──┘    └───┬──┘  └───┬──┘
     │                               │           │         │
     │                               ▼           ▼         ▼
     │                        ┌───────────┐ ┌─────────┐ ┌─────┐
     │                        │Claim OK!  │ │  403    │ │ 403 │
     └────────────────────────┤Update     │ │Pending  │ │Reject│
                              │Status     │ └─────────┘ └─────┘
                              └───────────┘
```

---

## 📧 Notification System

### Automatic Notifications

**When NGO Registers:**
- ✅ Notification sent to all admins
- 📧 Email to admins (if email service configured)
- 📱 Dashboard alert for admins

**When Admin Verifies NGO:**
- ✅ Notification sent to NGO
- ✉️ Success message with next steps
- 🎉 Welcome to verified NGOs

**When Admin Rejects NGO:**
- ✅ Notification sent to NGO with reason
- 📝 Instructions for re-submission
- 📞 Contact support information

---

## 🔐 Security Considerations

### For NGO Verification

**What to Verify:**
1. **Registration Number**
   - Check against government databases
   - Verify format and structure
   - Cross-reference with official records

2. **Organization Details**
   - Verify website exists and is active
   - Check social media presence
   - Confirm phone and address

3. **Documentation** (if provided)
   - Registration certificate
   - Tax exemption documents
   - Board member information
   - Recent activity reports

4. **Red Flags:**
   - ⚠️ New email domains
   - ⚠️ No online presence
   - ⚠️ Suspicious registration numbers
   - ⚠️ Incomplete information
   - ⚠️ Mismatched details

### Verification Timeline

**Recommended:**
- ✅ Review within 24-48 hours
- ✅ Request additional info if needed
- ✅ Provide clear rejection reasons
- ✅ Allow re-submission

---

## 🎯 API Endpoints

### NGO Verification (Admin Only)

**Get Pending NGOs:**
```bash
GET /api/admin/ngos/pending?page=1&limit=10
Authorization: Bearer <admin-token>
```

**Verify/Reject NGO:**
```bash
PUT /api/admin/ngos/:userId/verify
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "status": "verified",  // or "rejected"
  "reason": "Optional reason for rejection"
}
```

**Get All NGOs:**
```bash
GET /api/ngos?page=1&limit=10
```
*Only returns verified NGOs to public*

---

## 💡 Best Practices

### For Administrators

1. **Quick Response**
   - Review applications within 24 hours
   - Set up email notifications
   - Regular check of pending queue

2. **Thorough Verification**
   - Don't rush the process
   - Verify all provided information
   - Contact NGO if details unclear

3. **Clear Communication**
   - Provide specific rejection reasons
   - Offer guidance for re-submission
   - Be available for questions

4. **Documentation**
   - Keep notes on verification decisions
   - Document red flags or concerns
   - Maintain audit trail

### For NGOs

1. **Complete Profile**
   - Fill all required information
   - Provide valid registration number
   - Include working contact details

2. **Professional Presence**
   - Maintain updated website
   - Active social media
   - Clear mission statement

3. **Be Patient**
   - Verification takes 24-48 hours
   - Check email for updates
   - Respond promptly to requests

4. **Stay Active**
   - Update profile regularly
   - Report changes in details
   - Maintain good standing

---

## 🧪 Testing the Verification Flow

### 1. Register as NGO
```bash
POST /api/auth/register
Content-Type: application/json

{
  "email": "testngo@example.com",
  "password": "password123",
  "name": "Test NGO",
  "role": "ngo",
  "ngoDetails": {
    "registrationNumber": "TEST123",
    "description": "Test NGO for verification flow",
    "categories": ["food"]
  }
}
```

### 2. Try to Claim (Should Fail)
```bash
POST /api/donations/:id/claim
Authorization: Bearer <ngo-token>

# Expected: 403 Forbidden - "Your NGO must be verified"
```

### 3. Admin Verifies
```bash
PUT /api/admin/ngos/:userId/verify
Authorization: Bearer <admin-token>

{
  "status": "verified"
}
```

### 4. Try to Claim (Should Succeed)
```bash
POST /api/donations/:id/claim
Authorization: Bearer <ngo-token>

# Expected: 200 OK - Donation claimed
```

---

## ✅ Verification Checklist

**For NGO Registration:**
- [ ] Registration number provided
- [ ] Description is clear and professional
- [ ] Contact information complete
- [ ] Categories selected
- [ ] Website (if available)

**For Admin Review:**
- [ ] Verify registration number
- [ ] Check website/social media
- [ ] Validate contact information
- [ ] Review categories
- [ ] Check for red flags
- [ ] Make decision within 48 hours

**For System Integration:**
- [ ] Automatic notifications working
- [ ] Email notifications (if configured)
- [ ] Dashboard alerts for admins
- [ ] NGO can see verification status
- [ ] Claiming blocked until verified
- [ ] Re-submission allowed after rejection

---

**The verification system ensures trust and security on the DAANSETU platform! ✅**

