class AppStringsAr {
  AppStringsAr._();

  // App General
  static const String appName = 'فيت بلس';
  static const String appSubTitle = 'المنظومة البيطرية السريرية المتكاملة';
  static const String offlineMode = 'وضع عدم الاتصال (محلي)';

  // Common Actions
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String add = 'إضافة';
  static const String search = 'بحث...';
  static const String details = 'التفاصيل';
  static const String confirm = 'تأكيد';
  static const String back = 'رجوع';
  static const String refresh = 'تحديث';
  static const String print = 'طباعة';
  static const String share = 'مشاركة';
  static const String shareWhatsApp = 'مشاركة عبر واتساب';
  static const String sendReminder = 'إرسال تذكير';
  static const String all = 'الكل';
  static const String noDataFound = 'لا توجد بيانات متاحة';
  static const String errorOccurred = 'حدث خطأ، يرجى المحاولة لاحقاً';
  static const String successSaved = 'تم الحفظ بنجاح';
  static const String successDeleted = 'تم الحذف بنجاح';
  static const String successUpdated = 'تم التحديث بنجاح';

  // Auth & Clinic Setup
  static const String loginTitle = 'تسجيل الدخول للنظام';
  static const String loginSubtitle = 'أدخل اسم المستخدم وكلمة المرور للمتابعة';
  static const String username = 'اسم المستخدم';
  static const String password = 'كلمة المرور';
  static const String pinCode = 'رمز PIN السريع';
  static const String enterPin = 'أدخل رمز PIN المكون من 4 أرقام';
  static const String quickUnlock = 'إلغاء القفل السريع';
  static const String login = 'دخول';
  static const String logout = 'تسجيل الخروج';
  static const String lockApp = 'قفل الشاشة';
  static const String clinicSetupTitle = 'تهيئة بيانات العيادة';
  static const String clinicName = 'اسم العيادة';
  static const String doctorName = 'اسم الطبيب المسؤول';
  static const String licenseNumber = 'رقم ترخيص مزاولة المهنة';
  static const String phone = 'رقم الهاتف';
  static const String address = 'عنوان العيادة';

  // Roles
  static const String role = 'الصلاحية / الدور';
  static const String roleLeadDoctor = 'طبيب رئيسي';
  static const String roleAssistantVet = 'طبيب مساعد';
  static const String roleReceptionist = 'موظف استقبال';
  static const String rolePharmacist = 'أمين المستودع والصيدلية';

  // Dashboard KPIs
  static const String dashboard = 'لوحة التحكم';
  static const String todayVisits = 'كشوفات اليوم';
  static const String todaySurgeries = 'عمليات اليوم';
  static const String pendingFollowUps = 'مراجعات مستحقة';
  static const String lowStockAlerts = 'أدوية أوشكت على النفاد';
  static const String expiredMedsAlerts = 'أدوية منتهية / قريبة';
  static const String quickActions = 'إجراءات سريعة';
  static const String newVisitAction = 'كشف جديد';
  static const String newPetAction = 'تسجيل مريض';
  static const String newSurgeryAction = 'حجز عملية';

  // Patients & Owners
  static const String patients = 'المرضى (الحيوانات)';
  static const String patientProfile = 'ملف المريض البيطري';
  static const String petName = 'اسم الحيوان';
  static const String species = 'الفصيلة';
  static const String speciesCat = 'قط';
  static const String speciesDog = 'كلب';
  static const String speciesBird = 'طائر';
  static const String speciesHorse = 'خيل';
  static const String speciesExotic = 'حيوان أليف آخر';
  static const String breed = 'السلالة';
  static const String gender = 'الجنس';
  static const String male = 'ذكر';
  static const String female = 'أنثى';
  static const String isNeutered = 'معقم / مخصي';
  static const String neuteredYes = 'نعم (معقم)';
  static const String neuteredNo = 'غير معقم';
  static const String birthDate = 'تاريخ الميلاد التقريبي';
  static const String age = 'العمر';
  static const String microchipNumber = 'رقم الشريحة الإلكترونية (Microchip)';
  static const String allergyWarningTitle = 'تنبيه الحساسية الدوائية';
  static const String allergiesNotes = 'سجل الحساسيات الدوائية والغذائية';
  static const String noAllergies = 'لا توجد حساسية دوائية مسجلة';
  static const String weightTracking = 'سجل تتبع الوزن ومؤشر النمو';
  static const String currentWeight = 'الوزن الحالي';
  static const String addWeight = 'تسجيل وزن جديد';
  static const String weightKg = 'كجم';

  // Owner Info
  static const String ownerInfo = 'بيانات المربي (المالك)';
  static const String ownerName = 'اسم المالك';
  static const String primaryPhone = 'رقم الهاتف الأساسي (واتساب)';
  static const String secondaryPhone = 'رقم الهاتف الاحتياطي';
  static const String ownerAddress = 'عنوان السكن';
  static const String ownerNotes = 'ملاحظات إضافية عن المالك';

  // Consultation & SOAP
  static const String consultations = 'الكشوفات والتشخيص';
  static const String newConsultation = 'فحص سريري جديد (SOAP)';
  static const String consultationDate = 'تاريخ وساعة الفحص';
  static const String vitalsSection = 'العلامات الحيوية السريرية';
  static const String temperature = 'درجة الحرارة (°C)';
  static const String heartRate = 'معدل ضربات القلب (نبضة/د)';
  static const String subjective = 'الشكوى وأعراض المربي (Subjective)';
  static const String subjectiveHint = 'مثال: تقيؤ مستمر منذ يومين، خمول تام، فقدان الشهية...';
  static const String objective = 'الفحص السريري المباشر (Objective)';
  static const String objectiveHint = 'مثال: ألم عند فحص البطن، جفاف بالأغشية المخاطية، احمرار الأذن...';
  static const String assessment = 'التشخيص النهائي / المشتبه به (Assessment)';
  static const String assessmentHint = 'مثال: بارفو، كاليسي، التهاب رئوي حاد...';
  static const String plan = 'الخطة العلاجية والتوصيات (Plan)';
  static const String planHint = 'السوائل الوريدية، البروتوكول الدوائي، الراحة المنزلية...';
  static const String visitCost = 'أتعاب الكشف والخدمات (ر.ي)';

  // Currency
  static const String currency = 'ريال يمني';
  static const String currencyShort = 'ر.ي';

  // Prescriptions & Dispensing
  static const String prescription = 'الروشتة والوصفة الطبية';
  static const String prescribedMedicines = 'الأدوية الموصوفة والمصروفة';
  static const String addMedicineToRx = 'إضافة دواء للروشتة';
  static const String selectMedicine = 'اختر الدواء';
  static const String dosage = 'الجرعة';
  static const String dosageHint = 'مثال: 0.5 مل أو 1 قرص';
  static const String frequency = 'التكرار';
  static const String frequencyHint = 'مثال: مرتين يومياً بعد الأكل';
  static const String durationDays = 'المدة بالأيام';
  static const String quantityDispensed = 'الكمية المصروفة من الرف';
  static const String instructions = 'تعليمات الاستخدام للعميل';
  static const String dosageCalculator = 'حاسبة الجرعات البيطرية (mg/kg)';
  static const String calculateDose = 'احسب الجرعة الدوائية';
  static const String targetDoseRate = 'معدل الجرعة (mg/kg)';
  static const String medicineConcentration = 'تركيز الدواء (mg/ml)';
  static const String calculatedDoseResult = 'الجرعة المقترحة المحسوبة:';

  // Pharmacy & Inventory
  static const String pharmacy = 'الصيدلية والمخزون';
  static const String clinicStock = 'رف العيادة (للاستخدام الفوري)';
  static const String warehouseStock = 'المستودع الرئيسي (الاحتياطي)';
  static const String totalStock = 'إجمالي الرصيد';
  static const String addMedicine = 'إضافة مستحضر طبي جديد';
  static const String tradeName = 'الاسم التجاري';
  static const String scientificName = 'الاسم العلمي / التركيبة';
  static const String form = 'الشكل الصيدلاني';
  static const String formInjection = 'حقن (Injectable)';
  static const String formTablet = 'أقراص (Tablets)';
  static const String formSyrup = 'شراب (Syrup/Suspension)';
  static const String formOintment = 'مرهم / قطرة (Topical)';
  static const String formVaccine = 'لقاح (Vaccine)';
  static const String formFluid = 'سوائل وريدية (IV Fluids)';
  static const String concentration = 'التركيز';
  static const String batchNumber = 'رقم التشغيلة (Batch)';
  static const String expiryDate = 'تاريخ انتهاء الصلاحية';
  static const String minStockAlert = 'حد الأمان لإعادة الطلب';
  static const String unitCostPrice = 'سعر الشراء للوحدة (ر.ي)';
  static const String unitSalePrice = 'سعر البيع للوحدة (ر.ي)';
  static const String stockTransfer = 'نقل مخزون (من المستودع إلى الرف)';
  static const String transferAmount = 'الكمية المنقولة';
  static const String stockExpiredTag = 'منتهي الصلاحية';
  static const String stockNearExpiryTag = 'أوشك على الانتهاء (<30 يوم)';
  static const String stockValidTag = 'صالح للاستخدام';
  static const String stockLowTag = 'رصيد منخفض';

  // Follow-ups & Reminders
  static const String followUps = 'المراجعات والمواعيد القادمة';
  static const String scheduleFollowUp = 'جدولة موعد مراجعة';
  static const String followUpDate = 'تاريخ المراجعة';
  static const String followUpReason = 'سبب المراجعة';
  static const String reasonBooster = 'جرعة تطعيم منشطة';
  static const String reasonSutureRemoval = 'فك غرز جراحية';
  static const String reasonRecheck = 'إعادة فحص سريري / سونار';
  static const String reasonBloodTest = 'تحليل دم تتبعي';
  static const String statusPending = 'قيد الانتظار';
  static const String statusCompleted = 'تمت المراجعة';
  static const String statusMissed = 'فائتة / متأخرة';
  static const String statusCancelled = 'ملغية';
  static const String filterOverdue = 'المتأخرة';
  static const String filterToday = 'مواعيد اليوم';
  static const String filterUpcoming = 'القادمة';

  // Surgeries
  static const String surgeries = 'الجناح الجراحي';
  static const String scheduleSurgery = 'حجز موعد عملية جراحية';
  static const String surgeryName = 'اسم العملية / الإجراء';
  static const String surgeryCategory = 'تصنيف الجراحة';
  static const String categoryElective = 'جراحة اختيارية (تعقيم/إخصاء)';
  static const String categorySoftTissue = 'أنسجة رخوة (Soft Tissue)';
  static const String categoryOrthopedic = 'عظام ومفاصل (Orthopedic)';
  static const String categoryDental = 'جراحة أسنان وفك (Dental)';
  static const String categoryEmergency = 'جراحة طارئة (Emergency)';
  static const String leadSurgeon = 'الجراح الرئيسي';
  static const String preOpChecklist = 'قائمة التحقق قبل الجراحة (Pre-Op)';
  static const String checkFasting = 'تم التحقق من صيام الحيوان (8-12 ساعة)';
  static const String checkBloodWork = 'تمت مراجعة نتائج وظائف الكبد والكلى';
  static const String checkConsent = 'تم توقيع إقرار التخدير والموافقة من المالك';
  static const String anesthesiaProtocol = 'بروتوكول التخدير والملاحظات';
  static const String postOpNotes = 'تعليمات العناية بعد الجراحة وخروج المريض';
  static const String estimatedCost = 'التكلفة التقديرية للعملية (ر.ي)';

  // Users Management
  static const String usersManagement = 'إدارة فريق العمل والصلاحيات';
  static const String addUser = 'إضافة موظف جديد';
  static const String fullName = 'الاسم الكامل';
  static const String activeStatus = 'الحالة الحالية';
  static const String userActive = 'نشط';
  static const String userInactive = 'معطل';
}
