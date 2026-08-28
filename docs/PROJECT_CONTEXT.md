# Project Context

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
