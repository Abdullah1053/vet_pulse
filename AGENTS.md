# VetPulse Architecture & Agent Rules (Strict GetX + MVVM)

## 1. Strict MVVM + GetX Pattern
Every feature module under `lib/modules/<module_name>/` MUST strictly follow the MVVM pattern using GetX:
- **Model & Data Layer (`lib/data/models/` & `lib/data/repositories/`):**
  - Models are pure Dart data classes (`fromMap`, `toMap`, `copyWith`) with zero UI or DB logic.
  - Repositories handle ALL SQLite (`DatabaseHelper`) queries, atomic transactions (`db.transaction`), and trigger `DataSyncService` notifications automatically upon mutation.
  - Every domain entity MUST have its own dedicated Repository (1-to-1 responsibility).
- **ViewModel Layer (`lib/modules/<module>/controllers/`):**
  - Every ViewModel MUST extend `GetxController` (or `GetxService` for global services).
  - **NO GOD CONTROLLERS:** A single Controller must manage ONE specific View or sub-feature (e.g., separate `ConsultationFormController`, `DosageCalculatorController`, `PrescriptionController`, `ConsultationDetailController`).
  - Controllers must NEVER exceed ~200 lines or hold more than 8 `TextEditingController`s. If a screen has multiple complex sections, split them into child controllers and sub-views.
  - Repositories MUST be injected via GetX `Bindings` (`Get.lazyPut(() => Repo())` and `Get.lazyPut(() => Controller(Get.find()))`), never instantiated raw (`final _repo = Repo()`) inside a controller or view.
- **View Layer (`lib/modules/<module>/views/` & `widgets/`):**
  - Every screen and sub-view MUST extend `GetView<TController>` or `StatelessWidget`.
  - **STRICT BAN ON `StatefulWidget`:** Never use `StatefulWidget`, `setState()`, or `initState()` in module views or dialogs. Use `Obx()`, `GetBuilder`, and Controller lifecycle methods (`onInit`, `onReady`, `onClose`).
  - Views must contain ZERO business logic, ZERO direct repository calls, and ZERO SQL queries.

## 2. Anti-Hallucination & Scope Guardrails
- DO NOT invent extra widgets, decorative cards, or unrequested UI features.
- DO NOT duplicate Views as Dialogs (e.g., never create both `X_view.dart` and `X_dialog.dart` for the same screen).
- Always reuse core widgets (`CustomTextField`, `PrimaryButton`, `StatusChip`, `EmptyStateView`) and constants (`AppColors`, `AppStringsAr`, `AppPaymentMethods`).

## 3. Mandatory Core Hooks (Check on Every Task)
1. **Demo Quota:** Call `DemoConfig.canAdd...()` in the Controller before any creation flow.
2. **Auto-Sync in Repos:** Every `insert`, `update`, or `delete` inside a Repository MUST call the appropriate `DataSyncService.notify...Changed()` method before returning.
3. **Financial Ledger:** Billable actions (Consultations, Surgeries, Pharmacy sales) MUST atomically insert/update `financial_transactions` (and `customer_payments` if `paid_amount > 0`) inside a single SQLite `db.transaction()`.
4. **Database Schema:** `DatabaseTables` is the SINGLE source of truth for SQL table definitions. `DatabaseHelper.ensureAllTablesExist()` must reference `DatabaseTables` constants directly—never duplicate raw `CREATE TABLE` strings.