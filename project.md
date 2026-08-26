# SaaS Snooker Club

## Overview
SaaS Snooker Club is a comprehensive management and Point-of-Sale (POS) application built for snooker and pool clubs. It enables club owners and staff to efficiently manage tables, track time-based billing, handle inventory and quick sales, manage customer credit accounts, and view detailed financial analytics.

## Tech Stack
- **Framework:** Flutter
- **State Management:** Riverpod (`flutter_riverpod`)
- **Navigation:** GoRouter
- **Backend & Database:** Firebase (Cloud Firestore, Firebase Authentication)
- **Architecture:** Feature-first Clean Architecture

## Core Features

### 1. Dashboard & Analytics
- Real-time financial summaries (Revenue, Outstanding Credit, etc.)
- Quick overview of active/available tables.
- Low-stock inventory alerts.
- Detailed historical and reporting analytics for revenue, games, and quick sales.

### 2. Games & Table Management
- Start, stop, and track time for multiple snooker/pool tables.
- Dynamic billing based on pricing configurations, including overtime and grace periods.
- Add inventory items (snacks, drinks) directly to a running table's tab.
- Comprehensive audit logs and game history.

### 3. Quick Sales (POS)
- Standalone point-of-sale system for walk-in customers buying items without renting a table.
- Support for multiple payment methods (Cash, Card, UPI, Credit).

### 4. Inventory Management
- Track stock levels, prices, and categories for cafe/shop items.
- View detailed stock history (additions, deductions, restorations).

### 5. Credit System (Customer Tabs)
- Manage regular customers and their outstanding credit balances.
- Support for partial payments and transaction history.
- Merge duplicate customer profiles.

### 6. Team & Staff Management
- Role-based access control (Admin vs. Staff).
- Secure operations (e.g., deletions, overrides) guarded by an admin passcode.

### 7. Settings & App Configuration
- Manage club-specific settings like currency, tax rates, and pricing tiers.
- Built-in App Versioning and Force Update capabilities to ensure clients are running the latest version.

## Project Structure
The project follows a feature-driven folder structure inside the `lib/` directory:
- `core/` - Shared widgets, theme, routing, constants, and utilities.
- `features/` - Isolated feature modules, each containing its own `presentation`, `domain`, `data`, and `providers` folders:
  - `analytics/`
  - `authentication/`
  - `calendar/`
  - `credit/`
  - `dashboard/`
  - `games/`
  - `history/`
  - `inventory/`
  - `quick_sales/`
  - `reports/`
  - `settings/`
  - `team/`
  - `updater/`

## Deployment & Environments
The app utilizes an `AppEnvironment` configuration to toggle between `production` and `preview` modes, allowing for safe testing (read-only) without mutating live Firestore data.
