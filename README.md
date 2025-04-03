# DAANSETU - Connect Donors with NGOs

DAANSETU is a modern web platform designed to efficiently connect donors with NGOs, ensuring real-time tracking, transparency, and accountability in the donation process.

## Features

- **Authentication & Role-based Access**: Secure login system with different permissions for donors, NGOs, and administrators.
- **Donor Dashboard**: List and manage donations of various items (food, clothes, books, etc.).
- **NGO Dashboard**: Browse, claim, and distribute donations based on real-time needs.
- **Real-time Tracking**: Monitor donations from listing to delivery with complete transparency.
- **Admin Panel**: Verify NGOs, manage users, and oversee donation processes.
- **Push Notifications**: Get alerts for important events via Firebase Cloud Messaging.
- **Location-based Features**: Find nearby donations and NGOs using Google Maps integration.
- **Dark Mode & Responsive Design**: Beautiful UI that works on all devices.

## Tech Stack

- **Frontend**: Next.js (React framework)
- **Styling**: Tailwind CSS, Framer Motion (for animations)
- **Backend & Database**: Firebase (Firestore, Auth, Cloud Functions, FCM)
- **API Integration**: Google Maps API, Email Notifications
- **Hosting & Deployment**: Vercel / Firebase Hosting

## Getting Started

### Prerequisites

- Node.js (v18 or higher)
- npm or yarn
- Firebase account

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/daansetu-portal.git
   cd daansetu-portal
   ```

2. Install dependencies:
   ```bash
   npm install
   # or
   yarn
   ```

3. Set up environment variables:
   Create a `.env.local` file in the root directory with the following variables:
   ```
   NEXT_PUBLIC_FIREBASE_API_KEY=your_api_key
   NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_auth_domain
   NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
   NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your_storage_bucket
   NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
   NEXT_PUBLIC_FIREBASE_APP_ID=your_app_id
   NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID=your_measurement_id
   NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=your_google_maps_api_key
   ```

4. Run the development server:
   ```bash
   npm run dev
   # or
   yarn dev
   ```

5. Open [http://localhost:3000](http://localhost:3000) in your browser to see the application.

## Contributing

We welcome contributions to DAANSETU! Please read our contributing guidelines before submitting a pull request.

## License

This project is licensed under the MIT License.

## Contact

For any questions or suggestions, please reach out to us at info@daansetu.org.

## Troubleshooting

### Firebase Permissions Error

If you encounter the `FirebaseError: Missing or insufficient permissions.` error, follow these steps:

1. Make sure you've authenticated properly in the application
2. Check that your Firebase project has the following configurations:

   - Firestore database is created and enabled
   - Authentication providers (Email/Password and Google) are enabled
   - Security rules are deployed correctly

3. Deploy the security rules using Firebase CLI:

   ```bash
   firebase deploy --only firestore:rules
   ```

4. Ensure your user account has the correct role (donor, ngo, or admin)

5. For development purposes, you can seed the database with test data by clicking the "Seed Test Data" button on the dashboard (only visible in development mode)

### Development Data

For testing purposes, you can use the "Seed Database" functionality available in the dashboard for admin users or in development mode. This will create:

- Sample donations with various categories and statuses
- Sample NGO requests 
- Test data that you can interact with
