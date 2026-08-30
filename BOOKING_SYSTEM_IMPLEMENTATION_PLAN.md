# BOOKING SYSTEM IMPLEMENTATION PLAN

## 1. Executive Summary
The Table/Game Booking System for Sharma Billiards is designed to allow customers to reserve gaming resources (snooker tables, PS5, simulators, etc.) in advance. To protect the integrity of the existing highly-complex billing and game management engine, the Booking System will be built as an isolated, additive feature. **A booking is strictly a reservation, not an active game.** Games are only created when the club owner explicitly marks a customer as arrived and starts the game. This plan outlines a two-stage rollout (Version 1 and Version 2) ensuring safe, phased integration without destabilizing production code.

## 2. Existing Architecture Analysis
Based on the current Sharma Billiards architecture:
- **Stack:** Flutter (Frontend) + Firebase Firestore (Backend Single Source of Truth).
- **Data Isolation:** All data is strictly isolated under `clubs/{clubId}/*`.
- **Game Engine:** Handles diverse and complex logic including standard games, race games, per-minute, per-frame, and package billing.
- **State Management:** Uses Providers/Repositories for state and data fetching.
- **Conclusion:** The existing game and billing engines must remain completely untouched. The booking system must be built as a parallel feature (`lib/features/bookings`) that only interacts with the game engine at one specific handoff point: `Start Game From Booking`.

## 3. Recommended Booking Architecture
- **Additive Design:** We will introduce a new `Resource` concept to abstract bookable entities (Tables, Consoles, VIP Rooms) to ensure future-proofing.
- **New Feature Module:** A dedicated `lib/features/bookings/` folder containing:
  - `data/booking_repository.dart`
  - `domain/models/booking_model.dart`
  - `presentation/screens/booking_dashboard.dart`
  - `providers/booking_providers.dart`
- **Minimal Interference:** No existing collections (`tables`, `games`) will be structurally altered. 

## 4. Firebase Data Structure
Bookings will be stored in a new top-level collection within the club document. This respects the existing architecture and prevents unnecessary duplication.

```text
clubs/
 └── {clubId}/
      ├── tables/
      ├── games/
      ├── inventory/
      ├── ...
      └── bookings/           <-- NEW
           ├── {bookingId_1}
           ├── {bookingId_2}
           └── {bookingId_3}
```

## 5. Booking Model
The booking document will use precise timestamps for accurate availability checking, avoiding ambiguous slot-based logic.

```dart
class BookingModel {
  final String bookingId;
  final String clubId;

  // Resource Information
  final String resourceId;      // e.g., tableId
  final String resourceName;    // e.g., "Snooker Table 1"
  final String resourceType;    // e.g., "snooker", "ps5", "carrom"

  // Customer Information
  final String customerName;
  final String customerPhone;

  // Time Information
  final DateTime startTime;     // Exact start timestamp
  final DateTime endTime;       // Exact end timestamp

  // Lifecycle
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String source;          // e.g., "customer_web", "owner_app"

  // Handoff Reference
  final String? gameId;         // Null until the game is actually started
}

enum BookingStatus {
  pending,      // Customer requested, waiting for owner (if manual confirmation is needed)
  confirmed,    // Locked in and approved
  arrived,      // Customer is physically present
  completed,    // Game was started and finished
  cancelled,    // Cancelled by owner or customer
  noShow        // Customer never arrived
}
```

## 6. Resource Availability Logic
The system will dynamically calculate availability by querying the Single Source of Truth (Firestore).
**Availability Formula:** 
`Resource is Available IF (No Active Game on Resource) AND (No Confirmed/Pending Bookings overlapping with requested Time Window)`

- **Overlap Check:** A requested booking from `ReqStart` to `ReqEnd` overlaps an existing booking if: `(ReqStart < ExistingEnd) AND (ReqEnd > ExistingStart)`.
- **Live Games:** The system must cross-reference `clubs/{clubId}/tables` (where active `gameId` or table status is stored). If a table is occupied, it cannot be booked for a time slot that overlaps with the *current time*.

## 7. Booking Lifecycle
1. **BOOKING CREATED:** Customer submits form. Status = `pending` or `confirmed`.
2. **CUSTOMER ARRIVES:** Customer walks into the club.
3. **OWNER ACTION:** Owner finds the booking and taps `Mark Arrived`. Status = `arrived`.
4. **START GAME:** Owner taps `Start Game From Booking`. This transitions the user to the existing Game Setup screen.
5. **HANDOFF:** Game is created in the `games` collection. Booking is updated with `gameId` and Status = `completed`.

## 8. Owner App Flow
A dedicated "Bookings" tab will be added to the Sharma Billiards navigation.
- **Dashboard Views:**
  - *Today:* Quick list of upcoming bookings for the current day.
  - *Upcoming:* Future reservations.
  - *History:* Completed, Cancelled, and No-Shows.
- **Visual Indicators:** The main Tables/Games dashboard will show a small indicator (e.g., a calendar icon) on a table if it has an upcoming booking within the next 2 hours.
- **Actions:** View Details, Confirm, Cancel, Mark Arrived, Start Game.

## 9. Customer Booking Flow
- **Step 1:** Customer accesses a lightweight booking interface (web/app).
- **Step 2:** Selects the specific Club.
- **Step 3:** Browses abstract "Resources" (Snooker, PS5).
- **Step 4:** Selects Date, Start Time, and Duration.
- **Step 5:** System validates availability against Firestore.
- **Step 6:** Customer provides Name and Phone.
- **Step 7:** Booking is saved. Customer receives a simple confirmation screen/link to check status. *(No WhatsApp/Meta integration required).*

## 10. Booking-to-Game Integration
Integration is strictly one-way (Booking -> Game) via the UI.
When the owner clicks **"Start Game From Booking"**:
1. The app routes to the *existing* `GameSetupScreen`.
2. The route arguments pre-fill the form:
   - Resource/Table ID -> Pre-selects the correct table.
   - Customer Name -> Pre-fills the player name.
3. The owner retains full control to adjust the game type (Race, Standard, Package) and billing rules.
4. Once the owner hits "Start Game" on the setup screen, the standard game engine takes over. The Booking status updates to `completed`.

## 11. Single Source of Truth Strategy
- **No Duplicate State:** Bookings live only in `clubs/{clubId}/bookings`.
- **No Local Caching of Availability:** Availability checks must query Firestore directly to prevent double-booking caused by stale local data.
- **Event-Driven UI:** The Owner app will listen to the `bookings` collection via standard Riverpod/StreamProviders. When a new booking is written by a customer, the Owner's UI updates instantly.

## 12. Edge Cases
| Edge Case | Safe Handling Strategy |
| :--- | :--- |
| **Simultaneous Booking** | Firestore Transactions will lock the resource timeframe during writes. The second booking will fail gracefully and prompt the user to pick another time. |
| **Active Game Overlaps Future Booking** | If a walk-in game is running and a future booking approaches, the UI will warn the owner (e.g., "Table 1 has a booking in 15 mins"). The system will *not* automatically end the active game. |
| **Customer Cancellation** | Frees up the resource immediately. Status changes to `cancelled`. |
| **Resource Deleted** | If a table is removed, all upcoming bookings for it should be flagged for manual reassignment by the owner. |
| **Customer Early/Late** | Owner manages this manually. The booking acts as a hold, but the actual billing depends on when the owner taps "Start Game". |
| **Manual Game Start** | If an owner manually starts a game on a booked table without using the booking flow, the system warns: "This table is booked at [Time]. Continue?" |

## 13. Security Considerations
- **Firestore Rules:** Customers can only `create` and `read` their own bookings (validated via phone number/session ID). Only authenticated owners can `update` or `delete` bookings within their `clubId`.
- **Data Validation:** Start time must be in the future. End time must be strictly after start time. Maximum duration limits (e.g., 5 hours) must be enforced to prevent abuse.

## 14. Phased Implementation Plan

- **PHASE 1: Architecture & Firebase Design**
  - Define Firestore rules.
  - Setup `clubs/{clubId}/bookings` structure.
- **PHASE 2: Booking Model & Repository**
  - Create `BookingModel`, `BookingRepository`, and `BookingProviders`.
  - *Risks:* None, entirely additive.
- **PHASE 3: Owner Booking Dashboard**
  - Build the UI for the owner to view, accept, and cancel bookings.
  - *Files Affected:* Sharma Billiards Main Navigation (Add tab).
- **PHASE 4: Availability Engine**
  - Write the logic to check overlapping timestamps and active games.
  - *Testing Requirement:* Rigorous unit testing on time overlap logic.
- **PHASE 5: Booking-to-Game Integration**
  - Add "Start Game From Booking" button.
  - Pass route arguments to existing `GameSetupScreen`.
  - *Files Affected:* `app_router.dart`, `game_setup_screen.dart` (only to accept optional arguments).
- **PHASE 6: Customer Booking Interface**
  - Build the isolated web/app flow for customers.
- **PHASE 7: Testing & Edge Cases**
  - End-to-end testing of simultaneous bookings, overlapping times, and no-shows.

## 15. File Impact Analysis
- **NEW FILES:**
  - `lib/features/bookings/domain/models/booking_model.dart`
  - `lib/features/bookings/data/booking_repository.dart`
  - `lib/features/bookings/providers/booking_providers.dart`
  - `lib/features/bookings/presentation/screens/owner_booking_dashboard.dart`
  - `lib/features/bookings/presentation/widgets/booking_card.dart`
- **MODIFIED FILES (Minimal Impact):**
  - `lib/main_router.dart` (Add routes for booking screens).
  - `lib/features/dashboard/presentation/screens/main_dashboard.dart` (Add Bookings to bottom nav).
  - `lib/features/games/presentation/screens/game_setup_screen.dart` (Accept optional `initialPlayerName` and `initialTableId` arguments).

## 16. Testing Checklist
- [ ] Verify booking creation writes correctly to `clubs/{clubId}/bookings`.
- [ ] Verify overlap logic rejects overlapping times on the same resource.
- [ ] Verify active live games correctly block immediate bookings.
- [ ] Verify "Start Game" correctly routes to setup screen with pre-filled data.
- [ ] Verify starting a game updates booking status to `completed`.
- [ ] Verify Firestore Security Rules block cross-club booking reads/writes.

## 17. Final Recommendation

**Build this in two stages.**

**Version 1 (Core Reliability):**
Focus exclusively on the core loop: Customer books online -> Owner sees it in the app -> Owner starts the game from the booking. This keeps scope tight and validates the Firestore availability engine without touching the complex billing logic.

**Version 2 (Enhancements):**
Once Version 1 is stable, introduce advanced features like Calendar Views, No-Show analytics, Booking Reminders, and Advance Deposits.

By strictly adhering to the principle that **"A booking reserves a resource, but only a Game record dictates billing and gameplay"**, the existing Sharma Billiards architecture will remain entirely safe and stable throughout this implementation.
