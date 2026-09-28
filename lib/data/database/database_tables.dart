class DatabaseTables {
  DatabaseTables._();

  static const String tableClinicInfo = 'clinic_info';
  static const String tableUsers = 'users';
  static const String tableOwners = 'owners';
  static const String tablePets = 'pets';
  static const String tablePetWeights = 'pet_weights';
  static const String tableMedicines = 'medicines';
  static const String tableConsultations = 'consultations';
  static const String tablePrescriptions = 'prescriptions';
  static const String tableFollowUps = 'follow_ups';
  static const String tableSurgeries = 'surgeries';

  static const String createClinicInfoTable = '''
    CREATE TABLE $tableClinicInfo (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      clinic_name TEXT NOT NULL,
      doctor_name TEXT NOT NULL,
      phone TEXT,
      address TEXT,
      logo_path TEXT,
      license_number TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  ''';

  static const String createUsersTable = '''
    CREATE TABLE $tableUsers (
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
  ''';

  static const String createOwnersTable = '''
    CREATE TABLE $tableOwners (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      full_name TEXT NOT NULL,
      phone_primary TEXT NOT NULL,
      phone_secondary TEXT,
      address TEXT,
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  ''';

  static const String createOwnersPhoneIndex = '''
    CREATE INDEX idx_owners_phone ON $tableOwners(phone_primary);
  ''';

  static const String createPetsTable = '''
    CREATE TABLE $tablePets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      owner_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      species TEXT NOT NULL,
      breed TEXT,
      gender TEXT CHECK(gender IN ('male', 'female')),
      is_neutered INTEGER DEFAULT 0,
      date_of_birth DATE,
      microchip_number TEXT,
      photo_path TEXT,
      allergies TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (owner_id) REFERENCES $tableOwners (id) ON DELETE CASCADE
    );
  ''';

  static const String createPetsMicrochipIndex = '''
    CREATE INDEX idx_pets_microchip ON $tablePets(microchip_number);
  ''';

  static const String createPetWeightsTable = '''
    CREATE TABLE $tablePetWeights (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      pet_id INTEGER NOT NULL,
      weight REAL NOT NULL,
      recorded_date DATE NOT NULL,
      FOREIGN KEY (pet_id) REFERENCES $tablePets (id) ON DELETE CASCADE
    );
  ''';

  static const String createMedicinesTable = '''
    CREATE TABLE $tableMedicines (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      trade_name TEXT NOT NULL,
      scientific_name TEXT,
      form TEXT NOT NULL,
      concentration TEXT,
      clinic_stock INTEGER DEFAULT 0,
      warehouse_stock INTEGER DEFAULT 0,
      min_stock_alert INTEGER DEFAULT 5,
      unit_cost_price REAL DEFAULT 0.0,
      unit_sale_price REAL DEFAULT 0.0,
      expiry_date DATE NOT NULL,
      batch_number TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  ''';

  static const String createMedicinesExpiryIndex = '''
    CREATE INDEX idx_medicines_expiry ON $tableMedicines(expiry_date);
  ''';

  static const String createConsultationsTable = '''
    CREATE TABLE $tableConsultations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      pet_id INTEGER NOT NULL,
      doctor_id INTEGER NOT NULL,
      visit_date DATETIME NOT NULL,
      temperature REAL,
      heart_rate INTEGER,
      symptoms TEXT,
      examination_findings TEXT,
      diagnosis TEXT NOT NULL,
      treatment_plan TEXT,
      visit_cost REAL DEFAULT 0.0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (pet_id) REFERENCES $tablePets (id) ON DELETE CASCADE,
      FOREIGN KEY (doctor_id) REFERENCES $tableUsers (id)
    );
  ''';

  static const String createPrescriptionsTable = '''
    CREATE TABLE $tablePrescriptions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      consultation_id INTEGER NOT NULL,
      medicine_id INTEGER NOT NULL,
      dosage TEXT NOT NULL,
      frequency TEXT NOT NULL,
      duration_days INTEGER NOT NULL,
      quantity_dispensed INTEGER NOT NULL,
      instructions TEXT,
      FOREIGN KEY (consultation_id) REFERENCES $tableConsultations (id) ON DELETE CASCADE,
      FOREIGN KEY (medicine_id) REFERENCES $tableMedicines (id)
    );
  ''';

  static const String createFollowUpsTable = '''
    CREATE TABLE $tableFollowUps (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      pet_id INTEGER NOT NULL,
      consultation_id INTEGER,
      scheduled_date DATE NOT NULL,
      scheduled_time TEXT,
      reason TEXT NOT NULL,
      status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'completed', 'missed', 'cancelled')),
      reminder_sent INTEGER DEFAULT 0,
      notes TEXT,
      FOREIGN KEY (pet_id) REFERENCES $tablePets (id) ON DELETE CASCADE,
      FOREIGN KEY (consultation_id) REFERENCES $tableConsultations (id)
    );
  ''';

  static const String createFollowUpsDateIndex = '''
    CREATE INDEX idx_followups_date ON $tableFollowUps(scheduled_date);
  ''';

  static const String createSurgeriesTable = '''
    CREATE TABLE $tableSurgeries (
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
      FOREIGN KEY (pet_id) REFERENCES $tablePets (id) ON DELETE CASCADE,
      FOREIGN KEY (lead_surgeon_id) REFERENCES $tableUsers (id)
    );
  ''';
}
