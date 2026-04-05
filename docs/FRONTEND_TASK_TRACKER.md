# Daansetu Web App — Development Task Tracker

> Estimated total effort: ~8–10 weeks (solo) / ~4–5 weeks (2-person team)  
> All tasks follow the architecture defined in `architecture.md`

---

## Phase 0 — Project Setup & Infrastructure

**Goal**: Scaffold, configure tooling, and establish the dev baseline.  
**Estimated Time**: 2–3 days

- [x] **P0-1** — Scaffold Next.js 14 app with TypeScript, Tailwind, App Router, src dir
- [x] **P0-2** — Initialise ShadCN UI (`npx shadcn@latest init`), configure `components.json`
- [ ] **P0-3** — Set up ESLint + Prettier + Husky + lint-staged + commitlint
- [x] **P0-4** — Configure `@t3-oss/env-nextjs` env validation, create `.env.example`
- [x] **P0-5** — Set up TanStack Query provider (`QueryProvider.tsx`) in root layout
- [x] **P0-6** — Create Axios instance with request/response interceptors (`src/lib/api/axios.ts`)
- [x] **P0-7** — Set up Zustand stores: `auth.store.ts`, `ui.store.ts`, `notification.store.ts`, `chat.store.ts`
- [x] **P0-8** — Configure Tailwind design tokens (CSS variables for brand colors, radius, etc.)
- [x] **P0-9** — Create `AppProviders.tsx` wrapper (Query + Auth + Theme + Socket providers)
- [x] **P0-10** — Set up folder structure: `components/`, `services/`, `queries/`, `types/`, `hooks/`, `lib/`
- [x] **P0-11** — Configure `tsconfig.json` path aliases (`@/*`)
- [ ] **P0-12** — Add `@next/bundle-analyzer` and configure `next.config.ts`
- [x] **P0-13** — Install all libraries per `architecture.md` quick-start commands
- [x] **P0-14** — Create `src/lib/constants/routes.ts` and `src/lib/constants/roles.ts`
- [x] **P0-15** — Create `src/lib/utils/cn.ts`, `formatters.ts`, `validators.ts`

---

## Phase 1 — Authentication Module

**Goal**: Complete login/register/password-reset flows with session management.  
**Estimated Time**: 3–4 days

### Services & Queries

- [x] **P1-1** — Create `auth.service.ts` (all `/api/auth/*` and `/api/password-reset/*` calls)
- [x] **P1-2** — Create `useAuthQueries.ts` (useLogin, useRegister, useLogout, useProfile mutation hooks)
- [x] **P1-3** — Implement `AuthProvider.tsx` — on mount, call GET `/api/auth/profile` to restore session from cookie

### Layouts & Pages

- [x] **P1-4** — Create `(auth)/layout.tsx` — centered card layout with Daansetu branding
- [x] **P1-5** — Build `LoginForm.tsx` — email/password + Zod validation + React Hook Form
- [x] **P1-6** — Build `RegisterForm.tsx` — separate flows for Donor vs NGO registration
- [x] **P1-7** — Build `ForgotPasswordForm.tsx` — POST `/api/password-reset/request`
- [x] **P1-8** — Build `ResetPasswordForm.tsx` — POST `/api/password-reset/reset` with token from URL
- [x] **P1-9** — Build `/verify-email/page.tsx` — handle POST `/api/v1/auth/verify-email` with token
- [x] **P1-10** — Build `VerifyEmailBanner.tsx` — shown on dashboard if email not verified
- [x] **P1-11** — Implement silent token refresh in Axios interceptor (POST `/api/auth/refresh`)
- [x] **P1-12** — Route guards in `(donor)/layout.tsx`, `(ngo)/layout.tsx`, `(admin)/layout.tsx`
- [x] **P1-13** — Build `/profile/page.tsx` — GET/PUT `/api/auth/profile` + profile image upload
- [x] **P1-14** — Build change password form — PUT `/api/auth/change-password`
- [x] **P1-15** — Build NGO details update form — PUT `/api/auth/ngo-details`

---

## Phase 2 — App Shell & Navigation

**Goal**: Sidebar, topbar, mobile navigation, and theme system.  
**Estimated Time**: 2–3 days

- [x] **P2-1** — Build `Sidebar.tsx` — role-aware nav links, collapsible, active state
- [x] **P2-2** — Build `Topbar.tsx` — breadcrumb, notification bell, user avatar dropdown
- [x] **P2-3** — Build `MobileSidebar.tsx` — Sheet-based drawer for mobile
- [x] **P2-4** — Build `DashboardLayout.tsx` — compose Sidebar + Topbar + main content area
- [ ] **P2-5** — Create `ThemeProvider.tsx` — light/dark toggle with system preference detection
- [x] **P2-6** — Build `PageHeader.tsx` — reusable page title + action button slot
- [ ] **P2-7** — Build `GlobalSearch.tsx` — ShadCN Command palette with Cmd+K shortcut
- [x] **P2-8** — Build `NotificationBell.tsx` + `NotificationDropdown.tsx` in topbar
- [ ] **P2-9** — Build `PublicLayout.tsx` — public navbar + footer for landing/browse pages

---

## Phase 3 — Shared/Common Components

**Goal**: Build the full reusable component library before building features.  
**Estimated Time**: 2–3 days

- [ ] **P3-1** — `DataTable.tsx` — TanStack Table wrapper with sorting, pagination, toolbar
- [ ] **P3-2** — `DataTablePagination.tsx` — page size selector + prev/next controls
- [x] **P3-3** — `EmptyState.tsx` — icon + title + description + optional CTA
- [x] **P3-4** — `LoadingSpinner.tsx` + page-level skeleton screens
- [x] **P3-5** — `ConfirmDialog.tsx` — AlertDialog wrapper for destructive action confirmation
- [x] **P3-6** — `StatusBadge.tsx` — color-coded badge for donation/delivery/verification status
- [ ] **P3-7** — `UserAvatar.tsx` — with fallback initials, size variants
- [ ] **P3-8** — `FileUpload.tsx` — react-dropzone wrapper with preview grid
- [ ] **P3-9** — `ImageCropper.tsx` — react-easy-crop wrapper for profile image
- [ ] **P3-10** — `RichTextEditor.tsx` — TipTap wrapper (used in NGO profile descriptions)
- [ ] **P3-11** — `ErrorBoundary.tsx` — class component fallback UI
- [ ] **P3-12** — Install and configure all needed ShadCN components (Button, Input, Dialog, etc.)

---

## Phase 4 — Donations Module (Donor)

**Goal**: Full donation lifecycle management for donors.  
**Estimated Time**: 4–5 days

### Services & Queries

- [x] **P4-1** — Create `donations.service.ts` (all `/api/donations/*` calls)
- [x] **P4-2** — Create `useDonationQueries.ts` (useDonations, useDonation, useCreateDonation, useUpdateDonation, useDeleteDonation, useInfiniteDonations)

### Components

- [x] **P4-3** — Build `DonationCard.tsx` — image, title, category badge, status, location, CTA
- [x] **P4-4** — Build `DonationGrid.tsx` — responsive grid with loading skeletons
- [x] **P4-5** — Build `DonationFilters.tsx` — category, status, city, radius, date range (URL-synced via `nuqs`)
- [x] **P4-6** — Build `DonationStatusBadge.tsx` — maps all possible statuses to colors
- [x] **P4-7** — Build `DonationTimeline.tsx` — vertical stepper for GET `/api/donations/{id}/timeline`
- [x] **P4-8** — Build `DonationForm.tsx` — multi-step form (details → location → images → review)
- [ ] **P4-9** — Build `NearbyDonationsMap.tsx` — Leaflet map with clustered donation pins

### Pages

- [x] **P4-10** — `/donations/page.tsx` — browse with filters + infinite scroll
- [x] **P4-11** — `/donations/new/page.tsx` — multi-step donation creation form
- [x] **P4-12** — `/donations/[id]/page.tsx` — full detail view, edit/delete actions for owner
- [x] **P4-13** — `/donations/[id]/timeline/page.tsx` — status history
- [x] **P4-14** — `/donations/my/page.tsx` (or `/dashboard`) — donor's own donations list
- [x] **P4-15** — Implement donation stats cards on donor dashboard (GET `/api/donations/stats/summary`)

---

## Phase 5 — NGO Requests Module (Donor)

**Goal**: Donor can view and respond to NGO donation requests.  
**Estimated Time**: 1–2 days

- [ ] **P5-1** — Add request service calls to `ngo.service.ts` (GET `/api/ngos/requests/list`, PUT `.../status`)
- [ ] **P5-2** — Build `NGORequestCard.tsx` — request detail with approve/reject actions
- [ ] **P5-3** — `/requests/page.tsx` — donor's incoming NGO requests with approve/reject actions
- [ ] **P5-4** — Confirmation dialog before approve/reject

---

## Phase 6 — NGO Portal

**Goal**: NGO-facing dashboards, donation claiming, and request creation.  
**Estimated Time**: 3–4 days

- [ ] **P6-11** — NGO requests management page

---

## Phase 7 — Verification Module (NGO + Admin)

**Goal**: NGO submits verification docs; Admin reviews and approves/rejects.  
**Estimated Time**: 3–4 days

- [ ] **P7-1** — Create `verification.service.ts` (all `/api/v1/verification/*`)
- [ ] **P7-2** — Create `useVerificationQueries.ts`
- [ ] **P7-3** — Build `NGOVerificationStatus.tsx` — status card shown on NGO dashboard
- [ ] **P7-4** — Build `NGOVerificationForm.tsx` — Darpan ID, 80G PAN, supporting docs upload
- [ ] **P7-5** — `/verification/page.tsx` — NGO verification status + form (if pending/unverified)
- [ ] **P7-6** — Build `VerificationReviewPanel.tsx` — admin view of all docs + approve/reject/bypass
- [ ] **P7-7** — Admin `/verifications/page.tsx` — pending verifications table
- [ ] **P7-8** — Admin `/verifications/[id]/page.tsx` — full review with document viewer
- [ ] **P7-9** — Build `FraudAlertCard.tsx` for admin fraud-alerts page
- [ ] **P7-10** — Admin `/fraud-alerts/page.tsx`
- [ ] **P7-11** — NGO support request form + support inbox (admin side)

---

## Phase 8 — Delivery & GPS Tracking Module

**Goal**: Full delivery lifecycle with live GPS, QR, photo, signature.  
**Estimated Time**: 4–5 days

### Services & Queries

- [ ] **P8-1** — Create `delivery.service.ts` (all `/api/v1/delivery/*`)
- [ ] **P8-2** — Create `useDeliveryQueries.ts`

### Components

- [ ] **P8-3** — Set up React Leaflet with dynamic import (SSR disabled)
- [ ] **P8-4** — Build `LiveTrackingMap.tsx` — real-time marker + polyline trail from WebSocket
- [ ] **P8-5** — Build `DeliveryStatusStepper.tsx` — visual stepper: Initialized → Picked Up → In Transit → Delivered → Confirmed
- [ ] **P8-6** — Build `QRScanner.tsx` — camera-based QR code scanner (for NGO mobile web)
- [ ] **P8-7** — Build `SignaturePad.tsx` — react-signature-canvas wrapper
- [ ] **P8-8** — Build `PhotoCapture.tsx` — camera or file upload for proof photos
- [ ] **P8-9** — Build `LocationPicker.tsx` — click-on-map + Nominatim reverse geocoding

### Pages

- [ ] **P8-10** — `/deliveries/page.tsx` — NGO's active deliveries list
- [ ] **P8-11** — `/deliveries/[id]/page.tsx` — full delivery detail with status stepper
- [ ] **P8-12** — `/deliveries/[id]/track/page.tsx` — NGO GPS update + pickup/deliver actions
- [ ] **P8-13** — `/donations/[id]/track/page.tsx` — Donor-facing live tracking view
- [ ] **P8-14** — Integrate WebSocket for real-time location pushes from `delivery.store.ts`
- [ ] **P8-15** — Donor "Confirm Delivery" action — POST `/api/v1/delivery/{id}/confirm`

---

## Phase 9 — Chat Module

**Goal**: Real-time messaging between donors and NGOs.  
**Estimated Time**: 3 days

- [ ] **P9-1** — Create `chat.service.ts` (all `/api/v1/chat/*`)
- [ ] **P9-2** — Create `useChatQueries.ts`
- [ ] **P9-3** — Set up `SocketProvider.tsx` with Socket.IO client + auth token
- [ ] **P9-4** — Implement `useSocket.ts` hook for event subscription
- [ ] **P9-5** — Build `ConversationList.tsx` — grouped by user, with unread count badges
- [ ] **P9-6** — Build `ChatWindow.tsx` — scrollable message list with auto-scroll to bottom
- [ ] **P9-7** — Build `ChatMessage.tsx` — sent/received bubble, timestamp, read receipt
- [ ] **P9-8** — Build `ChatInput.tsx` — textarea with send button + Enter to send
- [ ] **P9-9** — `/chat/page.tsx` — conversations list page
- [ ] **P9-10** — `/chat/[userId]/page.tsx` — active chat window
- [ ] **P9-11** — Update `chat.store.ts` with incoming messages from WebSocket
- [ ] **P9-12** — Mark messages as read on chat open — PUT `/api/v1/chat/read/{recipientId}`

---

## Phase 10 — Reviews Module

**Goal**: Donors can rate and review NGOs; NGOs can respond.  
**Estimated Time**: 1–2 days

- [ ] **P10-1** — Create `reviews.service.ts` (POST review, GET by NGO, PUT update, DELETE, NGO respond)
- [ ] **P10-2** — Create `useReviewQueries.ts`
- [ ] **P10-3** — Build `ReviewCard.tsx` — star rating, text, date, NGO response (if any)
- [ ] **P10-4** — Build `WriteReviewForm.tsx` — star picker + textarea + submit
- [ ] **P10-5** — Integrate reviews section into NGO public profile `/ngos/[id]/page.tsx`
- [ ] **P10-6** — NGO `/reviews/page.tsx` — NGO's received reviews + respond action

---

## Phase 11 — Notifications Module

**Goal**: Real-time and persistent notifications for all users.  
**Estimated Time**: 1–2 days

- [ ] **P11-1** — Create `notifications.service.ts`
- [ ] **P11-2** — Create `useNotificationQueries.ts`
- [ ] **P11-3** — Build `NotificationItem.tsx` — icon, message, time, read/unread state
- [ ] **P11-4** — `NotificationBell.tsx` — badge count from Zustand `notification.store`
- [ ] **P11-5** — `NotificationDropdown.tsx` — latest 10 notifications with "mark all read"
- [ ] **P11-6** — `/notifications/page.tsx` — full paginated list with individual mark-read + delete
- [ ] **P11-7** — Wire WebSocket "notification:new" → Zustand store + Sonner toast

---

## Phase 12 — Dashboard & Analytics

**Goal**: Role-specific dashboards with stats, charts, and activity feeds.  
**Estimated Time**: 2–3 days

- [ ] **P12-1** — Create `dashboard.service.ts` + `useDashboardQueries.ts`
- [ ] **P12-2** — Build `StatsCard.tsx` — animated number, icon, trend indicator
- [ ] **P12-3** — Build `DonationChart.tsx` — monthly area chart with Recharts
- [ ] **P12-4** — Build `CategoryBreakdownChart.tsx` — donut chart
- [ ] **P12-5** — Build `ActivityFeed.tsx` — chronological activity list
- [ ] **P12-6** — Build `LeaderboardTable.tsx` — top donors table with rank + avatar
- [ ] **P12-7** — Build `QuickActions.tsx` — role-specific shortcut buttons
- [x] **P12-8** — Donor `/dashboard/page.tsx` — assemble all donor widgets
- [x] **P12-9** — NGO `/dashboard/page.tsx` — assemble all NGO widgets
- [ ] **P12-10** — `/leaderboard/page.tsx` — full leaderboard (GET `/api/auth/leaderboard`)

---

## Phase 13 — Search Module

**Goal**: Full-text search and advanced filtering across donations and NGOs.  
**Estimated Time**: 1–2 days

- [ ] **P13-1** — Create `search.service.ts` (GET `/api/search/donations`, `/ngos`, `/categories`)
- [ ] **P13-2** — Create `useSearchQueries.ts`
- [ ] **P13-3** — Build `GlobalSearch.tsx` — Command palette (Cmd+K) with debounced search
- [ ] **P13-4** — Build `SearchFilters.tsx` — sidebar filter panel, URL-synced via `nuqs`
- [ ] **P13-5** — Build `SearchResults.tsx` — unified results with tabs (Donations / NGOs)
- [ ] **P13-6** — Wire category browse from `GET /api/search/categories` into donation filters

---

## Phase 14 — Audit Module

**Goal**: Activity log and audit trail for users and donations.  
**Estimated Time**: 1 day

- [ ] **P14-1** — Create `audit.service.ts` (all `/api/v1/audit/*`)
- [ ] **P14-2** — Create `useAuditQueries.ts`
- [ ] **P14-3** — Build `AuditLogTable.tsx` — action, resource, timestamp, IP
- [ ] **P14-4** — Donor `/audit/page.tsx` — user's own activity log
- [ ] **P14-5** — Admin `/audit/[userId]/page.tsx` — full user audit trail

---

## Phase 15 — Admin Panel

**Goal**: Complete admin portal for platform management.  
**Estimated Time**: 4–5 days

- [ ] **P15-1** — Create `admin.service.ts` (all `/api/admin/*`)
- [ ] **P15-2** — Create `useAdminQueries.ts`
- [x] **P15-3** — Admin `/dashboard/page.tsx` — platform stats (GET `/api/admin/stats`) + charts
- [ ] **P15-4** — `PlatformStatsGrid.tsx` — total users, donations, NGOs, deliveries
- [ ] **P15-5** — `UserTable.tsx` — all users with filter, activate/deactivate, delete actions
- [ ] **P15-6** — Admin `/users/page.tsx`
- [ ] **P15-7** — Admin `/users/[id]/page.tsx` — full user profile + audit trail
- [ ] **P15-8** — Admin `/ngos/pending/page.tsx` — pending NGO verifications
- [ ] **P15-9** — Admin NGO approval UI with document viewer
- [ ] **P15-10** — Wire all verification admin actions (approve, reject, bypass, rerun-api)
- [ ] **P15-11** — Admin `/support/page.tsx` — all support tickets table
- [ ] **P15-12** — Admin `/support/[id]/page.tsx` — reply to support ticket
- [ ] **P15-13** — Admin `/donations/page.tsx` — all platform donations table
- [ ] **P15-14** — Admin `/stats/page.tsx` — detailed analytics charts

---

## Phase 16 — Public Pages

**Goal**: Landing page and public browsing (no auth required).  
**Estimated Time**: 2–3 days

- [ ] **P16-1** — Landing `page.tsx` — hero, stats, how it works, featured donations, CTA
- [ ] **P16-2** — Public `/donations/page.tsx` — browsable donation listing (limited info)
- [ ] **P16-3** — Public `/donations/[id]/page.tsx` — donation detail for public
- [ ] **P16-4** — Public `/ngos/page.tsx` — NGO directory
- [ ] **P16-5** — Public `/ngos/[id]/page.tsx` — NGO public profile with reviews
- [ ] **P16-6** — `about/page.tsx` — about the platform
- [ ] **P16-7** — SEO: add `next-seo` meta tags to all public pages
- [ ] **P16-8** — Configure ISR (`revalidate: 60`) for public donation/NGO pages

---

## Phase 17 — Polish & Production Readiness

**Goal**: Performance, error handling, accessibility, and final QA.  
**Estimated Time**: 3–4 days

- [ ] **P17-1** — Add `loading.tsx` and `error.tsx` for all major route segments
- [ ] **P17-2** — Add skeleton screens to all data-loading states
- [ ] **P17-3** — Audit and fix all empty states (EmptyState component)
- [ ] **P17-4** — Implement `ErrorBoundary` wrapping around all feature sections
- [ ] **P17-5** — Run `@next/bundle-analyzer` and optimise heavy chunks
- [ ] **P17-6** — Lazy load all heavy components (maps, charts, editors)
- [ ] **P17-7** — Accessibility audit — keyboard navigation, ARIA labels, focus rings
- [ ] **P17-8** — Mobile responsiveness pass on all pages
- [ ] **P17-9** — Add Framer Motion transitions to page navigation and key interactions
- [ ] **P17-10** — Dark mode testing and fixes
- [ ] **P17-11** — Add PWA manifest (`public/manifest.json`) and service worker (optional)
- [ ] **P17-12** — Final Playwright E2E test suite run
- [ ] **P17-13** — Set up Vercel deployment with environment variables
- [ ] **P17-14** — Configure `vercel.json` for headers, rewrites if needed
- [ ] **P17-15** — Add error monitoring (Sentry) — optional but recommended

---

## Phase 18 — Testing

**Goal**: Unit, integration, and E2E test coverage.  
**Estimated Time**: Ongoing (parallel with development)

- [ ] **P18-1** — Set up Vitest + React Testing Library config
- [ ] **P18-2** — Unit tests: `usePermission`, `cn`, `formatters`, `validators`
- [ ] **P18-3** — Component tests: `DonationCard`, `DonationForm`, `StatusBadge`, `DataTable`
- [ ] **P18-4** — Service tests: mock Axios, test `donations.service`, `auth.service`
- [ ] **P18-5** — Set up Playwright with staging base URL
- [ ] **P18-6** — E2E: Donor registration → create donation → receive NGO request → approve
- [ ] **P18-7** — E2E: NGO login → browse donations → claim → initialize delivery → deliver
- [ ] **P18-8** — E2E: Admin login → verify NGO → resolve fraud alert

---

## Task Summary by Phase

| Phase     | Area                   | Tasks          | Est. Days       |
| --------- | ---------------------- | -------------- | --------------- |
| 0         | Setup & Infrastructure | 15             | 2–3             |
| 1         | Authentication         | 15             | 3–4             |
| 2         | App Shell & Navigation | 9              | 2–3             |
| 3         | Shared Components      | 12             | 2–3             |
| 4         | Donations (Donor)      | 15             | 4–5             |
| 5         | NGO Requests (Donor)   | 4              | 1–2             |
| 6         | NGO Portal             | 11             | 3–4             |
| 7         | Verification Module    | 11             | 3–4             |
| 8         | Delivery & GPS         | 15             | 4–5             |
| 9         | Chat                   | 12             | 3               |
| 10        | Reviews                | 6              | 1–2             |
| 11        | Notifications          | 7              | 1–2             |
| 12        | Dashboard & Analytics  | 10             | 2–3             |
| 13        | Search                 | 6              | 1–2             |
| 14        | Audit                  | 5              | 1               |
| 15        | Admin Panel            | 14             | 4–5             |
| 16        | Public Pages           | 8              | 2–3             |
| 17        | Polish & Production    | 15             | 3–4             |
| 18        | Testing                | 8              | Parallel        |
| **Total** |                        | **~198 tasks** | **~45–55 days** |

---

## Priority Order for MVP

If you need to ship an MVP first, do phases in this order:

```
P0 → P1 → P2 → P3 → P4 → P6 → P8 (core) → P9 → P11 → P15 (core) → P16
```

Then add: P7 (verification), P12 (dashboards), P5, P10, P13, P14, then full P17/P18.
