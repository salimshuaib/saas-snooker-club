# Codebase Map

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
