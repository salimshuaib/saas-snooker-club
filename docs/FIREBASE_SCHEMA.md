# Firebase Schema

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
