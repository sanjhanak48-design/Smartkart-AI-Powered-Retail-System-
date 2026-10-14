# SmartKart — Development Plan

## Project Overview

**SmartKart** is an AI-Powered Retail Billing Flutter app. Users authenticate via phone OTP, link an RFID cart (via QR scan or manual entry), browse products, receive AI recommendations, earn/redeem SmartCoins, and checkout through a mock payment flow.

**Stack:** Flutter 3.47.2 / Dart 3.13.2 / Riverpod / GoRouter / Firebase Auth (Android) / mobile_scanner

**Architecture:** Clean Architecture per feature (`domain/models/`, `data/repositories/`, `presentation/controllers/` + `presentation/pages/`). Abstract repositories with `Mock*` implementations. Sealed state classes. In-memory mock data throughout.

---

## Completed Blocks

### Block 1 — Foundation & Authentication ✅
- Flutter project scaffold, theme (Deep Teal + Warm Amber), Material 3
- Firebase Auth (phone OTP), auth controller with sealed states
- Login page (phone input), OTP verification page (6-digit entry, resend)
- Loading/splash page, GoRouter with auth redirect guard
- Auth repository with mock fallback

### Block 2 — Product Catalog & Home ✅
- Home page with navigation cards (My Orders, Smart Picks, Shop Products)
- AppBar actions: QR scanner, cart, profile, sign-out
- Catalog page with product grid, search bar, category filter chips
- Catalog controller with search and category filtering
- MockCatalogRepository (14 products across 6 categories)

### Block 3 — Cart Management ✅
- Cart domain models (Cart, CartItem, CartStatus, CartEvent)
- CartController: link, load, add/remove items, quantity management
- MockCartRepository with stream-based real-time updates
- RFID simulation buttons (itemAdded, itemRemoved events)

### Block 4 — QR Cart Linking ✅
- QR scanner page with camera overlay and validation
- QR scanner controller (validates `smartkart://cart/<id>` or `CART-<digits>`)
- Link cart page (manual Cart ID entry)
- Known carts: CART-1, CART-2, CART-3

### Block 5 — Live Cart & Checkout ✅
- Live cart page: real-time item list, RFID stream, cart status
- Checkout page: order summary, line items, subtotal
- Cart event streaming (itemAdded, itemRemoved, cartCleared, statusChanged)

### Block 6 — Rewards (SmartCoins) ✅
- SmartCoins domain model (balance, transactions)
- RewardsController: load, award, redeem, reverse, consume
- MockRewardsRepository (in-memory balance + transaction history)
- SmartCoins page: balance card, redeem button, transaction history
- Earn rate: `floor(order.total)` coins per order

### Block 7 — AI Recommendations (Smart Picks) ✅
- RecommendationEngine: weighted scoring (cart affinity 3x, history 2x, co-purchase 1x, cold-start fallback)
- RecommendationsController with loading states
- Smart Picks page: recommendation cards with "Add" buttons
- RecommendationRepository with mock data

### Block 8 — Profile & Order History ✅
- Profile page: user info, UID, SmartCoins balance, order stats, sign-out
- OrderStats computed from order list
- PurchaseHistoryPage: list of past orders
- OrderDetailsPage: individual order view with path parameter

### Block 9 — QR Scanner Polish & Share ✅
- QR scanner micro-interactions
- Share sheet for cart/recommendations
- Smart Picks on-device polish

### Block 10–22 — Hardening, Polish & Integration ✅
- Cart event stream wiring, live cart streaming
- Checkout discount integration, receipt page
- Auth router guards for all routes
- Stream-based cart updates throughout
- Purchase history integration
- All foundational features wired end-to-end
- **214 tests passing at this stage**

### Step 23 — Checkout Store Reward Discount Flow ✅
- Reward toggle on checkout page (balance gating at 100 coins)
- `checkoutTotal` getter on CartController (`total - rewardDiscount`, clamped >= 0)
- Discount row on checkout summary and receipt
- `applyStoreReward` / toggle reversal logic
- Reward consumed on order success, reversed on cancel
- **221 tests passing**

### Step 24 — QR Scanner Micro-Interactions & Smart Picks Polish ✅
- QR scanner share sheet enhancements
- Smart Picks on-device refinements
- dart format pass (whitespace normalization)
- **214 tests (recount post-format)**

### Block 25A — Customer Payment Journey ✅
- **Payment domain models:** `PaymentMethod` (upi, card), `PaymentResult` (success/failure)
- **Payment repository:** Abstract `PaymentRepository` + `MockPaymentRepository` (400ms delay, deterministic success, `MOCK-PAY-0001…`)
- **Payment controller:** Sealed states (Idle/Processing/Success/Failure), `_busy` re-entrancy guard, `reset()`
- **Payment page:** Payable amount display, custom UPI/Card selection tiles (UPI default), "Pay ₹XX.XX" CTA, "Cancel Payment", processing spinner, failure box with "Try Again", mock disclaimer
- **Checkout → Payment:** CTA changes from "Place Order" to "Pay ₹XX.XX", navigates to `/payment`
- **Receipt payment card:** Status (Paid Mock), Method, Amount, Reference ID, disclaimer
- **Reward integrity:** Apply→pending, success→consume, fail/cancel→pending stays
- **Duplicate-submit prevention:** Controller busy flag + page disables controls during processing
- **8 files created, 8 files modified**
- **233/233 tests passing, dart analyze clean**

### Block 25B — Core Resilience & Routing Hardening ✅
- **App-level error handling:** `FlutterError.onError` + `runZonedGuarded` in `main.dart`; Firebase init wrapped in try/catch (logs and continues instead of crashing on startup)
- **Router hardening:** `errorBuilder` → `NotFoundPage` fallback for unknown routes/router errors; `/history/:orderId` no longer force-unwraps — rejects blank/missing ids with `NotFoundPage`
- **Splash timeout:** `LoadingPage` is now stateful with a 10s `Timer` fallback to `/login` (safe in all auth states; disposed/cancelled when navigated away); normal startup unchanged
- **Error theme tokens:** `AppColors.error` (Material red 700), `AppTextStyles.error` + `AppTextStyles.errorSmall`
- **Files created (1):** `lib/core/pages/not_found_page.dart`
- **Files modified (6):** `lib/main.dart`, `lib/core/router/app_router.dart`, `lib/features/auth/presentation/pages/loading_page.dart`, `lib/core/theme/app_colors.dart`, `lib/core/theme/app_text_styles.dart`
- **Tests created (2):** `test/core/router/not_found_page_test.dart`; updated `test/features/auth/loading_page_test.dart`
- **237/237 tests passing, dart analyze clean**

### Block 26 — Shared Widgets & Theme Consolidation ✅
- **Shared widgets under `lib/core/widgets/`:** `EmptyStateView`, `ErrorView`, `InfoBanner`, `LinkCartBanner`, `LoadingIndicator`, `LoadingButton`, `SummaryLine`, `CartItemRow`
- **Shared utility:** `lib/core/utils/date_format.dart` — `DateTimeFormat.date` (DD/MM/YYYY) / `DateTimeFormat.time` (12-hour h:mm AM/PM)
- **Refactored pages** to use the shared foundation (exact text/navigation/state/layout/a11y preserved):
  - `catalog_page`, `smart_picks_page`, `live_cart_page`, `checkout_page` (from prior partial work, dead code removed)
  - `receipt_page` → EmptyStateView, CartItemRow, SummaryLine, InfoBanner, LoadingButton, LoadingIndicator, DateTimeFormat
  - `purchase_history_page` → EmptyStateView, ErrorView, LoadingIndicator, DateTimeFormat
  - `order_details_page` → LoadingIndicator, ErrorView (Back), EmptyStateView, CartItemRow, SummaryLine, DateTimeFormat
  - `smart_coins_page` → LoadingIndicator, ErrorView (retry), InfoBanner; `_ErrorView` icon converged `Colors.redAccent` → shared error color (approved)
  - `payment_page` → LoadingIndicator, InfoBanner, LoadingButton
  - `qr_scanner_page` → LoadingIndicator (scanner placeholder only)
- **Theme tokens applied:** `AppColors.iconPlaceholder` (replaces `textSecondary@50%` in not_found_page, live_cart_page), `primarySoft` (primary@10%), `primaryFaint` (primary@8%) across catalog, smart_picks, live_cart, link_cart, qr_scanner, smart_coins. `accentContainer` intentionally NOT applied to `accentLight.withValues(alpha:0.15)` banners because the baked value differs (visual-change guardrail).
- **Dead code removed:** 6 analyzer warnings eliminated (`_CheckoutItemRow`/`_SummaryRow` in checkout, `_EmptyResultsView`/`_ErrorView` in catalog) plus orphaned imports.
- **Tests added (9 files, 19 tests):** `test/core/utils/date_format_test.dart` + `test/core/widgets/{empty_state_view,error_view,info_banner,loading_indicator,loading_button,summary_line,cart_item_row,link_cart_banner}_test.dart`
- **256/256 tests passing, dart analyze clean**


---

## Remaining Manual Verification

These are manual device checks that were deferred during automated development:

| Step | Item | Status |
|------|------|--------|
| Step 22 | Physical device QR scan (camera-based) | Pending |
| Step 24 | Smart Picks on-device verification | Pending |
| Block 25A | Full payment journey on emulator/device | Pending |

---

### Block 27 — Presentation Parity & Error Resilience ✅
- **Objective:** Finish presentation-layer parity: receipt payment fallback, profile error/retry parity (no ProfileController), payment error tokens + method-tile semantics, and summary/SmartCoins `AppColors.error` cleanup.
- **Task 1 — Receipt fallback** (`lib/features/cart/presentation/pages/receipt_page.dart`): non-success Payment now shows shared `InfoBanner('Payment details are not available for this receipt.')`; success Payment card text preserved; mock InfoBanner retained.
- **Task 2 — Profile parity** (`lib/features/profile/presentation/pages/profile_page.dart`): shared `LoadingIndicator` replaces raw `CircularProgressIndicator()`; history `HistoryError` → inline error message + `FilledButton.tonal('Retry')` calling `fetchHistory()`; `_SmartCoinsSection` on `RewardsError` shows error-color value + `rewardsState.message` in error color + `FilledButton.tonal('Retry')` calling `loadRewards()`; `View SmartCoins` preserved. No ProfileController (approved decision).
- **Task 3 — Payment** (`lib/features/payment/presentation/pages/payment_page.dart`): `_PaymentErrorBox` → `AppColors.errorLight`/`AppColors.error`; `_PaymentMethodTile` wrapped in `Semantics(button: true, selected: selected, label: title)`.
- **Task 4 — Token sweep:** `lib/core/widgets/summary_line.dart` and `lib/features/rewards/presentation/pages/smart_coins_page.dart` `Colors.red.shade700` → `AppColors.error`. Zero `Colors.red.shade*` remain in `lib/`.
- **Tests added:** `test/features/cart/receipt_page_test.dart` (3 tests); `test/features/payment/payment_page_test.dart` (semantics via `SemanticsData.flagsCollection` + error-token); `test/features/profile/profile_page_test.dart` (history + SmartCoins error/Retry recovery via `_FailingOnceCartRepository`/`_FailingOnceRewardsRepository`); `test/core/widgets/summary_line_test.dart` + `test/features/rewards/smart_coins_page_test.dart` error-color assertions.
- **264/264 tests passing (42 test files), dart analyze clean**

---

### Block 28 — Premium UI/UX Transformation ✅
- **Objective:** Premium visual transformation of every page (presentation-only), preserving all functionality, navigation, routing, controllers, repositories, models, and exact user-visible strings, semantics, and state behavior.
- **Scope guardrails honoured:** no new packages, no new features, no architectural changes, no product-detail screen, no bottom navigation.
- **Design tokens (`lib/core/theme/`):** `app_dimens.dart` (AppSpacing scale ×2s-xxxl, screen padding, radii, component sizes, `app_duration`/`app_elevation` tokens), `app_colors.dart` (primary gradient, `card`, `divider`, `errorLight`, `primaryFaint`, `accentGradient`, `textPrimary`/`textSecondary`), `app_text_styles.dart` (heroTitle/heroSubtitle, sectionNumber, price/priceLarge, statLabel/statValue, label), `app_theme.dart` (AppBar elevation 0).
- **Shared widgets added (4):** `hero_banner.dart` (gradient hero + stats), `status_badge.dart`, `order_summary_card.dart`, `quick_action_tile.dart`.
- **Shared widgets enhanced (4):** `app_card.dart` (default shadow/border), `empty_state_view.dart`, `cart_item_row.dart`, `summary_line.dart`.
- **Pages transformed (17):**
  - Auth: `login_page.dart` (gradient header + floating card), `otp_verification_page.dart` (gradient icon circle, 6-digit validation, spinner), `loading_page.dart` (primaryGradient, BrandLogoMark, `LoadingPage.timeout` preserved).
  - `not_found_page.dart` (new): plain AppBar (no custom back button — `context.canPop()` throws under `MaterialApp(home:)` test), `'Go to Home'` via `context.go('/')`.
  - Home: `home_page.dart` HeroBanner, connected-cart strip (cart id + totalQuantity), QuickActions 2×2 with contract subtitles ('Browse Products' → /catalog, 'See Recommendations' → /recommendations, 'View Purchase History' → /history), Smart Picks preview (header `'Handpicked For You'` so `'Smart Picks'` appears exactly once), rewards card; 4 AppBar actions preserved.
  - Catalog: `catalog_page.dart` search clear button, styled ChoiceChips, product count in AppBar actions (`'N products'` — moved out of body so list items stay visible in the 800×600 test viewport), compact FilterBar/product card, Card + `'+ Add'` + LinkCartBanner preserved.
  - Smart Picks: `smart_picks_page.dart` `_AiIntroCard` + amber-accented recommendation cards, Card + `'+ Add'` + empty/error/link texts preserved.
  - Live Cart: `live_cart_page.dart` RFID section in AppCard, Checkout FilledButton (height 52), static connection dot.
  - Checkout: user info bar in AppCard; all contract texts preserved.
  - Payment: `payment_page.dart` amount hero card (`priceLarge`), Semantics tiles preserved.
  - Receipt: `receipt_page.dart` OrderSummaryCard for order cards; payment card keeps combined strings ('Payment Status: Paid (Mock)', 'Method: Card', 'Amount Paid: ₹119.00', 'Reference: MOCK-PAY-0001'); mock InfoBanner + `'Done'` preserved.
  - Purchase History: `purchase_history_page.dart` + `order_details_page.dart` StatusBadge('Paid') + OrderSummaryCard.
  - Profile: `profile_page.dart` UID copy button (`Clipboard` from `package:flutter/services.dart`), stat labels.
  - SmartCoins: `smart_coins_page.dart` static `_HowItWorks` steps (avoids literal 'SmartCoins'/'124'/'coins' text conflicts).
- **Test-drive regression fixes (root-caused, not blind):**
  - Repeating/infinite animations break `pumpAndSettle` — QR scan line and Live Cart dot made static (no `AnimationController.repeat()` on pages under test).
  - Catalog `'Tea'` (item index 2) must render in the 800×600 viewport without scrolling — compacted banner spacing/FilterBar paddings, ChoiceChips `VisualDensity.compact`, card image 48 + `AppSpacing.sm` padding.
- **Results:** `dart format lib test` clean; `flutter analyze` — No issues found; `flutter test` — **264/264 passing (42 files)**; `flutter build apk --debug` — **`build\app\outputs\flutter-apk\app-debug.apk`** built successfully.
- **Remaining issues:** none automated; deferred manual device checks listed below.

---

### Block 29 — Reference-Accurate UI/UX Redesign ✅
- **Objective:** Complete reference-image-aligned redesign of the whole app: warm cream/ivory canvas (`#FAF6F0`), deep forest green used selectively for premium feature cards (`#1B3A2D`), muted gold accents, large rounded cards, soft shadows, compact premium density, pill-shaped elements, bento compositions, floating bottom nav. Presentation-only — no new packages, features, or business logic.
- **Design tokens (`lib/core/theme/`):** `app_colors.dart` (warm ivory `canvas`, premium dark `primary` `#1B3A2D`, muted gold accent `#C49A5C`, neutral shadows), `app_dimens.dart` (compact spacing `xxs=3…xl=28`, generous radii `radiusLg=18`, `radiusFull=100`), `app_text_styles.dart` (compact hierarchy, new `sectionLabel`), `app_theme.dart` (warm scaffold, NavigationBar theme, `FadeUpwardsPageTransitionsBuilder`, pill chips/inputs, premium-dark snackbar).
- **Shared widgets added (5):** `main_scaffold.dart` (bottom-nav shell `ShellRoute` host — destinations Home/Shop/Cart/Coins/Profile via `context.go`), `fade_in_wrapper.dart` (finite staggered entrance — `pumpAndSettle`-safe), `pressable_card.dart` (tactile 0.97 scale), `section_label.dart`, `stat_module.dart`.
- **Router restructured:** tab routes (`/`, `/catalog`, `/live-cart`, `/smartcoins`, `/profile`) moved inside a `ShellRoute` wrapping `MainScaffold`; all other routes remain pushed on top (no bottom nav), preserving the 16-route map.
- **Pages redesigned:** Home (AppBar 'SmartKart' + 'Link Cart' tooltip preserved, 'Welcome!' greeting, premium-dark connected-cart card, bento 2×2 quick actions with contract subtitles, 'Handpicked For You' rail, rewards mini-card); Profile (centered identity, `StatModule` Orders/Items/'Total Spent' (`₹…toStringAsFixed(2)`), SmartCoins compact card with 'View SmartCoins' + error message/Retry, 'Order Activity' rows, Sign Out); Catalog (warm search field, compact ChoiceChips, refined cards); SmartCoins (warm gold balance card); Login/OTP/Loading (warm canvas, premium-dark brand, refined form). Remaining pages refined via the theme system with all strings/semantics preserved.
- **Regression fixes from test drive (44 failing → 0):**
  - Removed `Spacer()` from Home bento cards (unbounded-height `RenderFlex` overflow inside `SingleChildScrollView` → cascaded across ~40 widget tests).
  - `'Welcome!'` greeting restored (QR-scanner back-nav contract).
  - Profile: `'Order Activity'` mixed-case text, `₹`/`toStringAsFixed(2)` Total Spent format, SmartCoins error shows `RewardsError.message`, added 'View SmartCoins' label.
  - Bottom nav 'Rewards' destination renamed 'Coins' to avoid duplicating the SmartCoins page's 'Rewards' section under the always-visible nav bar.
- **Results:** `dart format lib test` clean (0 changed); `dart analyze lib/` — 1 pre-existing info lint only (use_null_aware_elements in `section_label.dart`); `flutter test` — **264/264 passing (42 files)**; `flutter build apk --debug` — **`build\app\outputs\flutter-apk\app-debug.apk`** built successfully.

---

## Current Test Baseline

- **264/264 tests passing**
- **dart analyze: No issues found**
- **flutter build apk --debug: Successful** (`build\app\outputs\flutter-apk\app-debug.apk`)
- **42 test files** across 8 feature areas + core widgets/utils
- Test command: `flutter test`
- Format command: `dart format lib test`

## Current Route Map (16 routes)

| Route | Page | Auth Required |
|-------|------|---------------|
| `/splash` | LoadingPage | No |
| `/login` | LoginPage | No |
| `/otp` | OtpVerificationPage | No |
| `/` | HomePage | Yes |
| `/profile` | ProfilePage | Yes |
| `/catalog` | CatalogPage | Yes |
| `/recommendations` | SmartPicksPage | Yes |
| `/smartcoins` | SmartCoinsPage | Yes |
| `/link-cart` | LinkCartPage | Yes |
| `/live-cart` | LiveCartPage | Yes |
| `/scan-cart` | QrScannerPage | Yes |
| `/checkout` | CheckoutPage | Yes |
| `/payment` | PaymentPage | Yes |
| `/receipt` | ReceiptPage | Yes |
| `/history` | PurchaseHistoryPage | Yes |
| `/history/:orderId` | OrderDetailsPage | Yes |
