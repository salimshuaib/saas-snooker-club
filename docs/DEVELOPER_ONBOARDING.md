
# Developer Onboarding Guide: SaaS Snooker Club

Welcome to the SaaS Snooker Club codebase! This document is designed to give a new developer or technical expert a comprehensive understanding of how the application is architected, how data flows, and the critical rules to follow when maintaining or expanding the app.

---

## 1. Tech Stack Overview
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (lutter_riverpod)
- **Navigation/Routing**: GoRouter (go_router)
- **Backend/Database**: Firebase Firestore
- **Authentication**: Firebase Auth
- **Over-The-Air Updates**: Shorebird (used for pushing hot patches)

---

## 2. Codebase Architecture (Feature-First)

The repository follows a strict **Feature-First Architecture** inside the lib/ directory.

### Folder Structure
`	ext
lib/
├── core/                   # Shared utilities, constants, themes, routing, global providers
└── features/               # Independent feature modules
    ├── analytics/          # Financial summaries and chart data
    ├── authentication/     # Firebase Auth, Login/Signup UI
    ├── credit/             # Customer ledger, outstanding balances, payment tracking
    ├── dashboard/          # Main navigation shell and overview UI
    ├── games/              # Core game tracking, billing calculation, table management
    ├── inventory/          # Product catalog and stock levels
    ├── quick_sales/        # POS system (drinks, snacks)
    ├── settings/           # Club pricing configuration and system settings
    └── team/               # Staff member management and roles
`

### Inside a Feature
Each feature typically contains:
- domain/: Data models (e.g., GameSession, Table, CreditTransaction).
- data/: Repositories handling Firestore reads/writes (e.g., GamesRepository).
- providers/: Riverpod providers exposing streams, state, or future data.
- presentation/: UI components (screens and widgets).

---

## 3. The Multi-Tenant Architecture (Crucial)

This app is a SaaS product. **One Firebase database serves multiple completely isolated clubs.**

### How Tenant Isolation Works
1. When a user logs in, userClubProvider fetches their profile from the root user_clubs/{userId} collection.
2. This document contains their clubId and 
ole.
3. The clubId is exposed globally via clubIdProvider.
4. **EVERY Repository** watches clubIdProvider and scopes all database operations to clubs/{clubId}/....

**WARNING:** Never write code that accesses Firestore without routing it through a repository that uses clubId. The Firestore Security Rules (irestore.rules) will reject any query that tries to read across clubs unless you are the Super Admin.

---

## 4. State Management & Real-Time Sync

The app is **Offline-First / Real-Time**. We do not use traditional REST APIs. 

### Stream Providers
Instead of fetching data once, repositories return Stream<List<Model>> (using Firestore .snapshots()).
Riverpod StreamProviders listen to these streams. 
- Example: 	ablesProvider listens to table status changes. If Table 1 starts a game on Device A, Device B updates instantly without pulling to refresh.

### Important Riverpod Rule
- **Never trigger side effects during build**: Avoid calling Stream.value([]) synchronously if the users clubId is loading, as it will trigger a setState() called during build exception. Return const Stream.empty() to keep the provider in an AsyncLoading state until the clubId resolves.

---

## 5. Database Schema & Source of Truth

### Root Collections
- user_clubs: User ID -> { clubId, role }
- clubs: Club profile (name, subscription status).
- platform: Global app configurations.

### Club Subcollections (The Meat)
Everything under clubs/{clubId}/:
- 	ables: Physical tables.
- games: Active and historical sessions.
- inventory: Items available for sale.
- quick_sales: POS orders.
- credits: Customer profiles containing their outstanding balance.
  - credits/{customerId}/transactions: Ledger entries for debts incurred.
  - credits/{customerId}/payments: Ledger entries for debts paid.
- udit_logs: Immutable logs of deletions or manual overrides.
- 	eam_members: Staff accounts.
- settings/club_config: Pricing logic, intervals, and billing rules.

---

## 6. Core Business Logic: Games & Billing

The most complex part of the app is the **Games Billing Engine**.

### Game Types
1. **Standard**: Time-based or frame-based. Bills can be split equally or assigned to specific losers per round.
2. **Race**: 
   - *Solo Race*: Individual players. The selected loser pays **100%** of the bill.
   - *Team Race*: Team A vs Team B. The winning team is selected, and the opposing team splits the bill.
3. **Fixed Interval**: Per Minute, Half Hour, One Hour packages.
4. **Rummy**: Specialized points-based game.

### The Financial Flow
When a game ends:
1. _initializeLiabilities() (in illing_screen.dart) calculates how much each player owes based on the game type and rules.
2. The user selects **Cash**, **UPI**, or **Credit** for the owed amounts.
3. If **Credit** is selected, CreditRepository.addCreditRecord is fired. This creates a transaction in the customer's ledger and updates their total outstanding balance.
4. If an order (food/drink) is attached to the game, the inventory stock is decremented.
5. GamesRepository.updateGamePayment() finalizes the game state.

**WARNING**: When touching billing code, ensure that changes to one game type (e.g., Solo Race) do not break the logic for others (e.g., Team Race or Standard splitting).

---

## 7. The Secondary Admin Dashboard

You will notice an dmin_dashboard/ directory in the root. 
- This is a **completely separate Flutter Web project**. 
- It acts as the Super Admin control panel for managing tenant subscriptions, viewing global metrics, and managing the platform.
- It is deployed separately (e.g., to Vercel/Firebase Hosting) and uses the same Firebase backend.

---

## 8. CI/CD and Scripts

The root folder is kept clean. All operational scripts live in the scripts/ directory:
- scripts/ci/: PowerShell scripts for building the release APK (uild_release.ps1) and distributing over-the-air updates.
- scripts/archive/: Legacy scripts, AI patches, and data-migration scripts. Only use these for historical reference.

---

## 9. Engineering Golden Rules

1. **Single Source of Truth**: Never duplicate business logic (like bill calculation) across multiple UI files. Keep it centralized.
2. **Auditing**: Always write to udit_logs when performing destructive actions (like deleting a game or deleting a POS transaction).
3. **Cascade Deletes**: If you delete a Quick Sale, you MUST cascade delete the associated Credit Transaction to keep the ledger mathematically sound (handled in CreditRepository).
4. **Security**: Do not bypass AppConfig.guardWrite(). This prevents staff members without permissions from altering financial data.
