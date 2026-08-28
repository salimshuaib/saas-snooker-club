# Feature Map

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
