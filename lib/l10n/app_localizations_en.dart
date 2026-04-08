// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CalBNB';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginSubtitle => 'Access your portal.';

  @override
  String get emailHint => 'User';

  @override
  String get passwordHint => 'Password';

  @override
  String get loginButton => 'Log In';

  @override
  String get dashboardTitle => 'CalBNB';

  @override
  String get calendarTab => 'Calendar';

  @override
  String get metricsTab => 'Metrics';

  @override
  String get reportsTab => 'Reports';

  @override
  String get companiesTab => 'Companies';

  @override
  String get settingsTab => 'Settings';

  @override
  String get logoutButton => 'Log Out';

  @override
  String get systemAdministration => 'System Administration';

  @override
  String get mainMenu => 'MAIN MENU';

  @override
  String get assignments => 'Assignments';

  @override
  String get myProfile => 'My Profile';

  @override
  String get teamInbox => 'Inbox';

  @override
  String get myEarnings => 'My Earnings';

  @override
  String get administration => 'ADMINISTRATION';

  @override
  String get cleanings => 'Cleanings';

  @override
  String get inspections => 'Inspections';

  @override
  String get payroll => 'Payroll';

  @override
  String get billingAndPlan => 'Billing & Plan';

  @override
  String get advancedReports => 'Advanced Reports';

  @override
  String get management => 'MANAGEMENT';

  @override
  String get users => 'Users';

  @override
  String get properties => 'Properties';

  @override
  String get monthlyCalendar => 'Monthly Calendar';

  @override
  String get todayLabel => 'Today';

  @override
  String get todaysActivities => 'Today\'s Activities';

  @override
  String get noActivities => 'No activities for this date.';

  @override
  String get filterByProperty => 'Filter by Property';

  @override
  String get noPropertiesAvailable => 'No properties available';

  @override
  String get loadingCalendarData => 'Loading Calendar Data...';

  @override
  String get addBlockedDate => 'Add Blocked Date';

  @override
  String get selectProperty => 'Select Property';

  @override
  String get reasonPlaceholder => 'Reason (e.g., Maintenance)';

  @override
  String get saveAction => 'Save';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get allProperties => 'All Properties';

  @override
  String get profileUpdated => 'Profile updated successfully.';

  @override
  String get errorOccurred => 'Error:';

  @override
  String get pwdMinLength => 'Password must be at least 6 characters.';

  @override
  String get pwdMismatch => 'Passwords do not match.';

  @override
  String get pwdUpdated => 'Password updated successfully.';

  @override
  String get accountInfo => 'Account Information';

  @override
  String get usernameLabel => 'Username';

  @override
  String get emailLabel => 'Email';

  @override
  String get roleLabel => 'Role';

  @override
  String get contactDetails => 'Contact Details';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get address => 'Address';

  @override
  String get emergencyContact => 'Emergency Contact';

  @override
  String get emergencyHint => 'Name & number';

  @override
  String get saveContactInfo => 'Save Contact Info';

  @override
  String get changePassword => 'Change Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get systemSettingsTitle => 'System Settings';

  @override
  String get errorLoadingData => 'Error loading data:';

  @override
  String get propertyOrderSaved => 'Property order saved successfully.';

  @override
  String get errorSavingPropertyOrder => 'Error saving property order:';

  @override
  String get currencySettings => 'Currency Settings';

  @override
  String get platinumTier => 'Platinum';

  @override
  String get currencySettingsDesc =>
      'Set the currency used across payroll, earnings, and fees.';

  @override
  String get activeCurrency => 'Active Currency';

  @override
  String get applyCurrency => 'Apply Currency';

  @override
  String get currencyUpdatedTo => 'Currency updated to';

  @override
  String get phoneCountryCodeLabel => 'WhatsApp Country Code';

  @override
  String get phoneCountryCodeHelper =>
      'Prepended to staff phone numbers when sending WhatsApp messages';

  @override
  String whatsAppCleaningMessage(
      String name, String date, String property, String address) {
    return 'Hello $name! You have a cleaning assignment on $date at $property, $address.';
  }

  @override
  String get messageCleanerOnWhatsApp => 'Message Cleaner on WhatsApp';

  @override
  String get noPhoneOnFileError => 'This cleaner has no phone number on file.';

  @override
  String get couldNotOpenWhatsApp => 'Could not open WhatsApp';

  @override
  String get whiteLabelBranding => 'White-Label Branding';

  @override
  String get diamondTier => 'Diamond';

  @override
  String get whiteLabelDesc =>
      'Upload your company logo to replace the CalBNB branding across the app.';

  @override
  String get chooseLogo => 'Choose Logo';

  @override
  String get upload => 'Upload';

  @override
  String get logoUpdated => 'Logo updated!';

  @override
  String get logoRemoved => 'Logo removed.';

  @override
  String get remove => 'Remove';

  @override
  String get propertyDisplayOrder => 'Property Display Order';

  @override
  String get propertyDisplayOrderDesc =>
      'Drag and drop the properties below to rearrange how they appear in the system. Click \'Save Order\' when finished.';

  @override
  String get saveOrder => 'Save Order';

  @override
  String get usersTitle => 'Users';

  @override
  String get userLimitReachedPrefix => 'User limit reached';

  @override
  String get userLimitReachedSuffix => 'Upgrade your plan to add more users.';

  @override
  String get upgradeAction => 'Upgrade';

  @override
  String get addUserAction => 'Add User';

  @override
  String get searchUsersHint => 'Search by name, email or phone...';

  @override
  String get allRolesFilter => 'All Roles';

  @override
  String get ofKeyword => 'of';

  @override
  String get usersKeyword => 'users';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get tryDifferentSearch => 'Try a different search or filter';

  @override
  String get addFirstUserAbove => 'Add your first user above';

  @override
  String get deleteUserTitle => 'Delete User';

  @override
  String get deletePromptPrefix => 'Delete';

  @override
  String get deletePromptSuffix => '? This action cannot be undone.';

  @override
  String get deleteAction => 'Delete';

  @override
  String get editUserTitle => 'Edit User';

  @override
  String get createNewUserTitle => 'Create New User';

  @override
  String get updateRoleDetails => 'Update role or contact details.';

  @override
  String get registerNewUser => 'Register a new user in the system.';

  @override
  String get emailAddressLabel => 'Email Address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get displayNameLabel => 'Display Name';

  @override
  String get payRateLabel => 'Pay Rate';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get createUserAction => 'Create User';

  @override
  String get todaysCleaningsTitle => 'Today\'s Cleanings';

  @override
  String get assignmentDetailsTitle => 'Assignment Details';

  @override
  String get selectCleanerLabel => 'Select Cleaner';

  @override
  String get selectInspectorLabel => 'Select Inspector (Optional)';

  @override
  String get managerObservationsLabel => 'Manager observations for cleaner';

  @override
  String get propertyCleaningFeeLabel =>
      'Property Cleaning Fee (Charged to Owner)';

  @override
  String get propertyInstructionsLabel => 'Property Instructions';

  @override
  String get cleanerIncidentsLabel => 'Cleaner Reported Incidents';

  @override
  String get cancelCleaningAction => 'Cancel Cleaning';

  @override
  String get createAssignmentAction => 'Create Assignment';

  @override
  String get pleaseSelectCleanerError => 'Please select a cleaner';

  @override
  String get ownerPortalTitle => 'Owner Portal';

  @override
  String welcomeMessage(String username) {
    return 'Welcome, $username';
  }

  @override
  String assignedPropertiesCount(int count) {
    return 'You have $count properties assigned.';
  }

  @override
  String get noAssignedPropertiesDesc =>
      'You do not have any properties assigned to your account yet.';

  @override
  String get viewOnMapsTooltip => 'View on Maps';

  @override
  String get cleaningActivityTitle => 'Cleaning Activity';

  @override
  String noCleaningsScheduledFor(String month) {
    return 'No cleanings scheduled for $month';
  }

  @override
  String errorLoadingActivity(String error) {
    return 'Error loading activity: $error';
  }

  @override
  String notePrefix(String note) {
    return 'Note: $note';
  }

  @override
  String incidentsReportedCount(int count) {
    return '$count Incident(s) Reported';
  }

  @override
  String get inspectorFindingsLabel => 'Inspector Findings:';

  @override
  String get checkoutEvidenceTitle => 'Checkout Evidence';

  @override
  String get checkoutVerificationTitle => 'Checkout Verification';

  @override
  String get requiredChecklistTitle => 'Required Checklist';

  @override
  String get verifyTasksDesc =>
      'Please verify the following tasks have been completed before finishing this job.';

  @override
  String get photoEvidenceRequiredTitle => 'Photo Evidence Required';

  @override
  String get capturePhotosDesc =>
      'Please capture at least 1 (up to 3) photos to prove completion.';

  @override
  String get completeJobAction => 'Complete Job';

  @override
  String get myPendingAssignmentsTitle => 'My Pending Assignments';

  @override
  String get noPendingAssignmentsDesc => 'No pending assignments.';

  @override
  String genericError(String error) {
    return 'Error: $error';
  }

  @override
  String get activeJobBadge => 'ACTIVE JOB';

  @override
  String get managerNotesLabel => 'Manager Notes';

  @override
  String get cleaningInstructionsLabel => 'Cleaning Instructions';

  @override
  String get reportIncidentAction => 'Report Incident';

  @override
  String get finishJobAction => 'Finish Job';

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusPendingInspection => 'Pending Inspection';

  @override
  String get statusFixNeeded => 'Fix Needed';

  @override
  String get statusApprovedCompleted => 'Approved (Completed)';

  @override
  String get statusLabel => 'Status';

  @override
  String inspectorLabel(Object name) {
    return 'Inspector: $name';
  }

  @override
  String get checkInBadge => 'CHECK-IN';

  @override
  String get checkOutBadge => 'CHECK-OUT';

  @override
  String get reservedLabel => 'Reserved';

  @override
  String checkoutDateLabel(String date) {
    return 'Checkout: $date';
  }

  @override
  String assignedDateLabel(String date) {
    return 'Assigned: $date';
  }

  @override
  String get inspectorFindingsFixLabel =>
      '⚠ Inspector Findings requiring fixing:';

  @override
  String get startJobAction => 'Start Job';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get addPhotoAction => 'Add Photo';

  @override
  String get submitReportAction => 'Submit Report';

  @override
  String get todaysInspectionsTitle => 'Today\'\'s Inspections';

  @override
  String get pendingInspectionsTitle => 'Pending Inspections';

  @override
  String get noPendingInspectionsDesc => 'No pending inspections.';

  @override
  String get statusWaitingForCleaner => 'Waiting for Cleaner...';

  @override
  String get statusReadyForInspection => 'Ready for Inspection';

  @override
  String get statusCleanerFixingIssues => 'Cleaner is fixing issues...';

  @override
  String get statusApproved => 'Approved';

  @override
  String cleanerLabel(String name) {
    return 'Cleaner: $name';
  }

  @override
  String finishedAtLabel(String date) {
    return 'Finished at: $date';
  }

  @override
  String get checkoutEvidenceLabel => 'Checkout Evidence:';

  @override
  String get reportedIncidentsLabel => 'Reported Incidents:';

  @override
  String get inspectorFindingsNotesLabel => 'Inspector Findings / Notes:';

  @override
  String get noTextObservationDesc => 'No text observation';

  @override
  String get declineFixNeededAction => 'Decline (Fix Needed)';

  @override
  String get approveAction => 'Approve';

  @override
  String get addApprovalNotesTitle => 'Add Approval Notes (Optional)';

  @override
  String get reportFindingsFixNeededTitle => 'Report Findings (Fix Needed)';

  @override
  String get notesLabel => 'Notes';

  @override
  String get descriptionOfIssuesLabel => 'Description of issues';

  @override
  String get provideTextOrPhotoError =>
      'Please provide text or photo to decline';

  @override
  String get approveJobAction => 'Approve Job';

  @override
  String get sendToFixAction => 'Send to Fix';

  @override
  String get payrollDashboardTitle => 'Payroll Dashboard';

  @override
  String get weeklyEarningsTitle => 'Weekly Earnings';

  @override
  String get noApprovedJobsThisWeek =>
      'No approved cleaning jobs for this week.';

  @override
  String get unknownCleanerLabel => 'Unknown Cleaner';

  @override
  String jobsCompletedLabel(int count) {
    return '$count jobs completed';
  }

  @override
  String get teamInboxTitle => 'Inbox';

  @override
  String get cleanersChannel => 'Cleaners Channel';

  @override
  String get inspectorsChannel => 'Inspectors Channel';

  @override
  String get generalChannel => 'General';

  @override
  String get directMessages => 'Direct Messages';

  @override
  String get noActiveCompanyFound => 'No active company found.';

  @override
  String get markAllAsReadAction => 'Mark all as read';

  @override
  String get noMessagesYetDesc => 'No messages yet. Say hello!';

  @override
  String get typeMessageHint => 'Type a message…';

  @override
  String get advancedReportsTitle => 'Advanced Reports';

  @override
  String get advancedAnalyticsTitle => 'Advanced Analytics';

  @override
  String diamondTierReportingLabel(int year) {
    return 'Diamond-Tier Reporting · $year';
  }

  @override
  String get totalCleaningsLabel => 'Total Cleanings';

  @override
  String get totalRevenueLabel => 'Total Revenue';

  @override
  String get totalPayrollLabel => 'Total Payroll';

  @override
  String get netMarginLabel => 'Net Margin';

  @override
  String get monthlyCleaningsTitle => 'Monthly Cleanings';

  @override
  String get monthlyCleaningsDesc => 'Completed and approved cleans per month';

  @override
  String get noCleaningDataForYear => 'No cleaning data for this year.';

  @override
  String get revenueVsPayrollTitle => 'Revenue vs Payroll';

  @override
  String get revenueVsPayrollDesc =>
      'Monthly comparison of gross revenue and total payroll cost';

  @override
  String get revenueLabel => 'Revenue';

  @override
  String get payrollLabel => 'Payroll';

  @override
  String get cleanerPerformanceTitle => 'Cleaner Performance';

  @override
  String get cleanerPerformanceDesc =>
      'Revenue generated vs payroll cost per cleaner';

  @override
  String get noCleanerDataForYear => 'No cleaner data for this year.';

  @override
  String get cleanerHeader => 'Cleaner';

  @override
  String get jobsHeader => 'Jobs';

  @override
  String get revenueHeader => 'Revenue';

  @override
  String get payrollHeader => 'Payroll';

  @override
  String get marginHeader => 'Margin';

  @override
  String get myEarningsTitle => 'My Earnings';

  @override
  String get thisWeekTitle => 'This Week';

  @override
  String get lastWeekTitle => 'Last Week';

  @override
  String propertiesCleanedLabel(int count) {
    return '$count properties cleaned';
  }

  @override
  String comparedToLastWeekLabel(String diff) {
    return '$diff compared to last week';
  }

  @override
  String get thisWeeksDetailsTitle => 'This Week\'s Details';

  @override
  String get noCompletedCleaningsThisWeekDesc =>
      'No completed cleanings this week.';

  @override
  String get propertiesTitle => 'Properties';

  @override
  String get generateDummyProperty => 'Generate Dummy Property (Test)';

  @override
  String get addPropertyAction => 'Add Property';

  @override
  String get limitReached => 'Limit Reached';

  @override
  String get searchPropertiesHint =>
      'Search by name, address, owner, or management...';

  @override
  String get cityLabel => 'City';

  @override
  String get allCitiesFilter => 'All Cities';

  @override
  String get propertyManagementLabel => 'Property Management';

  @override
  String get allFilter => 'All';

  @override
  String get propertiesKeyword => 'properties';

  @override
  String get noPropertiesFound => 'No properties found';

  @override
  String get tryAdjustingSearchFilters =>
      'Try adjusting your search or filters';

  @override
  String get deletePropertyTitle => 'Delete Property';

  @override
  String deletePropertyPrompt(String propertyName) {
    return 'Delete \"$propertyName\"? This cannot be undone.';
  }

  @override
  String get stepBasic => 'Basic';

  @override
  String get stepLocationDetails => 'Location & Details';

  @override
  String get stepOwnerMgmt => 'Owner & Mgmt';

  @override
  String get stepAccessCleaning => 'Access & Cleaning';

  @override
  String get syncIdLabel => 'Sync ID / Slug';

  @override
  String get isCohostLabel => 'Is Co-Host?';

  @override
  String get isCohostHelper =>
      'Enable if your company manages this property but does not own it';

  @override
  String get assignToCompanyLabel => 'Assign to Company *';

  @override
  String get selectCompanyHint => 'Select company';

  @override
  String get generateAction => 'Generate';

  @override
  String get cleanerFeeLabel => 'Cleaner Fee';

  @override
  String get companyLabel => 'Company';

  @override
  String get propertyNameLabel => 'Property Name';

  @override
  String get propertyTypeLabel => 'Property Type';

  @override
  String get typeHouse => 'House';

  @override
  String get typeApartment => 'Apartment';

  @override
  String get typeOther => 'Other';

  @override
  String get streetAddressLabel => 'Street Address';

  @override
  String get stateProvinceLabel => 'State/Province';

  @override
  String get zipPostalCodeLabel => 'Zip/Postal Code';

  @override
  String get countryLabel => 'Country';

  @override
  String get cleaningFeeLabel => 'Cleaning Fee';

  @override
  String get sizeLabel => 'AxBxC (Rooms x Baths x Floors)';

  @override
  String get schedulingSettingsLabel => 'Scheduling Settings (Silver+)';

  @override
  String get recurringCleanCadenceLabel => 'Recurring Clean Cadence';

  @override
  String get cadenceNone => 'None (Ad-hoc)';

  @override
  String get cadenceWeekly => 'Weekly';

  @override
  String get cadenceBiWeekly => 'Bi-Weekly';

  @override
  String get cadenceMonthly => 'Monthly';

  @override
  String get trashDayLabel => 'Trash Day';

  @override
  String get trashDayNone => 'None';

  @override
  String get trashDayMonday => 'Monday';

  @override
  String get trashDayTuesday => 'Tuesday';

  @override
  String get trashDayWednesday => 'Wednesday';

  @override
  String get trashDayThursday => 'Thursday';

  @override
  String get trashDayFriday => 'Friday';

  @override
  String get trashDaySaturday => 'Saturday';

  @override
  String get trashDaySunday => 'Sunday';

  @override
  String get bufferHoursLabel => 'Buffer Hours';

  @override
  String get bufferHoursHint => 'Hours required before next checkin';

  @override
  String get linkedOwnerAccountLabel => 'Linked Owner Account (Optional)';

  @override
  String get linkedOwnerAccountHelper =>
      'Links this property to a specific Property Owner dashboard';

  @override
  String get noneUnassigned => 'None / Unassigned';

  @override
  String get ownerNameLegacyLabel => 'Owner Name (For Reference)';

  @override
  String get propertyManagementCompanyLabel => 'Property Management Company';

  @override
  String get lockBoxPinLabel => 'Lock Box Pin';

  @override
  String get housePinLabel => 'House Pin';

  @override
  String get garagePinLabel => 'Garage Pin';

  @override
  String get customCleaningChecklistsTitle => 'Custom Cleaning Checklists';

  @override
  String get addChecklistItemHint => 'Add a new mandatory checklist item...';

  @override
  String get addChecklistItemTooltip => 'Add Checklist Item';

  @override
  String get addInstructionPhotoAction => 'Add Instruction Photo';

  @override
  String get editPropertyTitle => 'Edit Property';

  @override
  String get addNewPropertyTitle => 'Add New Property';

  @override
  String get setupPropertyDetailsDesc =>
      'Complete the steps below to setup the property details.';

  @override
  String get savePropertyAction => 'Save Property';

  @override
  String get continueAction => 'Continue';

  @override
  String get backAction => 'Back';

  @override
  String get pleaseSelectCompanyError =>
      'Please select a company for this property.';

  @override
  String get expressSaveAction => 'Express Save';

  @override
  String get propertyNameRequiredError =>
      'Property Name is required for Express Save.';

  @override
  String get subscriptionLimitReachedTitle => 'Subscription Limit Reached';

  @override
  String subscriptionLimitReachedDesc(int limit) {
    return 'Your current plan limits you to $limit properties. Please upgrade your subscription to add more properties.';
  }

  @override
  String get upgradePlanAction => 'Upgrade Plan';

  @override
  String get cleaningFeeSuffix => 'cleaning fee';

  @override
  String get lockPrefix => 'Lock:';

  @override
  String get housePrefix => 'House:';

  @override
  String get garagePrefix => 'Garage:';

  @override
  String get settingsTabLabel => 'Settings';

  @override
  String get feedbackTabLabel => 'Feedback';

  @override
  String get noFeedbackLabel => 'No operational feedback yet.';

  @override
  String get englishToggle => 'English (US)';

  @override
  String get spanishToggle => 'Español (ES)';

  @override
  String get confirmPlanChangeTitle => 'Confirm Plan Change';

  @override
  String confirmPlanChangeDesc(String planName) {
    return 'Are you sure you want to change your subscription to the $planName plan?';
  }

  @override
  String get confirmAction => 'Confirm';

  @override
  String successfullyUpdatedPlan(String planName) {
    return 'Successfully updated plan to $planName';
  }

  @override
  String errorUpdatingPlan(String error) {
    return 'Error updating plan: $error';
  }

  @override
  String get noActiveCompanySelected => 'No active company selected.';

  @override
  String get companyDataNotFound => 'Company data not found.';

  @override
  String get currentPlanLabel => 'CURRENT PLAN';

  @override
  String get planSuffix => 'Plan';

  @override
  String get activeUsersLabel => 'Active Users';

  @override
  String get availablePlansTitle => 'Available Plans';

  @override
  String get availablePlansDesc =>
      'Choose the perfect plan for your business needs. Upgrade or downgrade at any time.';

  @override
  String get unlimitedCount => '/ Unlimited';

  @override
  String get perMonthLabel => '/ month';

  @override
  String get currentPlanButton => 'Current Plan';

  @override
  String get downgradeAction => 'Downgrade';

  @override
  String get mostPopularBadge => 'MOST POPULAR';

  @override
  String get planFeatureBronze1 => 'Up to 5 Properties';

  @override
  String get planFeatureBronze2 => 'Up to 2 Users';

  @override
  String get planFeatureBronze3 => 'Mobile App Access';

  @override
  String get planFeatureBronze4 => 'Photo Evidence (3/clean)';

  @override
  String get planFeatureBronze5 => 'Basic Property Data';

  @override
  String get planFeatureSilver1 => 'Up to 15 Properties';

  @override
  String get planFeatureSilver2 => 'Up to 10 Users';

  @override
  String get planFeatureSilver3 => 'Team Roles (Cleaner vs Manager)';

  @override
  String get planFeatureGold1 => 'Up to 40 Properties';

  @override
  String get planFeatureGold2 => 'Up to 12 Users';

  @override
  String get planFeatureGold3 => 'Payroll Module & Reports';

  @override
  String get planFeatureGold4 => 'Owner Portal';

  @override
  String get planFeatureGold5 => 'Inspector Role';

  @override
  String get planFeaturePlatinum1 => 'Up to 100 Properties';

  @override
  String get planFeaturePlatinum2 => 'Up to 50 Users';

  @override
  String get planFeaturePlatinum3 => 'Multi-Currency Billing';

  @override
  String get planFeatureDiamond1 => 'Unlimited Properties';

  @override
  String get planFeatureDiamond2 => 'Unlimited Users';

  @override
  String get planFeatureDiamond3 => 'White Labeling';

  @override
  String get planFeatureDiamond4 => 'Advanced Analytics';

  @override
  String get planFeatureDiamond5 => 'Priority WhatsApp Support';

  @override
  String get planFeatureFree1 => '1 Property Only';

  @override
  String get planFeatureFree2 => '1 User Only (Admin)';

  @override
  String get planFeatureFree3 => 'Basic Calendar View';

  @override
  String get planFeatureFree4 => 'Standard Checklists';

  @override
  String get planFeatureFree5 => 'Manual Status Updates';

  @override
  String get addCleanerAction => 'Add Cleaner';

  @override
  String get mainCleanerLabel => 'Main Cleaner';

  @override
  String get assistantCleanerLabel => 'Assistant';

  @override
  String individualFeeLabel(String name) {
    return 'Fee for $name';
  }

  @override
  String get assistantPermissionNotice =>
      'Assistant Role: Only the Main Cleaner can start or finish this job.';

  @override
  String get myPaymentsTitle => 'My Payments';

  @override
  String get paymentHistoryTab => 'Payment History';

  @override
  String get payoutSettingsTab => 'Payout Settings';

  @override
  String get paymentPreferencesSaved =>
      'Payment preferences saved successfully.';

  @override
  String get payoutQuestion => 'How would you like to get paid?';

  @override
  String get bankTransferOption => 'Bank';

  @override
  String get bankNameLabel => 'Bank Name';

  @override
  String get savingsAccountLabel => 'Savings Account number';

  @override
  String get cciLabel => 'CCI (Interbank Code)';

  @override
  String registeredPhoneLabel(String provider) {
    return 'Registered Phone Number for $provider';
  }

  @override
  String get savePaymentInfoAction => 'Save Payment Information';

  @override
  String get viewProofAction => 'View Proof';

  @override
  String paidOnLabel(String date) {
    return 'Paid on $date';
  }

  @override
  String get noPaymentHistoryDesc => 'No payment history found.';

  @override
  String get registerButton => 'Register';

  @override
  String get leadRegistrationTitle => 'Join Calbnb';

  @override
  String get leadRegistrationSubtitle =>
      'Tell us about your company and we\'ll get in contact to help you set up.';

  @override
  String get leadNameLabel => 'Company Name / Your Name';

  @override
  String get contactPreferenceLabel => 'How should we contact you?';

  @override
  String get emailOption => 'Email';

  @override
  String get whatsappOption => 'WhatsApp';

  @override
  String get countryPickerLabel => 'Country Code';

  @override
  String get phoneNumberPlaceholder => 'Phone Number (including country code)';

  @override
  String get emailPlaceholder => 'Your Email Address';

  @override
  String get submitLeadButton => 'Submit Interest';

  @override
  String get leadSubmittedSuccess =>
      'Thank you! We received your request and will contact you soon.';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get superAdminLeadsMenu => 'Customer Leads';

  @override
  String get superAdminSupportMenu => 'Support Tickets';

  @override
  String get leadContactTemplateEmailTitle => 'Calbnb: Setting up your account';

  @override
  String leadContactTemplateWhatsApp(Object name) {
    return 'Hi $name! I\'m the Calbnb admin. I saw you\'re interested in our platform. To set up your account, please provide the name of your company and the URL of your Airbnb property or your current calendar sync link (Lodgify, etc.).';
  }

  @override
  String get supportTitle => 'Contact Support';

  @override
  String get supportSubtitle =>
      'Describe your issue and our team will help you shortly.';

  @override
  String get newTicketButton => 'New Support Ticket';

  @override
  String get noTicketsMessage => 'No support tickets yet.';

  @override
  String get ticketStatusOpen => 'Open';

  @override
  String get ticketStatusClosed => 'Resolved';

  @override
  String get deleteTicketConfirm =>
      'Are you sure you want to delete this conversation?';

  @override
  String get priorityTicketLabel => 'Priority Support';
}
