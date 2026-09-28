# 🐾 VetPulse: Technical Specification & Implementation Plan
> **Offline-First Veterinary Clinic & Patient Management System**  
> **Tech Stack:** Flutter (Dart 3.x) • GetX (State, Navigation, DI) • Local SQLite (`sqflite`)  
> **Target UX:** 100% Arabic Native UI • RTL Responsive • Modern Clinical Aesthetic

---

## 1. System Overview & Architectural Principles

**VetPulse** (`vet_pulse`) is an offline-first clinical workstation built for veterinary doctors and clinic staff. It eliminates network dependency by storing all critical records in an encrypted, high-performance local SQLite database while maintaining enterprise-grade architectural separation through GetX.

### Key Architectural Guidelines
- **Offline-First:** All read and write operations occur against local SQLite tables.
- **GetX Pattern:** Strict separation of UI (`View`), State/Business Logic (`Controller`), Dependency Injection (`Binding`), and Infrastructure (`Service`).
- **Full Arabic RTL:** Native `TextDirection.rtl`, directional paddings (`EdgeInsetsDirectional`), Arabic date/number formatting, and the **Cairo / Tajawal** typography system.

---

## 2. Design System & UI/UX Guidelines (Arabic RTL)

### 🎨 Medical Color Palette
- **Primary (Clinical Teal):** `#0E8388` — Communicates authority, cleanliness, and calm.
- **Secondary (Soft Mint):** `#CBE4DE` — Backgrounds for chips, active states, and accents.
- **Dark Neutral (Deep Slate):** `#2E4F4F` — High-contrast text and active navigation items.
- **Background (Snow Off-White):** `#F8FAFC` — Reduces eye strain during long clinical shifts.
- **Card Surface:** Pure White `#FFFFFF` with soft diffused elevation (`rgba(0, 0, 0, 0.04)`).
- **Status Indicators:**
  - 🔴 **Critical / Emergency / Expired:** Crimson Red (`#E63946`)
  - 🟠 **Pending / Low Stock / Due Soon:** Warm Amber (`#F4A261`)
  - 🟢 **Stable / Completed / In-Stock:** Sage Green (`#2A9D8F`)

### 🔤 RTL Typography & Directionality
- **Font Family:** `GoogleFonts.cairo()` or `GoogleFonts.tajawal()`.
- **Layout Direction:** Root configured with `locale: Locale('ar', 'SA')` and RTL text direction.
- **Mirroring:** Back buttons, chevrons, progress steppers, and list badges automatically adapt to RTL orientation without visual distortion.

---

## 3. Feature Priority Matrix

| Phase | Priority | Feature Module | Core Objective |
| :--- | :---: | :--- | :--- |
| **Phase 1** | **P0 (Critical)** | Core DB & App Engine | SQLite initialization, schema migration, and GetX services. |
| **Phase 1** | **P0 (Critical)** | Authentication & Clinic Profile | Doctor onboarding, clinic identity, and session locking. |
| **Phase 2** | **P0 (Critical)** | Patient & Owner Management | Comprehensive medical profiles for pets and owner directory. |
| **Phase 2** | **P0 (Critical)** | Clinical Consultation & SOAP Rx | Vitals, diagnosis, and prescription dispensing. |
| **Phase 3** | **P1 (High)** | Pharmacy & Dual-Storage Inventory | Shelf vs. warehouse tracking, batch expiration alerts. |
| **Phase 3** | **P1 (High)** | Follow-up & Re-visit Tracker | 2nd appointment tracking, vaccine schedules, and follow-ups. |
| **Phase 4** | **P1 (High)** | Surgical Suite Scheduler | Surgery bookings, pre-op checks, and anesthesia logging. |
| **Phase 4** | **P2 (Medium)** | Role-Based Access Control (RBAC) | Assistant vets, receptionists, and permission enforcement. |
| **Phase 5** | **P2 (Polish)** | Reporting & Printable Prescriptions | Arabic PDF export for prescriptions and local database backup. |

---

## 4. Detailed Feature Breakdown & Missing Clinical Details

---

### Feature 1: Doctor Login/Signup & Clinic Profile Setup
* **Objective:** Establish the clinic's administrative identity and secure access to medical records.
* **Core Requirements:**
  - Lead doctor registration and credential storage (hashed passwords / secure PIN).
  - Clinic metadata: Clinic Name, Doctor Name, License Number, Contact Numbers, Address, and Custom Logo.
* **Missing Details & Clinical Edge Cases Added:**
  - **Quick Unlock PIN / Biometrics:** Quick 4-digit PIN unlock so the doctor can resume work instantly between patients without re-typing complex passwords.
  - **Prescription Letterhead Customization:** The clinic info and logo will be automatically formatted into the header of printable/shareable Arabic digital prescriptions.

---

### Feature 2: User Roles & Permission Management (RBAC)
* **Objective:** Allow clinics with multiple staff members to collaborate securely without compromising sensitive operational data.
* **Roles Defined:**
  1. **Lead Veterinarian (طبيب رئيسي):** Unrestricted access (Diagnoses, Surgeries, Financials, User Management, Database Backup).
  2. **Assistant Veterinarian (طبيب مساعد):** Create/edit consultations, prescriptions, view surgery schedules (cannot delete records or alter inventory base prices).
  3. **Receptionist (موظف استقبال):** Register owners/pets, book follow-up appointments, view appointment calendars (cannot edit medical diagnoses).
  4. **Pharmacy/Inventory Keeper (أمين المستودع):** Receive drug batches, update stock counts, flag damaged/expired medicines.
* **Missing Details & Clinical Edge Cases Added:**
  - **Audit Logging:** Every consultation and stock deduction records the `user_id` of the actor for medical and financial traceability.

---

### Feature 3: Comprehensive Pet Patient & Owner Registry
* **Objective:** Provide a 360-degree clinical view of the pet patient.
* **Pet Attributes:**
  - Name, Species (Cat, Dog, Bird, Horse, Exotic), Breed, Gender, Spayed/Neutered flag.
  - Estimated Date of Birth / Age, Microchip Identification Number, Identification Photo.
  - Owner details: Full Name, Primary Phone (WhatsApp-enabled), Secondary Phone, Address.
* **Missing Details & Clinical Edge Cases Added:**
  - **Critical Drug Allergy Banner (تنبيه الحساسية الدوائية):** High-visibility red warning chip at the top of the patient file (e.g., Penicillin hypersensitivity).
  - **Weight History & Growth Curve:** Tracks patient weight chronologically across visits to detect progressive wasting or acute weight loss.
  - **Medical Attachment Gallery:** Save photos of skin lesions, x-rays, or laboratory bloodwork locally on the device linked to the pet's ID.

---

### Feature 4: Clinical Diagnosis, SOAP Notes & Digital Prescriptions
* **Objective:** Structure medical examinations into veterinary-standard SOAP documentation and automate medication dispensing.
* **Clinical Workflow:**
  - **Vitals Capture:** Body Temperature (°C), Heart Rate (bpm), Respiratory Rate, Hydration Level, Mucous Membrane color.
  - **SOAP Framework:**
    - **S (Subjective - الشكوى):** Presenting complaints (e.g., vomiting, lethargy, anorexia).
    - **O (Objective - الفحص السريري):** Physical exam findings (e.g., abdominal palpation pain, swollen lymph nodes).
    - **A (Assessment - التشخيص):** Confirmed or differential diagnosis (e.g., Feline Panleukopenia, Otitis Externa).
    - **P (Plan - الخطة العلاجية):** Prescribed drugs, procedural interventions, home care instructions.
* **Missing Details & Clinical Edge Cases Added:**
  - **Weight-Based Dosage Calculator:** Automated drug dose suggestion using formula: `Dose = (Weight in kg × Dose Rate mg/kg) / Concentration`.
  - **Automated Stock Deduction:** Dispensing a medication automatically reduces current shelf inventory and logs the transaction.
  - **Shareable Arabic Digital Prescription (PDF):** One-tap generation of a prescription ready to be shared via WhatsApp or sent to a thermal Bluetooth receipt printer.

---

### Feature 5: Follow-up & Re-visit Appointment Tracker
* **Objective:** Ensure continuity of care, track chronic patients, and prevent missed booster vaccinations.
* **Core Requirements:**
  - Schedule follow-up visits directly during the consultation closing step (e.g., 3 days, 1 week, 2 weeks).
  - Reason for re-visit: Wound review, suture removal, IV fluid review, 2nd booster dose, blood test re-evaluation.
* **Missing Details & Clinical Edge Cases Added:**
  - **Categorized Daily Dashboard:**
    - 🔴 **Overdue (مراجعات متأخرة):** Missed appointments requiring staff follow-up.
    - 🟡 **Due Today (مراجعات اليوم):** Scheduled for today.
    - 🟢 **Upcoming (مراجعات قادمة):** Scheduled for the rest of the week/month.
  - **One-Tap WhatsApp Reminder:** Quick action button to send a pre-formatted Arabic reminder message directly to the owner's WhatsApp.

---

### Feature 6: Pharmacy, Dual-Storage & Inventory Control
* **Objective:** Prevent stock-outs of life-saving medicines and eliminate the risk of administering expired pharmaceuticals.
* **Dual-Tier Storage Architecture:**
  1. **Clinic Shelf / Dispensing (صيدلية العيادة):** Opened bottles, active ampoules, and ready-to-dispense tablets located in treatment rooms.
  2. **Main Storage / Warehouse (المستودع الرئيسي):** Sealed bulk cartons and reserve stock.
* **Medicine Record Attributes:**
  - Trade name, Generic/Scientific name, Formulation (Tablet, Injectable, Suspension, Ointment).
  - Batch number, Expiration date, Minimum safety stock threshold, Purchase cost, Sale price.
* **Missing Details & Clinical Edge Cases Added:**
  - **Color-Coded Expiry Warning:**
    - 🔴 **Expired:** Hard block in UI preventing doctors from selecting it in prescriptions.
    - 🟠 **Expiring in < 30 Days:** Warning banner to prioritize usage or return to supplier.
    - 🟢 **Valid.**
  - **Internal Stock Transfer:** Formal workflow to transfer units from "Main Warehouse" to "Clinic Shelf".

---

### Feature 7: Surgical Suite & Surgery Scheduling
* **Objective:** Organize operating room availability, maintain anesthesia safety protocols, and manage post-operative recovery.
* **Core Requirements:**
  - Surgery booking linked to patient ID, Lead Surgeon, and Assistant/Anesthetist.
  - Classification: Elective (Spay/Neuter), Soft Tissue, Orthopedic, Dental, Emergency.
* **Missing Details & Clinical Edge Cases Added:**
  - **Pre-Operative Safety Checklist (قائمة التحقق قبل الجراحة):**
    - [ ] Fasting status verified (minimum 8-12 hours food withdrawal).
    - [ ] Pre-anesthetic blood panel cleared (Liver & Kidney function).
    - [ ] Owner anesthesia consent form signed.
  - **Anesthesia Protocol Log:** Induction agent used, maintenance gas percentage, intra-operative complications.
  - **Post-Op Discharge Orders:** Suture care instructions, prescribed post-op analgesics/antibiotics, and suture removal date.

---

### Feature 8: GetX Architecture & Local SQLite Database Engine
* **Objective:** Deliver a zero-latency, reactive, offline-first application structure.
* **GetX State Management Principles:**
  - All screens bind to dedicated `GetxController` instances.
  - State changes propagated via fine-grained reactive observables (`.obs` and `Obx()`).
  - Lazy dependency instantiation using `Bindings` on route transitions (`GetPage(binding: ...)`).
* **Database Engine:**
  - `sqflite` with foreign key enforcement (`PRAGMA foreign_keys = ON;`).
  - Indexed search fields (`phone`, `name`, `microchip`) for instant search across thousands of patient records.

---

## 5. Complete Relational Database Schema (SQLite)

```sql
PRAGMA foreign_keys = ON;

-- 1. Clinic Information & Configuration
CREATE TABLE clinic_info (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    clinic_name TEXT NOT NULL,
    doctor_name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    logo_path TEXT,
    license_number TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. Staff Users & Role-Based Permissions
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK(role IN ('lead_doctor', 'assistant_vet', 'receptionist', 'pharmacist')),
    phone TEXT,
    pin_code TEXT,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 3. Pet Owners (Clients)
CREATE TABLE owners (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    phone_primary TEXT NOT NULL,
    phone_secondary TEXT,
    address TEXT,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_owners_phone ON owners(phone_primary);

-- 4. Patients (Pets)
CREATE TABLE pets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    owner_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    species TEXT NOT NULL, -- Cat, Dog, Bird, etc.
    breed TEXT,
    gender TEXT CHECK(gender IN ('male', 'female')),
    is_neutered INTEGER DEFAULT 0,
    date_of_birth DATE,
    microchip_number TEXT,
    photo_path TEXT,
    allergies TEXT, -- Critical allergy notes
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES owners (id) ON DELETE CASCADE
);
CREATE INDEX idx_pets_microchip ON pets(microchip_number);

-- 5. Longitudinal Weight Tracking
CREATE TABLE pet_weights (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pet_id INTEGER NOT NULL,
    weight REAL NOT NULL, -- in kilograms
    recorded_date DATE NOT NULL,
    FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
);

-- 6. Pharmacy & Warehouse Inventory
CREATE TABLE medicines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    trade_name TEXT NOT NULL,
    scientific_name TEXT,
    form TEXT NOT NULL, -- tablet, injection, syrup, etc.
    concentration TEXT, -- e.g. 50mg/ml
    clinic_stock INTEGER DEFAULT 0, -- Active clinic shelf
    warehouse_stock INTEGER DEFAULT 0, -- Storage warehouse
    min_stock_alert INTEGER DEFAULT 5,
    unit_cost_price REAL DEFAULT 0.0,
    unit_sale_price REAL DEFAULT 0.0,
    expiry_date DATE NOT NULL,
    batch_number TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_medicines_expiry ON medicines(expiry_date);

-- 7. Consultations & SOAP Clinical Examination
CREATE TABLE consultations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pet_id INTEGER NOT NULL,
    doctor_id INTEGER NOT NULL,
    visit_date DATETIME NOT NULL,
    temperature REAL,
    heart_rate INTEGER,
    symptoms TEXT, -- Subjective
    examination_findings TEXT, -- Objective
    diagnosis TEXT NOT NULL, -- Assessment
    treatment_plan TEXT, -- Plan
    visit_cost REAL DEFAULT 0.0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES users (id)
);

-- 8. Prescriptions & Dispensed Medications
CREATE TABLE prescriptions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    consultation_id INTEGER NOT NULL,
    medicine_id INTEGER NOT NULL,
    dosage TEXT NOT NULL,
    frequency TEXT NOT NULL,
    duration_days INTEGER NOT NULL,
    quantity_dispensed INTEGER NOT NULL,
    instructions TEXT,
    FOREIGN KEY (consultation_id) REFERENCES consultations (id) ON DELETE CASCADE,
    FOREIGN KEY (medicine_id) REFERENCES medicines (id)
);

-- 9. Follow-Up & Re-visit Appointments
CREATE TABLE follow_ups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pet_id INTEGER NOT NULL,
    consultation_id INTEGER,
    scheduled_date DATE NOT NULL,
    scheduled_time TEXT,
    reason TEXT NOT NULL,
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'completed', 'missed', 'cancelled')),
    reminder_sent INTEGER DEFAULT 0,
    notes TEXT,
    FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE,
    FOREIGN KEY (consultation_id) REFERENCES consultations (id)
);
CREATE INDEX idx_followups_date ON follow_ups(scheduled_date);

-- 10. Surgical Suite Management
CREATE TABLE surgeries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pet_id INTEGER NOT NULL,
    lead_surgeon_id INTEGER NOT NULL,
    scheduled_date DATETIME NOT NULL,
    surgery_name TEXT NOT NULL,
    surgery_category TEXT,
    status TEXT DEFAULT 'scheduled' CHECK(status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    pre_op_checklist_passed INTEGER DEFAULT 0,
    anesthesia_protocol TEXT,
    post_op_notes TEXT,
    estimated_cost REAL,
    FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE,
    FOREIGN KEY (lead_surgeon_id) REFERENCES users (id)
);
```

---

## 6. GetX Clean Architecture Folder Structure

```text
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart          # Teal (#0E8388), Mint (#CBE4DE), Slate (#2E4F4F)
│   │   ├── app_strings_ar.dart      # Complete Arabic translation dictionary
│   │   └── app_theme.dart           # ThemeData with RTL and Cairo font configuration
│   ├── utils/
│   │   ├── arabic_date_helper.dart  # Arabic date and calendar utilities
│   │   └── dosage_calculator.dart   # Veterinary mg/kg calculation logic
│   └── widgets/
│       ├── custom_text_field.dart   # RTL-adapted input fields with right-aligned labels
│       ├── primary_button.dart      # Styled action buttons with loading indicators
│       ├── status_chip.dart         # Color-coded status tags (Expired, Due, Stable)
│       └── empty_state_view.dart    # Clean placeholder illustration when lists are empty
│
├── data/
│   ├── database/
│   │   ├── database_helper.dart     # SQLite connection, migration, and raw query executor
│   │   └── database_tables.dart     # Schema creation DDL strings
│   ├── models/
│   │   ├── clinic_model.dart
│   │   ├── user_model.dart
│   │   ├── owner_model.dart
│   │   ├── pet_model.dart
│   │   ├── consultation_model.dart
│   │   ├── medicine_model.dart
│   │   ├── follow_up_model.dart
│   │   └── surgery_model.dart
│   └── repositories/
│       ├── pet_repository.dart
│       ├── consultation_repository.dart
│       ├── inventory_repository.dart
│       └── appointment_repository.dart
│
├── modules/
│   ├── auth/                        # Login, Clinic Setup & PIN Unlock
│   │   ├── controllers/auth_controller.dart
│   │   ├── bindings/auth_binding.dart
│   │   └── views/login_view.dart
│   │
│   ├── dashboard/                   # Main Home Screen with Quick Clinical KPI Cards
│   │   ├── controllers/dashboard_controller.dart
│   │   ├── bindings/dashboard_binding.dart
│   │   └── views/dashboard_view.dart
│   │
│   ├── patients/                    # Pet Profiles, Owners & Weight Logs
│   │   ├── controllers/patient_controller.dart
│   │   ├── bindings/patient_binding.dart
│   │   └── views/
│   │       ├── patient_list_view.dart
│   │       ├── patient_detail_view.dart
│   │       └── add_patient_view.dart
│   │
│   ├── consultations/               # Clinical Diagnoses, SOAP & Prescription Issuance
│   │   ├── controllers/consultation_controller.dart
│   │   ├── bindings/consultation_binding.dart
│   │   └── views/
│   │       ├── new_consultation_view.dart
│   │       └── prescription_preview_view.dart
│   │
│   ├── follow_ups/                  # Follow-Up Calendar, WhatsApp Reminders
│   │   ├── controllers/follow_up_controller.dart
│   │   ├── bindings/follow_up_binding.dart
│   │   └── views/follow_up_calendar_view.dart
│   │
│   ├── pharmacy/                    # Dual-Storage Stock, Expiration Tracker
│   │   ├── controllers/pharmacy_controller.dart
│   │   ├── bindings/pharmacy_binding.dart
│   │   └── views/
│   │       ├── inventory_list_view.dart
│   │       ├── add_medicine_view.dart
│   │       └── stock_transfer_view.dart
│   │
│   ├── surgeries/                   # Operating Room Calendar & Pre-Op Checklists
│   │   ├── controllers/surgery_controller.dart
│   │   ├── bindings/surgery_binding.dart
│   │   └── views/
│   │       ├── surgery_calendar_view.dart
│   │       └── new_surgery_view.dart
│   │
│   └── users_management/            # Staff Accounts & Permission Configuration
│       ├── controllers/users_controller.dart
│       ├── bindings/users_binding.dart
│       └── views/users_list_view.dart
│
├── routes/
│   ├── app_pages.dart               # GetPage declarations with route-level bindings
│   └── app_routes.dart              # Route string constants
│
└── main.dart                        # App entry point with Arabic locale and service init
```

---

## 7. Dependencies Checklist (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State Management & Routing
  get: ^4.6.6

  # Local SQLite Persistence
  sqflite: ^2.3.0
  path: ^1.9.0

  # Typography & RTL Support
  google_fonts: ^6.1.0
  intl: ^0.19.0

  # Prescription & Report Export
  pdf: ^3.10.8
  printing: ^5.13.1
  url_launcher: ^6.2.5 # For direct WhatsApp and phone dialing
```
