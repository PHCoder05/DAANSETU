# DAANSETU API Documentation (v1.0.0)

A comprehensive REST API for connecting donors with NGOs, enabling transparent donation tracking and management.

## `GET` /api/admin/users

**Summary**: Get all users (Admin only)

**Tags**: Admin

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| page | query | No | integer |  |
| limit | query | No | integer |  |
| role | query | No | string |  |
| verified | query | No | boolean |  |
| active | query | No | boolean |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | List of users |
| 403 | Admin access required |

## `DELETE` /api/admin/users/{userId}

**Summary**: Delete user (Admin only)

**Tags**: Admin

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| userId | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | User deleted successfully |

## `PUT` /api/admin/users/{userId}/toggle-status

**Summary**: Activate/deactivate user (Admin only)

**Tags**: Admin

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| userId | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | User status updated |

## `GET` /api/admin/ngos/pending

**Summary**: Get pending NGO verifications (Admin only)

**Tags**: Admin

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| page | query | No | integer |  |
| limit | query | No | integer |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | List of pending NGOs |

## `PUT` /api/admin/ngos/{userId}/verify

**Summary**: Verify or reject NGO (Admin only)

**Tags**: Admin

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| userId | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | NGO verification status updated |

## `GET` /api/admin/stats

**Summary**: Get platform statistics (Admin only)

**Tags**: Admin

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 200 | Platform statistics |

## `POST` /api/admin/seed

**Summary**: Seed test data (Development only)

**Tags**: Admin

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 200 | Test data seeded successfully |

## `GET` /api/v1/audit/my

**Summary**: Get current user's activity log

**Tags**: Audit

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| limit | query | No | integer | Max results (default 50) |
| action | query | No | string | Filter by action type |
| resource | query | No | string | Filter by resource type |

### Responses
| Code | Description |
| --- | --- |
| 200 | Activity log retrieved |

## `GET` /api/v1/audit/summary

**Summary**: Get activity summary for dashboard

**Tags**: Audit

**Security**: [{"bearerAuth":[]}]

## `GET` /api/v1/audit/donation/{donationId}

**Summary**: Get audit trail for a specific donation

**Tags**: Audit

**Security**: [{"bearerAuth":[]}]

## `GET` /api/v1/audit/user/{userId}

**Summary**: Admin - Get user's full activity history

**Tags**: Audit

**Security**: [{"bearerAuth":[]}]

## `GET` /api/auth/check-email

**Summary**: Check if email exists (for unified auth flow)

**Tags**: Authentication

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| email | query | Yes | string | Email address to check |

### Responses
| Code | Description |
| --- | --- |
| 200 | Email check completed |
| 400 | Email is required |

## `POST` /api/auth/register

**Summary**: Register a new user

**Tags**: Authentication

### Responses
| Code | Description |
| --- | --- |
| 201 | User registered successfully |
| 400 | Validation error or user already exists |

## `POST` /api/auth/login

**Summary**: Login user

**Tags**: Authentication

### Responses
| Code | Description |
| --- | --- |
| 200 | Login successful |
| 401 | Invalid credentials |

## `POST` /api/auth/refresh

**Summary**: Refresh access token

**Tags**: Authentication

### Responses
| Code | Description |
| --- | --- |
| 200 | Token refreshed successfully |
| 401 | Invalid or expired refresh token |

## `POST` /api/auth/logout

**Summary**: Logout user

**Tags**: Authentication

### Responses
| Code | Description |
| --- | --- |
| 200 | Logged out successfully |

## `GET` /api/auth/profile

**Summary**: Get user profile

**Tags**: Authentication

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 200 | Profile retrieved successfully |
| 401 | Unauthorized |

## `PUT` /api/auth/profile

**Summary**: Update user profile

**Tags**: Authentication

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 200 | Profile updated successfully |

## `POST` /api/auth/profile/image

**Summary**: Upload profile image

**Tags**: Authentication

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 200 | Image uploaded successfully |

## `POST` /api/auth/logout-all

**Summary**: Logout from all devices

**Tags**: Authentication

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 200 | Logged out from all devices |

## `PUT` /api/auth/change-password

**Summary**: Change password

**Tags**: Authentication

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 200 | Password changed successfully |
| 401 | Current password incorrect |

## `PUT` /api/auth/ngo-details

**Summary**: Update NGO details (NGO only)

**Tags**: Authentication

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 200 | NGO details updated successfully |
| 403 | Only NGOs can update NGO details |

## `POST` /api/auth/generate-token

**Summary**: Generate JWT token for a user by email or userId

**Description**: Generate access and refresh tokens for any user. No authentication required - useful for testing and development.

**Tags**: Authentication

### Responses
| Code | Description |
| --- | --- |
| 200 | JWT token generated successfully |
| 400 | User ID or email required, or user is deactivated |
| 404 | User not found |

## `GET` /api/auth/leaderboard

**Summary**: Get donor leaderboard

**Tags**: Authentication

### Responses
| Code | Description |
| --- | --- |
| 200 | Leaderboard retrieved successfully |

## `POST` /api/v1/auth/bookmark

**Summary**: Toggle bookmark for a donation

**Tags**: Authentication

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 200 | Bookmark toggled successfully |

## `POST` /api/v1/auth/send-verification

**Summary**: Send email verification link

**Tags**: Authentication

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 200 | Verification email sent |

## `POST` /api/v1/auth/verify-email

**Summary**: Verify email with token

**Tags**: Authentication

### Responses
| Code | Description |
| --- | --- |
| 200 | Email verified successfully |

## `GET` /api/v1/chat/history/{recipientId}

**Summary**: Get chat history with a user

**Tags**: Chat

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| recipientId | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Chat history retrieved |

## `GET` /api/v1/chat/donation/{donationId}/{recipientId}

**Summary**: Get chat history for a specific donation

**Tags**: Chat

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| donationId | path | Yes | string |  |
| recipientId | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Chat history for donation retrieved |

## `GET` /api/v1/chat/conversations

**Summary**: Get list of conversations (grouped by user)

**Tags**: Chat

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 200 | List of conversations |

## `GET` /api/v1/chat/conversations/by-donation

**Summary**: Get list of conversations grouped by donation

**Tags**: Chat

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 200 | List of conversations by donation |

## `PUT` /api/v1/chat/read/{recipientId}

**Summary**: Mark messages from a user as read

**Tags**: Chat

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| recipientId | path | Yes | string |  |
| donationId | query | No | string | Optional - filter by donation |

### Responses
| Code | Description |
| --- | --- |
| 200 | Messages marked as read |

## `GET` /api/dashboard

**Summary**: Get user dashboard data (role-specific)

**Tags**: Dashboard

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 200 | Dashboard data retrieved successfully |

## `GET` /api/dashboard/activity

**Summary**: Get user activity history

**Tags**: Dashboard

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| page | query | No | integer |  |
| limit | query | No | integer |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Activity history retrieved |

## `GET` /api/dashboard/leaderboard

**Summary**: Get platform leaderboard

**Tags**: Dashboard

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| type | query | No | string | Leaderboard type (default donors) |
| limit | query | No | integer | Number of results (default 10) |

### Responses
| Code | Description |
| --- | --- |
| 200 | Leaderboard data |

## `GET` /api/v1/delivery/{donationId}

**Summary**: Get tracking status for a donation

**Tags**: Delivery

**Security**: [{"bearerAuth":[]}]

## `POST` /api/v1/delivery/{donationId}/initialize

**Summary**: Initialize tracking (NGO only)

**Tags**: Delivery

**Security**: [{"bearerAuth":[]}]

## `POST` /api/v1/delivery/{donationId}/pickup

**Summary**: Mark donation as picked up with QR, photo, signature

**Tags**: Delivery

**Security**: [{"bearerAuth":[]}]

## `POST` /api/v1/delivery/{donationId}/location

**Summary**: Update GPS location during transit

**Tags**: Delivery

**Security**: [{"bearerAuth":[]}]

## `POST` /api/v1/delivery/{donationId}/deliver

**Summary**: Mark donation as delivered with QR, photo, signature

**Tags**: Delivery

**Security**: [{"bearerAuth":[]}]

## `POST` /api/v1/delivery/{donationId}/confirm

**Summary**: Donor confirms delivery

**Tags**: Delivery

**Security**: [{"bearerAuth":[]}]

## `GET` /api/v1/delivery/active

**Summary**: Get NGO's active deliveries

**Tags**: Delivery

**Security**: [{"bearerAuth":[]}]

## `GET` /api/v1/delivery/{donationId}/history

**Summary**: Get location history for a delivery

**Tags**: Delivery

**Security**: [{"bearerAuth":[]}]

## `GET` /api/donations

**Summary**: Get all donations

**Tags**: Donations

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| page | query | No | integer | Page number |
| limit | query | No | integer | Items per page |
| category | query | No | string |  |
| status | query | No | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | List of donations |

## `POST` /api/donations

**Summary**: Create a new donation (Donor only)

**Tags**: Donations

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 201 | Donation created successfully |
| 403 | Only donors can create donations |

## `GET` /api/donations/nearby

**Summary**: Find nearby donations

**Tags**: Donations

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| lat | query | Yes | number |  |
| lng | query | Yes | number |  |
| maxDistance | query | No | number | Maximum distance in km (default 50) |

### Responses
| Code | Description |
| --- | --- |
| 200 | List of nearby donations |

## `GET` /api/donations/{id}

**Summary**: Get donation by ID

**Tags**: Donations

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| id | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Donation details |
| 404 | Donation not found |

## `PUT` /api/donations/{id}

**Summary**: Update donation

**Tags**: Donations

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| id | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Donation updated successfully |

## `DELETE` /api/donations/{id}

**Summary**: Delete donation

**Tags**: Donations

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| id | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Donation deleted successfully |

## `POST` /api/donations/{id}/claim

**Summary**: Claim a donation (Verified NGO only)

**Tags**: Donations

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| id | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Donation claimed successfully |
| 403 | NGO must be verified |

## `PUT` /api/donations/{id}/status

**Summary**: Update donation status

**Tags**: Donations

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| id | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Status updated successfully |

## `GET` /api/donations/stats/summary

**Summary**: Get donation statistics

**Tags**: Donations

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 200 | Statistics retrieved successfully |

## `GET` /api/donations/my

**Summary**: Get my donations (as donor or NGO)

**Tags**: Donations

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| type | query | No | string | Filter by status type |
| role | query | No | string | Override role for filter |

### Responses
| Code | Description |
| --- | --- |
| 200 | List of user's donations |

## `GET` /api/donations/{id}/timeline

**Summary**: Get donation timeline (status history)

**Tags**: Donations

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| id | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Timeline retrieved |

## `GET` /api/ngos

**Summary**: Get all verified NGOs

**Tags**: NGOs

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| page | query | No | integer |  |
| limit | query | No | integer |  |
| search | query | No | string |  |
| category | query | No | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | List of verified NGOs |

## `GET` /api/ngos/{id}

**Summary**: Get NGO by ID

**Tags**: NGOs

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| id | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | NGO details |
| 404 | NGO not found |

## `POST` /api/ngos/requests

**Summary**: Create a donation request (Verified NGO only)

**Tags**: NGOs

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 201 | Request created successfully |
| 403 | NGO must be verified |

## `GET` /api/ngos/requests/list

**Summary**: Get donation requests

**Tags**: NGOs

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| page | query | No | integer |  |
| limit | query | No | integer |  |
| status | query | No | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | List of requests |

## `PUT` /api/ngos/requests/{id}/status

**Summary**: Approve or reject a request (Donor only)

**Tags**: NGOs

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| id | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Request status updated |

## `PUT` /api/ngos/requests/{id}/cancel

**Summary**: Cancel own request (NGO only)

**Tags**: NGOs

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| id | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Request cancelled successfully |

## `GET` /api/notifications

**Summary**: Get user notifications

**Tags**: Notifications

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| page | query | No | integer |  |
| limit | query | No | integer |  |
| unreadOnly | query | No | boolean |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | List of notifications |

## `GET` /api/notifications/unread-count

**Summary**: Get unread notification count

**Tags**: Notifications

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 200 | Unread count |

## `PUT` /api/notifications/{id}/read

**Summary**: Mark notification as read

**Tags**: Notifications

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| id | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Notification marked as read |

## `PUT` /api/notifications/read-all

**Summary**: Mark all notifications as read

**Tags**: Notifications

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 200 | All notifications marked as read |

## `DELETE` /api/notifications/{id}

**Summary**: Delete notification

**Tags**: Notifications

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| id | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Notification deleted |

## `POST` /api/password-reset/request

**Summary**: Request password reset

**Tags**: Password Reset

### Responses
| Code | Description |
| --- | --- |
| 200 | Reset link sent (if email exists) |

## `GET` /api/password-reset/verify

**Summary**: Verify reset token validity

**Tags**: Password Reset

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| token | query | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Token is valid |
| 400 | Token is invalid or expired |

## `POST` /api/password-reset/reset

**Summary**: Reset password with token

**Tags**: Password Reset

### Responses
| Code | Description |
| --- | --- |
| 200 | Password reset successfully |
| 400 | Invalid or expired token |

## `POST` /api/reviews

**Summary**: Create review for NGO (Donor only)

**Tags**: Reviews

**Security**: [{"bearerAuth":[]}]

### Responses
| Code | Description |
| --- | --- |
| 201 | Review created successfully |
| 400 | Donation not delivered or already reviewed |

## `GET` /api/reviews/ngo/{ngoId}

**Summary**: Get reviews for an NGO

**Tags**: Reviews

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| ngoId | path | Yes | string |  |
| page | query | No | integer |  |
| limit | query | No | integer |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Reviews with average rating |

## `PUT` /api/reviews/{id}

**Summary**: Update own review (Donor only)

**Tags**: Reviews

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| id | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Review updated successfully |

## `DELETE` /api/reviews/{id}

**Summary**: Delete review

**Tags**: Reviews

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| id | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Review deleted successfully |

## `PUT` /api/reviews/{id}/respond

**Summary**: NGO respond to review

**Tags**: Reviews

**Security**: [{"bearerAuth":[]}]

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| id | path | Yes | string |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Response added successfully |

## `GET` /api/search/donations

**Summary**: Advanced search for donations

**Tags**: Search

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| q | query | No | string | Search query (title, description, tags) |
| category | query | No | string |  |
| status | query | No | string |  |
| priority | query | No | string |  |
| minQuantity | query | No | number |  |
| maxQuantity | query | No | number |  |
| location | query | No | string | Lat,Lng (e.g., 40.7128,-74.0060) |
| radius | query | No | number | Search radius in km (default 50) |
| page | query | No | integer |  |
| limit | query | No | integer |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | Search results |

## `GET` /api/search/ngos

**Summary**: Search for NGOs

**Tags**: Search

### Parameters
| Name | In | Required | Type | Description |
| --- | --- | --- | --- | --- |
| q | query | No | string | Search query (name, description) |
| category | query | No | string |  |
| page | query | No | integer |  |
| limit | query | No | integer |  |

### Responses
| Code | Description |
| --- | --- |
| 200 | NGO search results |

## `GET` /api/search/categories

**Summary**: Get all donation categories with counts

**Tags**: Search

### Responses
| Code | Description |
| --- | --- |
| 200 | List of categories with donation counts |

## `GET` /api/setup/check

**Summary**: Check if first-time setup is required

**Tags**: Setup

### Responses
| Code | Description |
| --- | --- |
| 200 | Setup status retrieved |

## `POST` /api/setup/admin

**Summary**: Create first admin account (one-time setup)

**Tags**: Setup

### Responses
| Code | Description |
| --- | --- |
| 201 | Admin account created successfully |
| 400 | Admin already exists or validation error |
| 403 | Invalid setup key |

## `POST` /api/v1/verification/request

**Summary**: Request verification (auto-verifies NGO via govt APIs)

**Tags**: Verification

**Security**: [{"bearerAuth":[]}]

## `POST` /api/v1/verification/ngo/auto-verify

**Summary**: Auto-verify NGO using government databases (Darpan, 80G, MCA)

**Tags**: Verification

**Security**: [{"bearerAuth":[]}]

## `POST` /api/v1/verification/ngo/darpan

**Summary**: Verify NGO using Darpan ID only

**Tags**: Verification

**Security**: [{"bearerAuth":[]}]

## `POST` /api/v1/verification/ngo/80g

**Summary**: Verify 80G certificate using PAN

**Tags**: Verification

**Security**: [{"bearerAuth":[]}]

## `GET` /api/v1/verification/status

**Summary**: Get my verification status

**Tags**: Verification

**Security**: [{"bearerAuth":[]}]

## `GET` /api/v1/verification/pending

**Summary**: Admin - Get pending verifications

**Tags**: Verification

**Security**: [{"bearerAuth":[]}]

## `POST` /api/v1/verification/{id}/approve

**Summary**: Admin - Approve verification

**Tags**: Verification

**Security**: [{"bearerAuth":[]}]

## `POST` /api/v1/verification/{id}/reject

**Summary**: Admin - Reject verification

**Tags**: Verification

**Security**: [{"bearerAuth":[]}]

## `POST` /api/v1/verification/{id}/bypass

**Summary**: Admin - Bypass government API verification and approve directly

**Tags**: Verification

**Security**: [{"bearerAuth":[]}]

## `POST` /api/v1/verification/{id}/rerun-api

**Summary**: Admin - Force re-run government API verification

**Tags**: Verification

**Security**: [{"bearerAuth":[]}]

## `POST` /api/v1/verification/support/request

**Summary**: NGO - Request support / contact admin for verification issues

**Tags**: Verification

**Security**: [{"bearerAuth":[]}]

## `GET` /api/v1/verification/support/my

**Summary**: NGO - Get my support requests

**Tags**: Verification

**Security**: [{"bearerAuth":[]}]

## `GET` /api/v1/verification/support/all

**Summary**: Admin - Get all support requests

**Tags**: Verification

**Security**: [{"bearerAuth":[]}]

## `POST` /api/v1/verification/support/{id}/respond

**Summary**: Admin - Respond to support request

**Tags**: Verification

**Security**: [{"bearerAuth":[]}]

## `GET` /api/v1/verification/fraud-alerts

**Summary**: Admin - Get fraud alerts

**Tags**: Verification

**Security**: [{"bearerAuth":[]}]

## `POST` /api/v1/verification/fraud-alerts/{id}/resolve

**Summary**: Admin - Resolve fraud alert

**Tags**: Verification

**Security**: [{"bearerAuth":[]}]

