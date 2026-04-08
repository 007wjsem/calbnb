// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'CalBNB';

  @override
  String get loginTitle => 'Iniciar Sesión';

  @override
  String get loginSubtitle => 'Accede a tu portal.';

  @override
  String get emailHint => 'Usuario';

  @override
  String get passwordHint => 'Contraseña';

  @override
  String get loginButton => 'Entrar';

  @override
  String get dashboardTitle => 'CalBNB';

  @override
  String get calendarTab => 'Calendario';

  @override
  String get metricsTab => 'Métricas';

  @override
  String get reportsTab => 'Reportes';

  @override
  String get companiesTab => 'Compañías';

  @override
  String get settingsTab => 'Ajustes';

  @override
  String get logoutButton => 'Cerrar Sesión';

  @override
  String get systemAdministration => 'Administración del Sistema';

  @override
  String get mainMenu => 'MENÚ PRINCIPAL';

  @override
  String get assignments => 'Asignaciones';

  @override
  String get myProfile => 'Mi Perfil';

  @override
  String get teamInbox => 'Bandeja de Entrada';

  @override
  String get myEarnings => 'Mis Ganancias';

  @override
  String get administration => 'ADMINISTRACIÓN';

  @override
  String get cleanings => 'Limpiezas';

  @override
  String get inspections => 'Inspecciones';

  @override
  String get payroll => 'Nómina';

  @override
  String get billingAndPlan => 'Facturación y Plan';

  @override
  String get advancedReports => 'Reportes Avanzados';

  @override
  String get management => 'GESTIÓN';

  @override
  String get users => 'Usuarios';

  @override
  String get properties => 'Propiedades';

  @override
  String get monthlyCalendar => 'Calendario Mensual';

  @override
  String get todayLabel => 'Hoy';

  @override
  String get todaysActivities => 'Actividades de Hoy';

  @override
  String get noActivities => 'No hay actividades para esta fecha.';

  @override
  String get filterByProperty => 'Filtrar por Propiedad';

  @override
  String get noPropertiesAvailable => 'No hay propiedades disponibles';

  @override
  String get loadingCalendarData => 'Cargando datos del calendario...';

  @override
  String get addBlockedDate => 'Agregar Fecha Bloqueada';

  @override
  String get selectProperty => 'Seleccionar Propiedad';

  @override
  String get reasonPlaceholder => 'Motivo (ej. Mantenimiento)';

  @override
  String get saveAction => 'Guardar';

  @override
  String get cancelAction => 'Cancelar';

  @override
  String get allProperties => 'Todas las Propiedades';

  @override
  String get profileUpdated => 'Perfil actualizado exitosamente.';

  @override
  String get errorOccurred => 'Error:';

  @override
  String get pwdMinLength => 'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get pwdMismatch => 'Las contraseñas no coinciden.';

  @override
  String get pwdUpdated => 'Contraseña actualizada exitosamente.';

  @override
  String get accountInfo => 'Información de la Cuenta';

  @override
  String get usernameLabel => 'Nombre de Usuario';

  @override
  String get emailLabel => 'Correo';

  @override
  String get roleLabel => 'Rol';

  @override
  String get contactDetails => 'Detalles de Contacto';

  @override
  String get phoneNumber => 'Número Télefonico';

  @override
  String get address => 'Dirección';

  @override
  String get emergencyContact => 'Contacto de Emergencia';

  @override
  String get emergencyHint => 'Nombre y número';

  @override
  String get saveContactInfo => 'Guardar Información';

  @override
  String get changePassword => 'Cambiar Contraseña';

  @override
  String get newPassword => 'Nueva Contraseña';

  @override
  String get confirmNewPassword => 'Confirmar Nueva Contraseña';

  @override
  String get updatePassword => 'Actualizar Contraseña';

  @override
  String get systemSettingsTitle => 'Ajustes del Sistema';

  @override
  String get errorLoadingData => 'Error cargando datos:';

  @override
  String get propertyOrderSaved =>
      'Orden de propiedades guardado exitosamente.';

  @override
  String get errorSavingPropertyOrder =>
      'Error al guardar el orden de propiedades:';

  @override
  String get currencySettings => 'Ajustes de Moneda';

  @override
  String get platinumTier => 'Platino';

  @override
  String get currencySettingsDesc =>
      'Establece la moneda utilizada en la nómina, ganancias y tarifas.';

  @override
  String get activeCurrency => 'Moneda Activa';

  @override
  String get applyCurrency => 'Aplicar Moneda';

  @override
  String get currencyUpdatedTo => 'Moneda actualizada a';

  @override
  String get phoneCountryCodeLabel => 'Código de País (WhatsApp)';

  @override
  String get phoneCountryCodeHelper =>
      'Se añade al número del personal al enviar mensajes de WhatsApp';

  @override
  String whatsAppCleaningMessage(
      String name, String date, String property, String address) {
    return '¡Hola $name! Tienes una asignación de limpieza el $date en $property, $address.';
  }

  @override
  String get messageCleanerOnWhatsApp => 'Enviar WhatsApp al Limpiador';

  @override
  String get noPhoneOnFileError =>
      'Este limpiador no tiene número de teléfono registrado.';

  @override
  String get couldNotOpenWhatsApp => 'No se pudo abrir WhatsApp';

  @override
  String get whiteLabelBranding => 'Marca Blanca';

  @override
  String get diamondTier => 'Diamante';

  @override
  String get whiteLabelDesc =>
      'Sube el logo de tu compañía para reemplazar la marca CalBNB en toda la aplicación.';

  @override
  String get chooseLogo => 'Elegir Logo';

  @override
  String get upload => 'Subir';

  @override
  String get logoUpdated => '¡Logo actualizado!';

  @override
  String get logoRemoved => 'Logo eliminado.';

  @override
  String get remove => 'Remover';

  @override
  String get propertyDisplayOrder => 'Orden de Visualización';

  @override
  String get propertyDisplayOrderDesc =>
      'Arrastra y suelta las propiedades a continuación para reorganizar cómo aparecen en el sistema. Haz clic en \'Guardar Orden\' cuando termines.';

  @override
  String get saveOrder => 'Guardar Orden';

  @override
  String get usersTitle => 'Usuarios';

  @override
  String get userLimitReachedPrefix => 'Límite de usuarios alcanzado';

  @override
  String get userLimitReachedSuffix =>
      'Mejora tu plan para agregar más usuarios.';

  @override
  String get upgradeAction => 'Mejorar';

  @override
  String get addUserAction => 'Agregar Usuario';

  @override
  String get searchUsersHint => 'Buscar por nombre, correo o teléfono...';

  @override
  String get allRolesFilter => 'Todos los Roles';

  @override
  String get ofKeyword => 'de';

  @override
  String get usersKeyword => 'usuarios';

  @override
  String get noUsersFound => 'No se encontraron usuarios';

  @override
  String get tryDifferentSearch => 'Intenta con otra búsqueda o filtro';

  @override
  String get addFirstUserAbove => 'Agrega tu primer usuario arriba';

  @override
  String get deleteUserTitle => 'Eliminar Usuario';

  @override
  String get deletePromptPrefix => '¿Eliminar a';

  @override
  String get deletePromptSuffix => '? Esta acción no se puede deshacer.';

  @override
  String get deleteAction => 'Eliminar';

  @override
  String get editUserTitle => 'Editar Usuario';

  @override
  String get createNewUserTitle => 'Crear Nuevo Usuario';

  @override
  String get updateRoleDetails => 'Actualiza el rol o detalles de contacto.';

  @override
  String get registerNewUser => 'Registra un nuevo usuario en el sistema.';

  @override
  String get emailAddressLabel => 'Correo Electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get displayNameLabel => 'Nombre para Mostrar';

  @override
  String get payRateLabel => 'Tarifa de Pago';

  @override
  String get saveChanges => 'Guardar Cambios';

  @override
  String get createUserAction => 'Crear Usuario';

  @override
  String get todaysCleaningsTitle => 'Limpiezas de Hoy';

  @override
  String get assignmentDetailsTitle => 'Detalles de la Asignación';

  @override
  String get selectCleanerLabel => 'Seleccionar Limpiador';

  @override
  String get selectInspectorLabel => 'Seleccionar Inspector (Opcional)';

  @override
  String get managerObservationsLabel =>
      'Observaciones del gerente para el limpiador';

  @override
  String get propertyCleaningFeeLabel =>
      'Tarifa de Limpieza (Cobrada al Dueño)';

  @override
  String get propertyInstructionsLabel => 'Instrucciones de la Propiedad';

  @override
  String get cleanerIncidentsLabel => 'Incidentes Reportados por el Limpiador';

  @override
  String get cancelCleaningAction => 'Cancelar Limpieza';

  @override
  String get createAssignmentAction => 'Crear Asignación';

  @override
  String get pleaseSelectCleanerError => 'Por favor, selecciona un limpiador';

  @override
  String get ownerPortalTitle => 'Portal del Dueño';

  @override
  String welcomeMessage(String username) {
    return 'Bienvenido, $username';
  }

  @override
  String assignedPropertiesCount(int count) {
    return 'Tienes $count propiedades asignadas.';
  }

  @override
  String get noAssignedPropertiesDesc =>
      'Aún no tienes propiedades asignadas a tu cuenta.';

  @override
  String get viewOnMapsTooltip => 'Ver en Mapas';

  @override
  String get cleaningActivityTitle => 'Actividad de Limpieza';

  @override
  String noCleaningsScheduledFor(String month) {
    return 'No hay limpiezas programadas para $month';
  }

  @override
  String errorLoadingActivity(String error) {
    return 'Error cargando actividad: $error';
  }

  @override
  String notePrefix(String note) {
    return 'Nota: $note';
  }

  @override
  String incidentsReportedCount(int count) {
    return '$count Incidente(s) Reportado(s)';
  }

  @override
  String get inspectorFindingsLabel => 'Hallazgos del Inspector:';

  @override
  String get checkoutEvidenceTitle => 'Evidencia de Salida (Checkout)';

  @override
  String get checkoutVerificationTitle => 'Verificación de Salida';

  @override
  String get requiredChecklistTitle => 'Lista de Verificación Requerida';

  @override
  String get verifyTasksDesc =>
      'Por favor, verifica que las siguientes tareas se hayan completado antes de terminar el trabajo.';

  @override
  String get photoEvidenceRequiredTitle => 'Evidencia Fotográfica Requerida';

  @override
  String get capturePhotosDesc =>
      'Por favor toma al menos 1 (hasta 3) fotos para probar que has terminado.';

  @override
  String get completeJobAction => 'Completar Trabajo';

  @override
  String get myPendingAssignmentsTitle => 'Mis Trabajos Pendientes';

  @override
  String get noPendingAssignmentsDesc => 'No hay trabajos pendientes.';

  @override
  String genericError(String error) {
    return 'Error: $error';
  }

  @override
  String get activeJobBadge => 'TRABAJO ACTIVO';

  @override
  String get managerNotesLabel => 'Notas del Gerente';

  @override
  String get cleaningInstructionsLabel => 'Instrucciones de Limpieza';

  @override
  String get reportIncidentAction => 'Reportar Incidente';

  @override
  String get finishJobAction => 'Terminar Trabajo';

  @override
  String get statusAssigned => 'Asignado';

  @override
  String get statusInProgress => 'En Progreso';

  @override
  String get statusPendingInspection => 'Esperando Inspección';

  @override
  String get statusFixNeeded => 'Requiere Corrección';

  @override
  String get statusApprovedCompleted => 'Aprobado (Completado)';

  @override
  String get statusLabel => 'Estado';

  @override
  String inspectorLabel(Object name) {
    return 'Inspector: $name';
  }

  @override
  String get checkInBadge => 'ENTRADA';

  @override
  String get checkOutBadge => 'SALIDA';

  @override
  String get reservedLabel => 'Reservado';

  @override
  String checkoutDateLabel(String date) {
    return 'Salida: $date';
  }

  @override
  String assignedDateLabel(String date) {
    return 'Asignado: $date';
  }

  @override
  String get inspectorFindingsFixLabel =>
      '⚠ Hallazgos del Inspector que requieren corrección:';

  @override
  String get startJobAction => 'Empezar Trabajo';

  @override
  String get descriptionLabel => 'Descripción';

  @override
  String get addPhotoAction => 'Agregar Foto';

  @override
  String get submitReportAction => 'Enviar Reporte';

  @override
  String get todaysInspectionsTitle => 'Inspecciones de Hoy';

  @override
  String get pendingInspectionsTitle => 'Inspecciones Pendientes';

  @override
  String get noPendingInspectionsDesc => 'No hay inspecciones pendientes.';

  @override
  String get statusWaitingForCleaner => 'Esperando al Limpiador...';

  @override
  String get statusReadyForInspection => 'Listo para Inspección';

  @override
  String get statusCleanerFixingIssues =>
      'El limpiador está corrigiendo problemas...';

  @override
  String get statusApproved => 'Aprobado';

  @override
  String cleanerLabel(String name) {
    return 'Limpiador: $name';
  }

  @override
  String finishedAtLabel(String date) {
    return 'Terminado a las: $date';
  }

  @override
  String get checkoutEvidenceLabel => 'Evidencia de Salida:';

  @override
  String get reportedIncidentsLabel => 'Incidentes Reportados:';

  @override
  String get inspectorFindingsNotesLabel => 'Hallazgos / Notas del Inspector:';

  @override
  String get noTextObservationDesc => 'Sin observación de texto';

  @override
  String get declineFixNeededAction => 'Rechazar (Requiere Corrección)';

  @override
  String get approveAction => 'Aprobar';

  @override
  String get addApprovalNotesTitle => 'Agregar Notas de Aprobación (Opcional)';

  @override
  String get reportFindingsFixNeededTitle =>
      'Reportar Hallazgos (Requiere Corrección)';

  @override
  String get notesLabel => 'Notas';

  @override
  String get descriptionOfIssuesLabel => 'Descripción de los problemas';

  @override
  String get provideTextOrPhotoError =>
      'Por favor, proporciona texto o una foto para rechazar';

  @override
  String get approveJobAction => 'Aprobar Trabajo';

  @override
  String get sendToFixAction => 'Enviar a Corregir';

  @override
  String get payrollDashboardTitle => 'Panel de Nómina';

  @override
  String get weeklyEarningsTitle => 'Ganancias Semanales';

  @override
  String get noApprovedJobsThisWeek =>
      'No hay trabajos de limpieza aprobados para esta semana.';

  @override
  String get unknownCleanerLabel => 'Limpiador Desconocido';

  @override
  String jobsCompletedLabel(int count) {
    return '$count trabajos completados';
  }

  @override
  String get teamInboxTitle => 'Bandeja del Equipo';

  @override
  String get cleanersChannel => 'Cleaners Channel';

  @override
  String get inspectorsChannel => 'Inspectors Channel';

  @override
  String get generalChannel => 'General';

  @override
  String get directMessages => 'Direct Messages';

  @override
  String get noActiveCompanyFound => 'No se encontró compañía activa.';

  @override
  String get markAllAsReadAction => 'Marcar todo como leído';

  @override
  String get noMessagesYetDesc => 'Aún no hay mensajes. ¡Di hola!';

  @override
  String get typeMessageHint => 'Escribe un mensaje…';

  @override
  String get advancedReportsTitle => 'Reportes Avanzados';

  @override
  String get advancedAnalyticsTitle => 'Analítica Avanzada';

  @override
  String diamondTierReportingLabel(int year) {
    return 'Reporte Nivel Diamante · $year';
  }

  @override
  String get totalCleaningsLabel => 'Limpiezas Totales';

  @override
  String get totalRevenueLabel => 'Ingresos Totales';

  @override
  String get totalPayrollLabel => 'Nómina Total';

  @override
  String get netMarginLabel => 'Margen Neto';

  @override
  String get monthlyCleaningsTitle => 'Limpiezas Mensuales';

  @override
  String get monthlyCleaningsDesc =>
      'Limpiezas completadas y aprobadas por mes';

  @override
  String get noCleaningDataForYear => 'No hay datos de limpieza para este año.';

  @override
  String get revenueVsPayrollTitle => 'Ingresos vs Nómina';

  @override
  String get revenueVsPayrollDesc =>
      'Comparación mensual de ingresos brutos y costo total de nómina';

  @override
  String get revenueLabel => 'Ingresos';

  @override
  String get payrollLabel => 'Nómina';

  @override
  String get cleanerPerformanceTitle => 'Rendimiento del Limpiador';

  @override
  String get cleanerPerformanceDesc =>
      'Ingresos generados vs costo de nómina por limpiador';

  @override
  String get noCleanerDataForYear =>
      'No hay datos de limpiadores para este año.';

  @override
  String get cleanerHeader => 'Limpiador';

  @override
  String get jobsHeader => 'Trabajos';

  @override
  String get revenueHeader => 'Ingresos';

  @override
  String get payrollHeader => 'Nómina';

  @override
  String get marginHeader => 'Margen';

  @override
  String get myEarningsTitle => 'Mis Ganancias';

  @override
  String get thisWeekTitle => 'Esta Semana';

  @override
  String get lastWeekTitle => 'Semana Pasada';

  @override
  String propertiesCleanedLabel(int count) {
    return '$count propiedades limpiadas';
  }

  @override
  String comparedToLastWeekLabel(String diff) {
    return '$diff comparado con la semana pasada';
  }

  @override
  String get thisWeeksDetailsTitle => 'Detalles de Esta Semana';

  @override
  String get noCompletedCleaningsThisWeekDesc =>
      'No hay limpiezas completadas esta semana.';

  @override
  String get propertiesTitle => 'Propiedades';

  @override
  String get generateDummyProperty => 'Generar Propiedad de Prueba (Test)';

  @override
  String get addPropertyAction => 'Agregar Propiedad';

  @override
  String get limitReached => 'Límite Alcanzado';

  @override
  String get searchPropertiesHint =>
      'Buscar por nombre, dirección, dueño o administración...';

  @override
  String get cityLabel => 'Ciudad';

  @override
  String get allCitiesFilter => 'Todas las Ciudades';

  @override
  String get propertyManagementLabel => 'Administración';

  @override
  String get allFilter => 'Todos';

  @override
  String get propertiesKeyword => 'propiedades';

  @override
  String get noPropertiesFound => 'No se encontraron propiedades';

  @override
  String get tryAdjustingSearchFilters =>
      'Intenta ajustar tu búsqueda o filtros';

  @override
  String get deletePropertyTitle => 'Eliminar Propiedad';

  @override
  String deletePropertyPrompt(String propertyName) {
    return '¿Eliminar \"$propertyName\"? Esto no se puede deshacer.';
  }

  @override
  String get stepBasic => 'Básico';

  @override
  String get stepLocationDetails => 'Ubicación y Detalles';

  @override
  String get stepOwnerMgmt => 'Dueño y Admin.';

  @override
  String get stepAccessCleaning => 'Acceso y Limpieza';

  @override
  String get syncIdLabel => 'ID de Sincronización / Slug';

  @override
  String get isCohostLabel => '¿Es Co-Anfitrión?';

  @override
  String get isCohostHelper =>
      'Activa si tu empresa administra esta propiedad pero no es dueña';

  @override
  String get assignToCompanyLabel => 'Asignar a Empresa *';

  @override
  String get selectCompanyHint => 'Seleccionar empresa';

  @override
  String get generateAction => 'Generar';

  @override
  String get cleanerFeeLabel => 'Pago Limpiador';

  @override
  String get companyLabel => 'Empresa';

  @override
  String get propertyNameLabel => 'Nombre de la Propiedad';

  @override
  String get propertyTypeLabel => 'Tipo de Propiedad';

  @override
  String get typeHouse => 'Casa';

  @override
  String get typeApartment => 'Departamento';

  @override
  String get typeOther => 'Otro';

  @override
  String get streetAddressLabel => 'Dirección';

  @override
  String get stateProvinceLabel => 'Estado/Provincia';

  @override
  String get zipPostalCodeLabel => 'Código Postal';

  @override
  String get countryLabel => 'País';

  @override
  String get cleaningFeeLabel => 'Tarifa de Limpieza';

  @override
  String get sizeLabel => 'AxBxC (Cuartos x Baños x Pisos)';

  @override
  String get schedulingSettingsLabel => 'Config. de Programación (Silver+)';

  @override
  String get recurringCleanCadenceLabel => 'Frecuencia de Limpieza Recurrente';

  @override
  String get cadenceNone => 'Ninguna (Ad-hoc)';

  @override
  String get cadenceWeekly => 'Semanal';

  @override
  String get cadenceBiWeekly => 'Quincenal';

  @override
  String get cadenceMonthly => 'Mensual';

  @override
  String get trashDayLabel => 'Día de Basura';

  @override
  String get trashDayNone => 'Ninguno';

  @override
  String get trashDayMonday => 'Lunes';

  @override
  String get trashDayTuesday => 'Martes';

  @override
  String get trashDayWednesday => 'Miércoles';

  @override
  String get trashDayThursday => 'Jueves';

  @override
  String get trashDayFriday => 'Viernes';

  @override
  String get trashDaySaturday => 'Sábado';

  @override
  String get trashDaySunday => 'Domingo';

  @override
  String get bufferHoursLabel => 'Horas de Reserva (Buffer)';

  @override
  String get bufferHoursHint => 'Horas requeridas antes del próximo check-in';

  @override
  String get linkedOwnerAccountLabel => 'Cuenta de Dueño Vinculada (Opcional)';

  @override
  String get linkedOwnerAccountHelper =>
      'Vincula esta propiedad al panel de un dueño';

  @override
  String get noneUnassigned => 'Ninguno / Sin Asignar';

  @override
  String get ownerNameLegacyLabel => 'Nombre del Propietario (Referencia)';

  @override
  String get propertyManagementCompanyLabel => 'Empresa Administradora';

  @override
  String get lockBoxPinLabel => 'PIN de Caja de Llaves';

  @override
  String get housePinLabel => 'PIN de la Casa';

  @override
  String get garagePinLabel => 'PIN del Garaje';

  @override
  String get customCleaningChecklistsTitle =>
      'Listas de Verificación de Limpieza';

  @override
  String get addChecklistItemHint => 'Agregar un nuevo elemento obligatorio...';

  @override
  String get addChecklistItemTooltip => 'Agregar Elemento';

  @override
  String get addInstructionPhotoAction => 'Agregar Foto de Instrucción';

  @override
  String get editPropertyTitle => 'Editar Propiedad';

  @override
  String get addNewPropertyTitle => 'Agregar Nueva Propiedad';

  @override
  String get setupPropertyDetailsDesc =>
      'Completa los pasos a continuación para configurar los detalles.';

  @override
  String get savePropertyAction => 'Guardar Propiedad';

  @override
  String get continueAction => 'Continuar';

  @override
  String get backAction => 'Atrás';

  @override
  String get pleaseSelectCompanyError =>
      'Por favor, selecciona una empresa para esta propiedad.';

  @override
  String get expressSaveAction => 'Guardado Rápido';

  @override
  String get propertyNameRequiredError =>
      'El Nombre de la Propiedad es necesario para el Guardado Rápido.';

  @override
  String get subscriptionLimitReachedTitle => 'Límite de Suscripción Alcanzado';

  @override
  String subscriptionLimitReachedDesc(int limit) {
    return 'Tu plan actual te limita a $limit propiedades. Por favor, mejora tu suscripción para agregar más.';
  }

  @override
  String get upgradePlanAction => 'Mejorar Plan';

  @override
  String get cleaningFeeSuffix => 'tarifa de lim.';

  @override
  String get lockPrefix => 'Llave:';

  @override
  String get housePrefix => 'Casa:';

  @override
  String get garagePrefix => 'Garaje:';

  @override
  String get settingsTabLabel => 'Ajustes';

  @override
  String get feedbackTabLabel => 'Feedback';

  @override
  String get noFeedbackLabel => 'Aún no hay comentarios operacionales.';

  @override
  String get englishToggle => 'English (US)';

  @override
  String get spanishToggle => 'Español (ES)';

  @override
  String get confirmPlanChangeTitle => 'Confirmar Cambio de Plan';

  @override
  String confirmPlanChangeDesc(String planName) {
    return '¿Estás seguro de que quieres cambiar tu suscripción al plan $planName?';
  }

  @override
  String get confirmAction => 'Confirmar';

  @override
  String successfullyUpdatedPlan(String planName) {
    return 'Plan actualizado exitosamente a $planName';
  }

  @override
  String errorUpdatingPlan(String error) {
    return 'Error al actualizar plan: $error';
  }

  @override
  String get noActiveCompanySelected => 'Ninguna compañía seleccionada.';

  @override
  String get companyDataNotFound => 'Datos de compañía no encontrados.';

  @override
  String get currentPlanLabel => 'PLAN ACTUAL';

  @override
  String get planSuffix => 'Plan';

  @override
  String get activeUsersLabel => 'Usuarios Activos';

  @override
  String get availablePlansTitle => 'Planes Disponibles';

  @override
  String get availablePlansDesc =>
      'Elige el plan perfecto para las necesidades de tu negocio. Mejóralo o redúcelo en cualquier momento.';

  @override
  String get unlimitedCount => '/ Ilimitado';

  @override
  String get perMonthLabel => '/ mes';

  @override
  String get currentPlanButton => 'Plan Actual';

  @override
  String get downgradeAction => 'Bajar Plan';

  @override
  String get mostPopularBadge => 'MÁS POPULAR';

  @override
  String get planFeatureBronze1 => 'Hasta 5 Propiedades';

  @override
  String get planFeatureBronze2 => 'Hasta 2 Usuarios';

  @override
  String get planFeatureBronze3 => 'Acceso a App Móvil';

  @override
  String get planFeatureBronze4 => 'Evidencia Fotográfica (3/limp)';

  @override
  String get planFeatureBronze5 => 'Datos Básicos de Propiedad';

  @override
  String get planFeatureSilver1 => 'Hasta 15 Propiedades';

  @override
  String get planFeatureSilver2 => 'Hasta 10 Usuarios';

  @override
  String get planFeatureSilver3 => 'Roles de Equipo (Limpiador vs Gerente)';

  @override
  String get planFeatureGold1 => 'Hasta 40 Propiedades';

  @override
  String get planFeatureGold2 => 'Hasta 12 Usuarios';

  @override
  String get planFeatureGold3 => 'Módulo de Nómina y Reportes';

  @override
  String get planFeatureGold4 => 'Portal de Dueño';

  @override
  String get planFeatureGold5 => 'Rol de Inspector';

  @override
  String get planFeaturePlatinum1 => 'Hasta 100 Propiedades';

  @override
  String get planFeaturePlatinum2 => 'Hasta 50 Usuarios';

  @override
  String get planFeaturePlatinum3 => 'Facturación Multimoneda';

  @override
  String get planFeatureDiamond1 => 'Propiedades Ilimitadas';

  @override
  String get planFeatureDiamond2 => 'Usuarios Ilimitados';

  @override
  String get planFeatureDiamond3 => 'Marca Blanca';

  @override
  String get planFeatureDiamond4 => 'Analítica Avanzada';

  @override
  String get planFeatureDiamond5 => 'Soporte Prioritario por WhatsApp';

  @override
  String get planFeatureFree1 => 'Solo 1 Propiedad';

  @override
  String get planFeatureFree2 => 'Solo 1 Usuario (Admin)';

  @override
  String get planFeatureFree3 => 'Vista Básica de Calendario';

  @override
  String get planFeatureFree4 => 'Listas de Control Estándar';

  @override
  String get planFeatureFree5 => 'Actualizaciones Manuales de Estado';

  @override
  String get addCleanerAction => 'Agregar Limpiador';

  @override
  String get mainCleanerLabel => 'Limpiador Principal';

  @override
  String get assistantCleanerLabel => 'Asistente';

  @override
  String individualFeeLabel(String name) {
    return 'Pago para $name';
  }

  @override
  String get assistantPermissionNotice =>
      'Rol de Asistente: Solo el limpiador principal puede iniciar o terminar este trabajo.';

  @override
  String get myPaymentsTitle => 'Mis Pagos';

  @override
  String get paymentHistoryTab => 'Historial de Pagos';

  @override
  String get payoutSettingsTab => 'Ajustes de Cobro';

  @override
  String get paymentPreferencesSaved =>
      'Preferencias de pago guardadas exitosamente.';

  @override
  String get payoutQuestion => '¿Cómo te gustaría cobrar?';

  @override
  String get bankTransferOption => 'Banco';

  @override
  String get bankNameLabel => 'Nombre del Banco';

  @override
  String get savingsAccountLabel => 'Número de Cuenta de Ahorros';

  @override
  String get cciLabel => 'CCI (Código Interbancario)';

  @override
  String registeredPhoneLabel(String provider) {
    return 'Número Celular registrado para $provider';
  }

  @override
  String get savePaymentInfoAction => 'Guardar Información de Pago';

  @override
  String get viewProofAction => 'Ver Comprobante';

  @override
  String paidOnLabel(String date) {
    return 'Pagado el $date';
  }

  @override
  String get noPaymentHistoryDesc => 'No se encontró historial de pagos.';

  @override
  String get registerButton => 'Regístrate';

  @override
  String get leadRegistrationTitle => 'Únete a Calbnb';

  @override
  String get leadRegistrationSubtitle =>
      'Cuéntanos sobre tu empresa y nos pondremos en contacto para ayudarte con la configuración.';

  @override
  String get leadNameLabel => 'Nombre de la Empresa / Tu Nombre';

  @override
  String get contactPreferenceLabel => '¿Cómo prefieres que te contactemos?';

  @override
  String get emailOption => 'Correo Electrónico';

  @override
  String get whatsappOption => 'WhatsApp';

  @override
  String get countryPickerLabel => 'Código de País';

  @override
  String get phoneNumberPlaceholder =>
      'Número de Teléfono (incluye código de país)';

  @override
  String get emailPlaceholder => 'Tu Correo Electrónico';

  @override
  String get submitLeadButton => 'Enviar Interés';

  @override
  String get leadSubmittedSuccess =>
      '¡Gracias! Recibimos tu solicitud y te contactaremos pronto.';

  @override
  String get fieldRequired => 'Este campo es obligatorio';

  @override
  String get superAdminLeadsMenu => 'Prospectos de Clientes';

  @override
  String get superAdminSupportMenu => 'Tickets de Soporte';

  @override
  String get leadContactTemplateEmailTitle =>
      'Calbnb: Configuración de tu cuenta';

  @override
  String leadContactTemplateWhatsApp(Object name) {
    return '¡Hola $name! Soy el administrador de Calbnb. Vi que estás interesado en nuestra plataforma. Para configurar tu cuenta, por favor proporciona el nombre de tu compañía y el enlace de tu propiedad en Airbnb o tu enlace de sincronización de calendario actual (Lodgify, etc.).';
  }

  @override
  String get supportTitle => 'Contactar a Soporte';

  @override
  String get supportSubtitle =>
      'Describe tu problema y nuestro equipo te ayudará en breve.';

  @override
  String get newTicketButton => 'Nuevo Ticket de Soporte';

  @override
  String get noTicketsMessage => 'No hay tickets de soporte aún.';

  @override
  String get ticketStatusOpen => 'Abierto';

  @override
  String get ticketStatusClosed => 'Resuelto';

  @override
  String get deleteTicketConfirm =>
      '¿Estás seguro de que deseas eliminar esta conversación?';

  @override
  String get priorityTicketLabel => 'Soporte Prioritario';
}
