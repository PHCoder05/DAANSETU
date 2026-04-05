# Daansetu Web App — Frontend Architecture

> **Platform**: Donation & NGO Management Platform  
> **Stack**: Next.js 14 (App Router) + TypeScript + TailwindCSS + ShadCN UI  
> **Target**: Enterprise-grade, scalable, production-ready  
> **Roles**: Donor · NGO · Admin

---

## Table of Contents

1. [Tech Stack & Rationale](#1-tech-stack--rationale)
2. [Project Folder Structure](#2-project-folder-structure)
3. [Routing Architecture](#3-routing-architecture)
4. [State Management](#4-state-management)
5. [API Layer & Data Fetching](#5-api-layer--data-fetching)
6. [Authentication & Session](#6-authentication--session)
7. [Role-Based Access Control (RBAC)](#7-role-based-access-control-rbac)
8. [UI Library & Design System](#8-ui-library--design-system)
9. [Forms & Validation](#9-forms--validation)
10. [Real-Time (WebSocket & SSE)](#10-real-time-websocket--sse)
11. [Maps & GPS Tracking](#11-maps--gps-tracking)
12. [File Uploads](#12-file-uploads)
13. [Notifications](#13-notifications)
14. [Search & Filtering](#14-search--filtering)
15. [Charts & Analytics](#15-charts--analytics)
16. [Error Handling](#16-error-handling)
17. [Performance Strategy](#17-performance-strategy)
18. [Testing Strategy](#18-testing-strategy)
19. [Environment & Configuration](#19-environment--configuration)
20. [CI/CD & Deployment](#20-cicd--deployment)

---

## 1. Tech Stack & Rationale

### Core Framework

| Layer | Choice | Reason |
|---|---|---|
| Framework | **Next.js 14 (App Router)** | SSR/SSG/ISR, file-based routing, server components, built-in image optimisation |
| Language | **TypeScript 5.x** | Full type safety, better DX, enterprise standard |
| Styling | **TailwindCSS 3.x** | Utility-first, purge-safe, design tokens, responsive |
| Component Library | **ShadCN UI** | Unstyled-base (Radix primitives), fully customisable, copy-paste ownership |
| Icons | **Lucide React** | Consistent, tree-shakeable, 1000+ icons |

### State & Data

| Layer | Choice | Reason |
|---|---|---|
| Server State | **TanStack Query v5** | Caching, background refetch, optimistic updates, pagination |
| Global Client State | **Zustand v4** | Lightweight, no boilerplate, persist middleware |
| Form State | **React Hook Form v7** | Performance (uncontrolled), integrates cleanly with Zod |
| Validation | **Zod** | Schema-first, shared with API types |

### UI Enhancements

| Purpose | Choice |
|---|---|
| Animation | **Framer Motion** |
| Maps | **React Leaflet** + **OpenStreetMap** (free, no API key) |
| Charts | **Recharts** |
| Rich Text | **TipTap** (for NGO profiles/descriptions) |
| Date handling | **date-fns** |
| Toast/Notifications | **Sonner** |
| File upload | **react-dropzone** |
| Table | **TanStack Table v8** |
| Virtual list | **TanStack Virtual** (for large lists) |
| Image crop | **react-easy-crop** |
| QR Code | **qrcode.react** |
| Signature pad | **react-signature-canvas** |

### Utilities

| Purpose | Choice |
|---|---|
| HTTP client | **Axios** with interceptors |
| Classnames | **clsx** + **tailwind-merge** |
| Env validation | **@t3-oss/env-nextjs** |
| SEO | **next-seo** |
| Linting | **ESLint** + **Prettier** + **Husky** + **lint-staged** |
| Commit standards | **Commitizen** + **conventional-commits** |
| Bundle analysis | **@next/bundle-analyzer** |

---

## 2. Project Folder Structure

```
daansetu-web/
│
├── public/
│   ├── icons/                      # PWA icons, favicons
│   ├── images/                     # Static images (logos, illustrations)
│   └── fonts/                      # Self-hosted fonts (if any)
│
├── src/
│   │
│   ├── app/                        # Next.js App Router (pages & layouts)
│   │   │
│   │   ├── (auth)/                 # Route group – unauthenticated
│   │   │   ├── login/
│   │   │   │   └── page.tsx
│   │   │   ├── register/
│   │   │   │   └── page.tsx
│   │   │   ├── forgot-password/
│   │   │   │   └── page.tsx
│   │   │   ├── reset-password/
│   │   │   │   └── page.tsx
│   │   │   ├── verify-email/
│   │   │   │   └── page.tsx
│   │   │   └── layout.tsx          # Auth shell (centered card layout)
│   │   │
│   │   ├── (public)/               # Route group – public pages
│   │   │   ├── page.tsx            # Landing / Home
│   │   │   ├── about/page.tsx
│   │   │   ├── donations/
│   │   │   │   ├── page.tsx        # Browse all donations
│   │   │   │   └── [id]/page.tsx   # Donation detail (public view)
│   │   │   ├── ngos/
│   │   │   │   ├── page.tsx        # Browse NGOs
│   │   │   │   └── [id]/page.tsx   # NGO public profile
│   │   │   └── layout.tsx          # Public layout (navbar + footer)
│   │   │
│   │   ├── (donor)/                # Route group – Donor portal
│   │   │   ├── dashboard/page.tsx
│   │   │   ├── donations/
│   │   │   │   ├── page.tsx        # My donations list
│   │   │   │   ├── new/page.tsx    # Create donation
│   │   │   │   └── [id]/
│   │   │   │       ├── page.tsx    # Donation detail / manage
│   │   │   │       ├── timeline/page.tsx
│   │   │   │       └── track/page.tsx  # GPS tracking view
│   │   │   ├── requests/
│   │   │   │   └── page.tsx        # NGO requests to approve/reject
│   │   │   ├── leaderboard/page.tsx
│   │   │   ├── bookmarks/page.tsx
│   │   │   ├── chat/
│   │   │   │   ├── page.tsx        # Conversations list
│   │   │   │   └── [userId]/page.tsx
│   │   │   ├── notifications/page.tsx
│   │   │   ├── profile/page.tsx
│   │   │   └── layout.tsx          # Donor shell (sidebar + topbar)
│   │   │
│   │   ├── (ngo)/                  # Route group – NGO portal
│   │   │   ├── dashboard/page.tsx
│   │   │   ├── donations/
│   │   │   │   ├── page.tsx        # Available donations to claim
│   │   │   │   └── [id]/page.tsx
│   │   │   ├── deliveries/
│   │   │   │   ├── page.tsx        # Active deliveries
│   │   │   │   └── [donationId]/
│   │   │   │       ├── page.tsx    # Delivery detail
│   │   │   │       └── track/page.tsx
│   │   │   ├── requests/
│   │   │   │   ├── page.tsx        # My requests
│   │   │   │   └── new/page.tsx    # Create request
│   │   │   ├── verification/
│   │   │   │   ├── page.tsx        # Verification status
│   │   │   │   └── apply/page.tsx  # Submit verification docs
│   │   │   ├── chat/
│   │   │   │   ├── page.tsx
│   │   │   │   └── [userId]/page.tsx
│   │   │   ├── reviews/page.tsx
│   │   │   ├── support/page.tsx
│   │   │   ├── notifications/page.tsx
│   │   │   ├── profile/page.tsx
│   │   │   └── layout.tsx          # NGO shell (sidebar + topbar)
│   │   │
│   │   ├── (admin)/                # Route group – Admin panel
│   │   │   ├── dashboard/page.tsx
│   │   │   ├── users/
│   │   │   │   ├── page.tsx        # All users table
│   │   │   │   └── [userId]/page.tsx
│   │   │   ├── ngos/
│   │   │   │   ├── pending/page.tsx
│   │   │   │   └── [id]/page.tsx
│   │   │   ├── verifications/
│   │   │   │   ├── page.tsx        # Pending verifications
│   │   │   │   └── [id]/page.tsx
│   │   │   ├── fraud-alerts/page.tsx
│   │   │   ├── support/
│   │   │   │   ├── page.tsx        # All support requests
│   │   │   │   └── [id]/page.tsx
│   │   │   ├── donations/page.tsx
│   │   │   ├── audit/
│   │   │   │   ├── page.tsx
│   │   │   │   └── [userId]/page.tsx
│   │   │   ├── stats/page.tsx
│   │   │   └── layout.tsx          # Admin shell
│   │   │
│   │   ├── api/                    # Next.js API routes (BFF / proxy layer)
│   │   │   └── [...proxy]/route.ts # Optional: thin proxy to backend
│   │   │
│   │   ├── error.tsx               # Global error boundary
│   │   ├── not-found.tsx
│   │   ├── loading.tsx
│   │   └── layout.tsx              # Root layout (providers, fonts, meta)
│   │
│   ├── components/
│   │   │
│   │   ├── ui/                     # ShadCN generated components (DO NOT EDIT)
│   │   │   ├── button.tsx
│   │   │   ├── input.tsx
│   │   │   ├── dialog.tsx
│   │   │   ├── table.tsx
│   │   │   └── ...
│   │   │
│   │   ├── common/                 # App-wide reusable components
│   │   │   ├── AppShell/
│   │   │   │   ├── Sidebar.tsx
│   │   │   │   ├── Topbar.tsx
│   │   │   │   ├── MobileSidebar.tsx
│   │   │   │   └── index.ts
│   │   │   ├── DataTable/
│   │   │   │   ├── DataTable.tsx   # TanStack Table wrapper
│   │   │   │   ├── DataTablePagination.tsx
│   │   │   │   ├── DataTableToolbar.tsx
│   │   │   │   └── index.ts
│   │   │   ├── PageHeader/
│   │   │   │   └── PageHeader.tsx
│   │   │   ├── EmptyState/
│   │   │   │   └── EmptyState.tsx
│   │   │   ├── LoadingSpinner/
│   │   │   │   └── LoadingSpinner.tsx
│   │   │   ├── ErrorBoundary/
│   │   │   │   └── ErrorBoundary.tsx
│   │   │   ├── ConfirmDialog/
│   │   │   │   └── ConfirmDialog.tsx
│   │   │   ├── FileUpload/
│   │   │   │   ├── FileUpload.tsx
│   │   │   │   └── ImageCropper.tsx
│   │   │   ├── Map/
│   │   │   │   ├── DonationMap.tsx
│   │   │   │   ├── DeliveryTracker.tsx
│   │   │   │   └── LocationPicker.tsx
│   │   │   ├── Avatar/
│   │   │   │   └── UserAvatar.tsx
│   │   │   ├── Badge/
│   │   │   │   └── StatusBadge.tsx
│   │   │   └── RichTextEditor/
│   │   │       └── RichTextEditor.tsx
│   │   │
│   │   ├── features/               # Feature-specific components
│   │   │   │
│   │   │   ├── auth/
│   │   │   │   ├── LoginForm.tsx
│   │   │   │   ├── RegisterForm.tsx
│   │   │   │   ├── ForgotPasswordForm.tsx
│   │   │   │   └── VerifyEmailBanner.tsx
│   │   │   │
│   │   │   ├── donations/
│   │   │   │   ├── DonationCard.tsx
│   │   │   │   ├── DonationGrid.tsx
│   │   │   │   ├── DonationForm.tsx
│   │   │   │   ├── DonationTimeline.tsx
│   │   │   │   ├── DonationStatusBadge.tsx
│   │   │   │   ├── DonationFilters.tsx
│   │   │   │   ├── NearbyDonationsMap.tsx
│   │   │   │   └── ClaimDonationModal.tsx
│   │   │   │
│   │   │   ├── delivery/
│   │   │   │   ├── DeliveryCard.tsx
│   │   │   │   ├── DeliveryStatusStepper.tsx
│   │   │   │   ├── LiveTrackingMap.tsx
│   │   │   │   ├── QRScanner.tsx
│   │   │   │   ├── SignaturePad.tsx
│   │   │   │   └── PhotoCapture.tsx
│   │   │   │
│   │   │   ├── chat/
│   │   │   │   ├── ChatWindow.tsx
│   │   │   │   ├── ChatMessage.tsx
│   │   │   │   ├── ConversationList.tsx
│   │   │   │   └── ChatInput.tsx
│   │   │   │
│   │   │   ├── ngo/
│   │   │   │   ├── NGOCard.tsx
│   │   │   │   ├── NGOProfileHeader.tsx
│   │   │   │   ├── NGOVerificationStatus.tsx
│   │   │   │   ├── NGOVerificationForm.tsx
│   │   │   │   ├── NGORequestForm.tsx
│   │   │   │   └── ReviewCard.tsx
│   │   │   │
│   │   │   ├── dashboard/
│   │   │   │   ├── StatsCard.tsx
│   │   │   │   ├── ActivityFeed.tsx
│   │   │   │   ├── DonationChart.tsx
│   │   │   │   ├── LeaderboardTable.tsx
│   │   │   │   └── QuickActions.tsx
│   │   │   │
│   │   │   ├── notifications/
│   │   │   │   ├── NotificationItem.tsx
│   │   │   │   ├── NotificationDropdown.tsx
│   │   │   │   └── NotificationBell.tsx
│   │   │   │
│   │   │   ├── search/
│   │   │   │   ├── GlobalSearch.tsx
│   │   │   │   ├── SearchFilters.tsx
│   │   │   │   └── SearchResults.tsx
│   │   │   │
│   │   │   └── admin/
│   │   │       ├── UserTable.tsx
│   │   │       ├── VerificationReviewPanel.tsx
│   │   │       ├── FraudAlertCard.tsx
│   │   │       ├── SupportTicketView.tsx
│   │   │       └── PlatformStatsGrid.tsx
│   │   │
│   │   └── layouts/                # Page-level layout components
│   │       ├── PublicLayout.tsx
│   │       ├── AuthLayout.tsx
│   │       ├── DashboardLayout.tsx
│   │       └── AdminLayout.tsx
│   │
│   ├── hooks/                      # Custom React hooks
│   │   ├── useAuth.ts              # Auth state + helpers
│   │   ├── usePermission.ts        # RBAC permission check
│   │   ├── useMediaQuery.ts
│   │   ├── useDebounce.ts
│   │   ├── useInfiniteScroll.ts
│   │   ├── useGeolocation.ts       # Browser GPS
│   │   ├── useSocket.ts            # WebSocket connection
│   │   ├── useNotifications.ts
│   │   ├── useLocalStorage.ts
│   │   └── useClipboard.ts
│   │
│   ├── lib/                        # Pure utilities, configs, helpers
│   │   ├── api/
│   │   │   ├── axios.ts            # Axios instance + interceptors
│   │   │   └── queryClient.ts      # TanStack Query client config
│   │   ├── auth/
│   │   │   ├── session.ts          # Token storage helpers
│   │   │   └── permissions.ts      # Role/permission matrix
│   │   ├── utils/
│   │   │   ├── cn.ts               # clsx + twMerge helper
│   │   │   ├── formatters.ts       # Date, currency, number formatters
│   │   │   ├── validators.ts       # Shared Zod validators
│   │   │   └── mappers.ts          # API response → UI model
│   │   └── constants/
│   │       ├── routes.ts           # All route path constants
│   │       ├── roles.ts            # Role enums
│   │       └── config.ts           # App-wide constants
│   │
│   ├── services/                   # API service functions (per domain)
│   │   ├── auth.service.ts
│   │   ├── donations.service.ts
│   │   ├── delivery.service.ts
│   │   ├── ngo.service.ts
│   │   ├── chat.service.ts
│   │   ├── verification.service.ts
│   │   ├── notifications.service.ts
│   │   ├── reviews.service.ts
│   │   ├── search.service.ts
│   │   ├── dashboard.service.ts
│   │   ├── audit.service.ts
│   │   └── admin.service.ts
│   │
│   ├── store/                      # Zustand global stores
│   │   ├── auth.store.ts           # User, token, role
│   │   ├── ui.store.ts             # Sidebar state, theme, modal stack
│   │   ├── chat.store.ts           # Active chat, unread counts
│   │   ├── notification.store.ts   # Notification list + unread count
│   │   └── delivery.store.ts       # Active delivery GPS state
│   │
│   ├── queries/                    # TanStack Query hooks (per domain)
│   │   ├── useAuthQueries.ts
│   │   ├── useDonationQueries.ts
│   │   ├── useDeliveryQueries.ts
│   │   ├── useNGOQueries.ts
│   │   ├── useChatQueries.ts
│   │   ├── useVerificationQueries.ts
│   │   ├── useNotificationQueries.ts
│   │   ├── useReviewQueries.ts
│   │   ├── useSearchQueries.ts
│   │   ├── useDashboardQueries.ts
│   │   ├── useAuditQueries.ts
│   │   └── useAdminQueries.ts
│   │
│   ├── types/                      # TypeScript type definitions
│   │   ├── api/
│   │   │   ├── auth.types.ts
│   │   │   ├── donation.types.ts
│   │   │   ├── delivery.types.ts
│   │   │   ├── ngo.types.ts
│   │   │   ├── chat.types.ts
│   │   │   ├── notification.types.ts
│   │   │   └── admin.types.ts
│   │   ├── ui/
│   │   │   ├── table.types.ts
│   │   │   └── form.types.ts
│   │   └── index.ts                # Barrel export
│   │
│   ├── styles/
│   │   ├── globals.css             # Tailwind directives + CSS vars
│   │   └── themes/
│   │       ├── light.css
│   │       └── dark.css
│   │
│   └── providers/                  # React context providers
│       ├── AppProviders.tsx        # Wraps all providers in root layout
│       ├── AuthProvider.tsx
│       ├── QueryProvider.tsx
│       ├── ThemeProvider.tsx
│       └── SocketProvider.tsx
│
├── .env.local                      # Local dev env vars
├── .env.example                    # Committed env template
├── next.config.ts
├── tailwind.config.ts
├── tsconfig.json
├── components.json                 # ShadCN config
├── eslint.config.mjs
├── prettier.config.js
├── commitlint.config.js
└── package.json
```

---

## 3. Routing Architecture

### Route Groups Strategy

Next.js App Router route groups `(auth)`, `(public)`, `(donor)`, `(ngo)`, `(admin)` each have their own `layout.tsx`. This means:
- Each portal renders a completely different shell
- No layout bleeding across portals
- Code-split per portal automatically

### Route Guard Pattern

```tsx
// src/app/(donor)/layout.tsx
// Every protected layout does role-gating server-side
import { redirect } from "next/navigation";
import { getServerSession } from "@/lib/auth/session";
import { ROUTES } from "@/lib/constants/routes";

export default async function DonorLayout({ children }) {
  const session = await getServerSession();
  if (!session) redirect(ROUTES.LOGIN);
  if (session.role !== "donor") redirect(ROUTES.UNAUTHORIZED);
  return <DashboardLayout role="donor">{children}</DashboardLayout>;
}
```

### Route Constants

```ts
// src/lib/constants/routes.ts
export const ROUTES = {
  // Public
  HOME: "/",
  BROWSE_DONATIONS: "/donations",
  BROWSE_NGOS: "/ngos",
  // Auth
  LOGIN: "/login",
  REGISTER: "/register",
  // Donor
  DONOR_DASHBOARD: "/dashboard",
  DONOR_DONATIONS: "/donations",
  DONOR_NEW_DONATION: "/donations/new",
  DONOR_DONATION: (id: string) => `/donations/${id}`,
  DONOR_TRACK: (id: string) => `/donations/${id}/track`,
  DONOR_REQUESTS: "/requests",
  DONOR_CHAT: "/chat",
  DONOR_CHAT_USER: (uid: string) => `/chat/${uid}`,
  // NGO
  NGO_DASHBOARD: "/dashboard",
  NGO_DELIVERIES: "/deliveries",
  NGO_VERIFICATION: "/verification",
  // Admin
  ADMIN_DASHBOARD: "/dashboard",
  ADMIN_USERS: "/users",
  ADMIN_VERIFICATIONS: "/verifications",
  ADMIN_FRAUD: "/fraud-alerts",
} as const;
```

---

## 4. State Management

### Two-layer Architecture

```
┌─────────────────────────────────────────────────────┐
│              Server State (TanStack Query)           │
│  All API data: donations, NGOs, users, notifications │
│  Handles: caching, background sync, pagination       │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│              Client State (Zustand)                  │
│  Auth session, UI state, WebSocket messages          │
│  Does NOT store API data — that belongs in Query     │
└─────────────────────────────────────────────────────┘
```

### Auth Store

```ts
// src/store/auth.store.ts
interface AuthState {
  user: User | null;
  accessToken: string | null;
  role: "donor" | "ngo" | "admin" | null;
  isAuthenticated: boolean;
  setSession: (user: User, token: string) => void;
  clearSession: () => void;
}
```

### UI Store

```ts
// src/store/ui.store.ts
interface UIState {
  sidebarOpen: boolean;
  theme: "light" | "dark";
  activeModal: string | null;
  setSidebarOpen: (v: boolean) => void;
  openModal: (id: string) => void;
  closeModal: () => void;
}
```

---

## 5. API Layer & Data Fetching

### Axios Instance

```ts
// src/lib/api/axios.ts
const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  timeout: 30_000,
  headers: { "Content-Type": "application/json" },
});

// Request interceptor: attach token
api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().accessToken;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Response interceptor: handle 401 → refresh token flow
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      await refreshTokenSilently(); // calls POST /api/auth/refresh
    }
    return Promise.reject(error);
  }
);
```

### Service Layer

Each domain has its own service file. Services are plain async functions — no React hooks, just the API call.

```ts
// src/services/donations.service.ts
export const donationsService = {
  getAll: (params?: DonationFilters) =>
    api.get<PaginatedResponse<Donation>>("/api/donations", { params }),

  getById: (id: string) =>
    api.get<Donation>(`/api/donations/${id}`),

  create: (data: CreateDonationDto) =>
    api.post<Donation>("/api/donations", data),

  update: (id: string, data: UpdateDonationDto) =>
    api.put<Donation>(`/api/donations/${id}`, data),

  delete: (id: string) =>
    api.delete(`/api/donations/${id}`),

  claim: (id: string) =>
    api.post(`/api/donations/${id}/claim`),

  updateStatus: (id: string, status: DonationStatus) =>
    api.put(`/api/donations/${id}/status`, { status }),

  getTimeline: (id: string) =>
    api.get(`/api/donations/${id}/timeline`),

  getNearby: (lat: number, lng: number, radius: number) =>
    api.get("/api/donations/nearby", { params: { lat, lng, radius } }),

  getMy: () =>
    api.get<Donation[]>("/api/donations/my"),

  getStats: () =>
    api.get("/api/donations/stats/summary"),
};
```

### TanStack Query Hooks

```ts
// src/queries/useDonationQueries.ts
export const useDonations = (filters?: DonationFilters) =>
  useQuery({
    queryKey: ["donations", filters],
    queryFn: () => donationsService.getAll(filters).then(r => r.data),
    staleTime: 1000 * 60 * 2, // 2 minutes
  });

export const useDonation = (id: string) =>
  useQuery({
    queryKey: ["donations", id],
    queryFn: () => donationsService.getById(id).then(r => r.data),
    enabled: !!id,
  });

export const useCreateDonation = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: donationsService.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["donations"] });
      toast.success("Donation created successfully!");
    },
  });
};

export const useInfiniteDonations = (filters?: DonationFilters) =>
  useInfiniteQuery({
    queryKey: ["donations", "infinite", filters],
    queryFn: ({ pageParam = 1 }) =>
      donationsService.getAll({ ...filters, page: pageParam }).then(r => r.data),
    getNextPageParam: (last) => last.hasNextPage ? last.page + 1 : undefined,
    initialPageParam: 1,
  });
```

---

## 6. Authentication & Session

### Token Storage Strategy

- **Access token**: Stored in Zustand (in-memory) — never in localStorage for XSS safety
- **Refresh token**: `HttpOnly` cookie (handled by backend's `/api/auth/refresh`)
- On page reload: call `/api/auth/profile` with cookie → re-hydrate Zustand

### Auth Flow

```
App Load
  └── AppProviders.tsx
        └── AuthProvider.tsx
              ├── calls GET /api/auth/profile (cookie-based)
              ├── Success → setSession(user, token)
              └── Failure → clearSession() → redirect to /login (if protected)
```

### Refresh Token Interceptor

The Axios interceptor silently refreshes the token on 401 and replays the failed request. This is transparent to the user.

---

## 7. Role-Based Access Control (RBAC)

### Permission Matrix

```ts
// src/lib/auth/permissions.ts
export const PERMISSIONS = {
  donor: {
    canCreateDonation: true,
    canClaimDonation: false,
    canApproveRequest: true,
    canViewAdminPanel: false,
    canVerifyNGO: false,
  },
  ngo: {
    canCreateDonation: false,
    canClaimDonation: true,
    canApproveRequest: false,
    canViewAdminPanel: false,
    canVerifyNGO: false,
  },
  admin: {
    canCreateDonation: false,
    canClaimDonation: false,
    canApproveRequest: false,
    canViewAdminPanel: true,
    canVerifyNGO: true,
  },
} as const;

export type Role = keyof typeof PERMISSIONS;
export type Permission = keyof typeof PERMISSIONS.donor;
```

### usePermission Hook

```ts
// src/hooks/usePermission.ts
export const usePermission = (permission: Permission): boolean => {
  const role = useAuthStore((s) => s.role);
  if (!role) return false;
  return PERMISSIONS[role][permission] ?? false;
};
```

### Usage in Components

```tsx
const canClaim = usePermission("canClaimDonation");

return (
  <>
    {canClaim && (
      <Button onClick={handleClaim}>Claim Donation</Button>
    )}
  </>
);
```

---

## 8. UI Library & Design System

### ShadCN UI — Component Baseline

ShadCN provides unstyled Radix-based components. All customisation is done through Tailwind variants.

**Components to install:**
- Button, Input, Textarea, Select, Checkbox, RadioGroup, Switch
- Dialog, Sheet, Drawer, AlertDialog, Popover, Tooltip
- Card, Separator, Badge, Avatar, Skeleton
- Table, Pagination
- Form (integrates React Hook Form)
- Tabs, Accordion
- DropdownMenu, NavigationMenu, ContextMenu
- Progress, Slider
- Calendar, DatePicker (via shadcn + react-day-picker)
- Command (for Global Search with Cmd+K)
- Sonner (Toast)

### Design Token System

```css
/* src/styles/globals.css */
:root {
  --background: 0 0% 100%;
  --foreground: 222.2 84% 4.9%;
  --primary: 221.2 83.2% 53.3%;       /* Daansetu brand blue */
  --primary-foreground: 210 40% 98%;
  --secondary: 210 40% 96.1%;
  --success: 142.1 76.2% 36.3%;       /* Donation status: completed */
  --warning: 47.9 95.8% 53.1%;        /* Pending */
  --destructive: 0 72.2% 50.6%;       /* Cancelled/Rejected */
  --muted: 210 40% 96.1%;
  --muted-foreground: 215.4 16.3% 46.9%;
  --border: 214.3 31.8% 91.4%;
  --radius: 0.5rem;
}
```

### Status Color System

Donation statuses across the entire app use consistent colour semantics:

| Status | Colour Token | Tailwind Class |
|---|---|---|
| available | `success` | `bg-green-100 text-green-800` |
| pending | `warning` | `bg-yellow-100 text-yellow-800` |
| claimed | `primary` | `bg-blue-100 text-blue-800` |
| in_transit | `primary` | `bg-indigo-100 text-indigo-800` |
| delivered | `success` | `bg-emerald-100 text-emerald-800` |
| cancelled | `destructive` | `bg-red-100 text-red-800` |

---

## 9. Forms & Validation

### Stack: React Hook Form + Zod + ShadCN Form

```ts
// src/types/api/donation.types.ts (Zod schema doubles as TS type)
export const CreateDonationSchema = z.object({
  title: z.string().min(5, "Title must be at least 5 characters"),
  description: z.string().min(20),
  category: z.enum(["food", "clothes", "books", "medicine", "electronics", "other"]),
  quantity: z.number().positive(),
  unit: z.string(),
  expiryDate: z.date().optional(),
  pickupAddress: z.string().min(10),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  images: z.array(z.string()).max(5),
});
export type CreateDonationDto = z.infer<typeof CreateDonationSchema>;
```

```tsx
// Usage in DonationForm.tsx
const form = useForm<CreateDonationDto>({
  resolver: zodResolver(CreateDonationSchema),
  defaultValues: { category: "food", quantity: 1 },
});

const { mutate, isPending } = useCreateDonation();

const onSubmit = (data: CreateDonationDto) => mutate(data);
```

---

## 10. Real-Time (WebSocket & SSE)

### Chat — WebSocket

The backend likely uses Socket.IO or raw WebSocket for chat. Wrap in a provider:

```tsx
// src/providers/SocketProvider.tsx
const socket = io(process.env.NEXT_PUBLIC_WS_URL, {
  auth: { token: accessToken },
  autoConnect: false,
});

// Events to handle:
// - "message:new"   → update chat store + TanStack Query cache
// - "delivery:location" → update GPS coordinates on map
// - "notification:new" → push to notification store + show toast
```

### Notification Bell — Polling Fallback

If WebSocket is not available, use `refetchInterval`:

```ts
const { data: count } = useQuery({
  queryKey: ["notifications", "unread"],
  queryFn: () => notificationsService.getUnreadCount(),
  refetchInterval: 30_000, // poll every 30s
});
```

---

## 11. Maps & GPS Tracking

### Library: React Leaflet (free, no API key)

```tsx
// src/components/features/delivery/LiveTrackingMap.tsx
import { MapContainer, TileLayer, Marker, Polyline } from "react-leaflet";

// Dynamic import (Leaflet requires browser)
const LiveTrackingMap = dynamic(() => import("./LiveTrackingMap"), {
  ssr: false,
  loading: () => <Skeleton className="h-80 w-full rounded-lg" />,
});
```

**Features to build:**
- `NearbyDonationsMap`: cluster markers for nearby donations (use `react-leaflet-cluster`)
- `LocationPicker`: click-to-pin with reverse geocoding (use Nominatim API — free)
- `LiveTrackingMap`: real-time NGO courier position using WebSocket location updates, polyline trail
- `DeliveryTracker`: donor-side view of delivery progress on map

---

## 12. File Uploads

### Stack: react-dropzone + direct multipart to backend

```tsx
// POST /api/auth/profile/image
// POST /api/donations (images array)
// POST /api/v1/delivery/{id}/pickup (photo + signature)

const onDrop = useCallback(async (acceptedFiles: File[]) => {
  const formData = new FormData();
  acceptedFiles.forEach(file => formData.append("images", file));
  await api.post(`/api/donations/${id}/images`, formData, {
    headers: { "Content-Type": "multipart/form-data" },
  });
}, []);

const { getRootProps, getInputProps, isDragActive } = useDropzone({
  onDrop,
  accept: { "image/*": [".jpg", ".jpeg", ".png", ".webp"] },
  maxFiles: 5,
  maxSize: 5 * 1024 * 1024, // 5MB
});
```

### Signature Pad (Delivery)

```tsx
// src/components/features/delivery/SignaturePad.tsx
import SignatureCanvas from "react-signature-canvas";

// On submit: sigCanvas.current.toDataURL("image/png")
// Send as base64 or convert to Blob
```

---

## 13. Notifications

### Architecture

```
Backend pushes via WebSocket  →  SocketProvider.tsx catches "notification:new"
  → updates Zustand notification.store (unreadCount++)
  → shows Sonner toast
  → TanStack Query cache invalidated for ["notifications"]

NotificationBell (in Topbar) reads unreadCount from Zustand
NotificationDropdown fetches latest 10 via useNotificationQueries
Full /notifications page shows paginated list with mark-read
```

---

## 14. Search & Filtering

### Global Search (Cmd+K)

Use ShadCN's `<Command>` component:
- Opens on `⌘K` / `Ctrl+K`
- Searches donations (`GET /api/search/donations`) and NGOs (`GET /api/search/ngos`)
- Debounced — 300ms delay before API call
- Results grouped: Donations / NGOs / Categories

### Advanced Donation Filters

```
URL: /donations?category=food&status=available&city=Pune&radius=10&q=rice
```

Filters are stored in URL search params (using `nuqs` library) so they are shareable and bookmarkable.

```ts
// Install: pnpm i nuqs
import { useQueryState } from "nuqs";

const [category, setCategory] = useQueryState("category");
const [status, setStatus] = useQueryState("status");
```

---

## 15. Charts & Analytics

### Library: Recharts

Dashboard charts needed:

| Chart | Data Source | Component |
|---|---|---|
| Donations by month (area chart) | `GET /api/dashboard` | `DonationTrendChart` |
| Donation categories (pie/donut) | `GET /api/search/categories` | `CategoryBreakdownChart` |
| Platform stats (stat cards) | `GET /api/admin/stats` | `PlatformStatsGrid` |
| Leaderboard (bar chart) | `GET /api/dashboard/leaderboard` | `LeaderboardChart` |
| Activity heatmap (donor) | `GET /api/dashboard/activity` | `ActivityHeatmap` |

All charts should:
- Render skeletons while loading
- Handle empty states gracefully
- Be responsive (`<ResponsiveContainer width="100%" height={300}>`)

---

## 16. Error Handling

### Hierarchy

```
Global Error Boundary (app/error.tsx)
  └── Query Error Boundary (per page/feature)
        └── Component-level error states (empty/error UI)
```

### Standard API Error Shape

```ts
interface ApiError {
  statusCode: number;
  message: string;
  errors?: Record<string, string[]>; // field-level validation errors
}
```

### Error Handler Utility

```ts
// src/lib/utils/formatters.ts
export const getApiErrorMessage = (error: unknown): string => {
  if (axios.isAxiosError(error)) {
    return error.response?.data?.message ?? "Something went wrong";
  }
  return "An unexpected error occurred";
};
```

---

## 17. Performance Strategy

### Next.js Optimisations

- **Server Components** for data fetching where possible (admin tables, public donation lists)
- **Streaming** with `<Suspense>` boundaries for progressive page rendering
- **Dynamic imports** for heavy components: maps, charts, QR scanner, signature pad
- **`next/image`** for all images — auto WebP, lazy loading, blur placeholder
- **Route prefetching** via `<Link prefetch>` for likely navigation paths
- **ISR** for public pages (NGO profiles, donation detail) — revalidate every 60s

### Code Splitting

```tsx
// Lazy load heavy components
const LiveTrackingMap = dynamic(() => import("@/components/features/delivery/LiveTrackingMap"), { ssr: false });
const RichTextEditor = dynamic(() => import("@/components/common/RichTextEditor"), { ssr: false });
const QRScanner = dynamic(() => import("@/components/features/delivery/QRScanner"), { ssr: false });
```

### TanStack Query Cache Config

```ts
// src/lib/api/queryClient.ts
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 2,      // 2 min
      gcTime: 1000 * 60 * 10,         // 10 min
      retry: 2,
      refetchOnWindowFocus: false,
    },
  },
});
```

---

## 18. Testing Strategy

### Unit & Integration Tests: Vitest + React Testing Library

```
src/
  components/
    features/
      donations/
        DonationCard.test.tsx
        DonationForm.test.tsx
  hooks/
    usePermission.test.ts
  services/
    donations.service.test.ts
```

### E2E Tests: Playwright

```
tests/
  auth/
    login.spec.ts
    register.spec.ts
  donor/
    create-donation.spec.ts
    approve-request.spec.ts
  ngo/
    claim-donation.spec.ts
    delivery-flow.spec.ts
  admin/
    verify-ngo.spec.ts
```

---

## 19. Environment & Configuration

```bash
# .env.example

NEXT_PUBLIC_API_URL=https://api.daansetu.in
NEXT_PUBLIC_WS_URL=wss://api.daansetu.in
NEXT_PUBLIC_APP_URL=https://daansetu.in

# Maps (Leaflet uses OpenStreetMap — no key needed)
# Optionally add Mapbox if premium tiles wanted:
# NEXT_PUBLIC_MAPBOX_TOKEN=

# Optional: Sentry DSN for error monitoring
NEXT_PUBLIC_SENTRY_DSN=
```

### Env Validation at Build Time

```ts
// src/env.ts (using @t3-oss/env-nextjs)
import { createEnv } from "@t3-oss/env-nextjs";
import { z } from "zod";

export const env = createEnv({
  client: {
    NEXT_PUBLIC_API_URL: z.string().url(),
    NEXT_PUBLIC_WS_URL: z.string().url(),
  },
  runtimeEnv: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
    NEXT_PUBLIC_WS_URL: process.env.NEXT_PUBLIC_WS_URL,
  },
});
```

---

## 20. CI/CD & Deployment

### Recommended Deployment: Vercel

- Zero-config Next.js deployment
- Preview deployments per PR
- Edge network CDN
- Environment variable management

### GitHub Actions CI Pipeline

```yaml
# .github/workflows/ci.yml
jobs:
  lint:      # eslint + prettier check
  typecheck: # tsc --noEmit
  test:      # vitest run
  e2e:       # playwright test (on staging env)
  build:     # next build
```

### Branch Strategy

```
main        → Production (auto-deploy to Vercel)
staging     → Staging (auto-deploy preview)
develop     → Integration branch
feature/*   → Feature branches (PR → develop)
fix/*       → Bug fixes
```

---

## Quick Start Commands

```bash
# Scaffold
pnpm create next-app@latest daansetu-web --typescript --tailwind --app --src-dir --import-alias "@/*"
cd daansetu-web

# ShadCN init
pnpm dlx shadcn@latest init

# Core dependencies
pnpm i axios @tanstack/react-query @tanstack/react-table @tanstack/react-virtual zustand
pnpm i react-hook-form @hookform/resolvers zod
pnpm i framer-motion sonner lucide-react clsx tailwind-merge
pnpm i date-fns nuqs

# Feature dependencies  
pnpm i react-leaflet leaflet @react-leaflet/core react-leaflet-cluster
pnpm i recharts
pnpm i react-dropzone react-easy-crop
pnpm i react-signature-canvas qrcode.react
pnpm i @tiptap/react @tiptap/starter-kit
pnpm i socket.io-client

# Dev dependencies
pnpm i -D @types/leaflet vitest @testing-library/react @testing-library/jest-dom
pnpm i -D prettier eslint-config-prettier husky lint-staged commitizen
pnpm i -D @t3-oss/env-nextjs @next/bundle-analyzer
```
