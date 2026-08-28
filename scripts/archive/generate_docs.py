import os

docs_dir = 'docs'
if not os.path.exists(docs_dir):
    os.makedirs(docs_dir)

files = {
    'PROJECT_CONTEXT.md': '''# Project Context

## Application Overview
SaaS Snooker Club is a multi-tenant club management application designed for snooker, pool, and gaming clubs. It handles table/game tracking, billing (including split payments and credit), inventory management, point-of-sale (quick sales), and team management.

## Main Architecture
- **Frontend**: Flutter (Dart) using Riverpod for state management, GoRouter for navigation, and a heavily modularized feature-first architecture (lib/features/).
- **Backend**: Firebase (Firestore for database, Firebase Auth for authentication).
- **Multi-Tenant Architecture**: Single Firebase project supports multiple clubs. Users are mapped to clubs via the user_clubs root collection. All club-specific data is strictly partitioned inside clubs/{clubId}/*.

## Core Philosophy
- **Single Source of Truth**: All domain logic and data fetching happens through repositories which are scoped by clubIdProvider.
- **Offline First / Realtime**: Heavily uses Firestore snapshots (streams) for real-time sync across devices in the same club.

## Major Systems
- **Games**: Tracks active sessions on tables (Standard, Race, Rummy, Per Minute, etc.).
- **Billing**: Complex bill splitting, partial payments, and ledger-based credit system.
- **Inventory/POS**: Tracks stock levels and quick sales of items like drinks and snacks.
- **Credit (Ledger)**: Tracks outstanding balances per customer, with full payment history.
''',

    'CODEBASE_MAP.md': '''# Codebase Map

## Architecture Pattern
The project uses a Feature-First architecture under lib/features/. Each feature contains data (repositories), domain (models), providers (state), and presentation (UI).

## Core
- lib/core/: Shared constants, models, providers (e.g., club_scope_provider.dart for multi-tenancy), themes, and routing.

## Features
- **Authentication** (lib/features/authentication/): Firebase auth, login screens, user session.
- **Dashboard / Analytics** (lib/features/dashboard/, lib/features/analytics/): Financial summaries, charts, and revenue aggregation.
- **Games** (lib/features/games/): 
  - data/games_repository.dart: Manages tables and active/completed game sessions.
  - presentation/screens/: Table grid, Game setup, Table details, Billing screen.
- **Quick Sales** (lib/features/quick_sales/): POS system for selling inventory items.
- **Inventory** (lib/features/inventory/): Product catalog, stock management.
- **Credit** (lib/features/credit/): Customer ledger, outstanding balances, payment tracking.
- **Team** (lib/features/team/): Staff management and role-based access.
- **Settings** (lib/features/settings/): Club configuration, pricing rules, hardware/app settings.
''',

    'FIREBASE_SCHEMA.md': '''# Firebase Schema

## Multi-Tenant Root Collections
- user_clubs/{userId}: Maps a Firebase Auth UID to a { clubId, role }.
- platform/config: Global platform configuration (SaaS subscription price, support info).
- clubs/{clubId}: The root document for a specific tenant club.

## Club Subcollections (Tenant Data)
All business data resides under clubs/{clubId}/:
- 	ables: Physical game tables/resources.
- games: Game sessions (active and completed).
- inventory: Products and stock levels.
- quick_sales: POS transactions.
- credits: Customer profiles containing outstanding balances.
  - credits/{customerId}/transactions: Line items for debt added.
  - credits/{customerId}/payments: Line items for debt paid off.
- 	eam_members: Staff profiles for this club.
- udit_logs: System logs for sensitive actions (e.g., deletions).
- settings/club_config: Configuration for pricing, business rules, etc.

## Data Ownership & Rules
- irestore.rules enforces that a user can only read/write data under clubs/{clubId} if their user_clubs/{userId} document contains that clubId or if they are a Super Admin.
''',

    'ARCHITECTURE_RULES.md': '''# Architecture Rules

1. **Never read the entire repository unless absolutely required.** Use targeted search instead.
2. **Always identify the smallest affected feature first.**
3. **Search before reading large numbers of files.**
4. **Read only:** directly relevant files, immediate dependencies, required data services, and required shared types.
5. **Do not modify unrelated working systems.** Prefer surgical fixes over refactoring.
6. **Do not duplicate business logic.** Maintain a single source of truth.
7. **Do not create duplicate Firebase writes or duplicate financial calculations.**
8. **Do not change database architecture without understanding existing usage.**
9. **Do not delete code simply because it appears unused without verifying references.**
10. **Preserve backwards compatibility unless explicitly instructed otherwise.**
11. **Before making major changes, trace:** UI → state → business logic → service → Firebase → downstream consumers.
12. **Every financial change must be traced through:** Game → Bill → Payment → Transaction → Player Profile → Financial Reports → Firebase.
13. **Every game change must verify that other game types remain unaffected.**
14. **Never perform broad rewrites to fix a local bug.**
''',

    'CURRENT_SYSTEM_STATE.md': '''# Current System State

## WORKING FEATURES
- Multi-tenant architecture and club scoping.
- Game timing and real-time synchronization.
- Complex billing including Team Race and Solo Race.
- Financial dashboards and analytics.
- Point of sale (Quick Sales).
- Credit ledger tracking and partial payments.

## RECENT CHANGES
- Fixed Solo Race billing: Selected loser now correctly pays 100% of the bill without automatic splitting.
- Fixed Riverpod synchronous setState() crash on app load by replacing Stream.value() with const Stream.empty() in providers when clubId is not yet resolved.

## CURRENT BUSINESS RULES
- **Solo Race**: The selected loser pays 100% of the game and orders. No automatic splitting.
- **Team Race**: Winning team is selected; the opposing team splits the bill.
- **Standard Games**: Bills can be split among players, or assigned to specific losers per round.
- **Transactions**: Cash, UPI, and Credit payments all log corresponding audit and financial transactions.

## KNOWN ISSUES
- None currently reported.
''',

    'FEATURE_MAP.md': '''# Feature Map

## GAME SYSTEM
- **Standard Game**: Time-based or frame-based, with flexible bill splitting.
- **Per Minute / Half Hour / One Hour**: Time-based packages.
- **Race**:
  - **Solo Race**: Individual players. Loser pays all.
  - **Team Race**: Team A vs Team B. Losing team pays.
- **Rummy**: specialized points-based logic.

## BILLING FLOW
Entry UI (	able_details_screen.dart) 
→ Business Logic (_handleEndGame) 
→ Billing UI (illing_screen.dart) 
→ Calculations (_initializeLiabilities)
→ Payment Selection (Cash/UPI/Credit)
→ Firebase Service (GamesRepository.updateGamePayment or CreditRepository.addCreditRecord)
→ Transaction Impact (Dashboard, Credit Ledger, Audit Logs)
''',

    'CHANGELOG_AI.md': '''# AI Changelog

## DATE: 2026-08-28
**FEATURE**: Solo Race Billing
**CHANGE**: Fixed Solo Race billing logic so the selected loser pays 100% of the bill without falling back to equal splitting.
**AFFECTED SYSTEMS**: Game billing.
**DO NOT MODIFY**: Team Race, Standard Game.

## DATE: 2026-08-28
**FEATURE**: Riverpod Providers
**CHANGE**: Replaced synchronous Stream.value() emissions with const Stream.empty() across all feature providers when clubId is null to prevent setState() called during build exceptions.
**AFFECTED SYSTEMS**: Analytics, Credit, Games, Inventory, Quick Sales providers.
'''
}

for filename, content in files.items():
    with open(os.path.join(docs_dir, filename), 'w', encoding='utf-8') as f:
        f.write(content)

print("Documentation generated successfully.")
