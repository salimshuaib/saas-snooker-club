# Current System State

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
