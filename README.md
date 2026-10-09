# 🌿 Plantora 

Plantora is a comprehensive Flutter-based multi-vendor e-commerce platform dedicated to plants, gardening supplies, and related products. It connects buyers, sellers, and drivers in a seamless ecosystem, featuring real-time order tracking, comprehensive seller dashboards, and an integrated Node.js backend.

## ✨ Key Features

### 🛒 For Buyers
- **Explore & Shop**: Browse a wide variety of plants and gardening supplies.
- **Order Tracking**: Real-time order tracking to see exactly when your plants will arrive.
- **Multi-Language Support**: Seamless localization for multiple languages.

### 🏪 For Sellers
- **Seller Dashboard**: Manage inventory, track orders, and view sales metrics.
- **Delivery Management**: Dedicated views to track outgoing deliveries.
- **PDF Invoices**: Automated invoice generation for seamless record-keeping.

### 🚚 For Drivers
- **Active Delivery Tracking**: Manage and update the status of active deliveries.
- **Driver Navigation**: Built-in navigation and routing to reach customers efficiently.

## 🛠️ Technology Stack

- **Frontend**: [Flutter](https://flutter.dev/) & Dart
- **Backend**: Node.js
- **State Management**: Provider (via `localization_provider`)
- **Key Integrations**: Maps/Navigation, PDF Generation

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js](https://nodejs.org/en/download/) (for the backend)
- IDE (VS Code or Android Studio recommended)

### Installation

1. **Clone the repository:**
   ```bash
   git clone <your-repository-url>
   cd PLANTORA
   ```

2. **Install Flutter Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Install Backend Dependencies:**
   ```bash
   cd backend
   npm install
   ```

4. **Run the Application:**
   ```bash
   flutter run
   ```

## 📁 Project Structure

- `lib/screens/` - Contains the UI screens organized by feature/role (e.g., `seller_dashboard_screen`, `driver_navigation_screen`).
- `lib/providers/` - State management providers.
- `lib/services/` - Helper services like `pdf_invoice_service`.
- `lib/models/` - Data models.
- `backend/` - Node.js backend server and product assets.

---
*Made with ❤️ using Flutter*
