import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'CalBNB'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access your portal.'**
  String get loginSubtitle;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'CalBNB'**
  String get dashboardTitle;

  /// No description provided for @calendarTab.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTab;

  /// No description provided for @metricsTab.
  ///
  /// In en, this message translates to:
  /// **'Metrics'**
  String get metricsTab;

  /// No description provided for @reportsTab.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTab;

  /// No description provided for @companiesTab.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get companiesTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logoutButton;

  /// No description provided for @systemAdministration.
  ///
  /// In en, this message translates to:
  /// **'System Administration'**
  String get systemAdministration;

  /// No description provided for @mainMenu.
  ///
  /// In en, this message translates to:
  /// **'MAIN MENU'**
  String get mainMenu;

  /// No description provided for @assignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get assignments;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @teamInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get teamInbox;

  /// No description provided for @myEarnings.
  ///
  /// In en, this message translates to:
  /// **'My Earnings'**
  String get myEarnings;

  /// No description provided for @administration.
  ///
  /// In en, this message translates to:
  /// **'ADMINISTRATION'**
  String get administration;

  /// No description provided for @cleanings.
  ///
  /// In en, this message translates to:
  /// **'Cleanings'**
  String get cleanings;

  /// No description provided for @inspections.
  ///
  /// In en, this message translates to:
  /// **'Inspections'**
  String get inspections;

  /// No description provided for @payroll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get payroll;

  /// No description provided for @billingAndPlan.
  ///
  /// In en, this message translates to:
  /// **'Billing & Plan'**
  String get billingAndPlan;

  /// No description provided for @advancedReports.
  ///
  /// In en, this message translates to:
  /// **'Advanced Reports'**
  String get advancedReports;

  /// No description provided for @management.
  ///
  /// In en, this message translates to:
  /// **'MANAGEMENT'**
  String get management;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @properties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get properties;

  /// No description provided for @monthlyCalendar.
  ///
  /// In en, this message translates to:
  /// **'Monthly Calendar'**
  String get monthlyCalendar;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @todaysActivities.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Activities'**
  String get todaysActivities;

  /// No description provided for @noActivities.
  ///
  /// In en, this message translates to:
  /// **'No activities for this date.'**
  String get noActivities;

  /// No description provided for @filterByProperty.
  ///
  /// In en, this message translates to:
  /// **'Filter by Property'**
  String get filterByProperty;

  /// No description provided for @noPropertiesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No properties available'**
  String get noPropertiesAvailable;

  /// No description provided for @loadingCalendarData.
  ///
  /// In en, this message translates to:
  /// **'Loading Calendar Data...'**
  String get loadingCalendarData;

  /// No description provided for @addBlockedDate.
  ///
  /// In en, this message translates to:
  /// **'Add Blocked Date'**
  String get addBlockedDate;

  /// No description provided for @selectProperty.
  ///
  /// In en, this message translates to:
  /// **'Select Property'**
  String get selectProperty;

  /// No description provided for @reasonPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Reason (e.g., Maintenance)'**
  String get reasonPlaceholder;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @allProperties.
  ///
  /// In en, this message translates to:
  /// **'All Properties'**
  String get allProperties;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get profileUpdated;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get errorOccurred;

  /// No description provided for @pwdMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get pwdMinLength;

  /// No description provided for @pwdMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get pwdMismatch;

  /// No description provided for @pwdUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully.'**
  String get pwdUpdated;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInfo;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contactDetails;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @emergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get emergencyContact;

  /// No description provided for @emergencyHint.
  ///
  /// In en, this message translates to:
  /// **'Name & number'**
  String get emergencyHint;

  /// No description provided for @saveContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Save Contact Info'**
  String get saveContactInfo;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @systemSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get systemSettingsTitle;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data:'**
  String get errorLoadingData;

  /// No description provided for @propertyOrderSaved.
  ///
  /// In en, this message translates to:
  /// **'Property order saved successfully.'**
  String get propertyOrderSaved;

  /// No description provided for @errorSavingPropertyOrder.
  ///
  /// In en, this message translates to:
  /// **'Error saving property order:'**
  String get errorSavingPropertyOrder;

  /// No description provided for @currencySettings.
  ///
  /// In en, this message translates to:
  /// **'Currency Settings'**
  String get currencySettings;

  /// No description provided for @platinumTier.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get platinumTier;

  /// No description provided for @currencySettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Set the currency used across payroll, earnings, and fees.'**
  String get currencySettingsDesc;

  /// No description provided for @activeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Active Currency'**
  String get activeCurrency;

  /// No description provided for @applyCurrency.
  ///
  /// In en, this message translates to:
  /// **'Apply Currency'**
  String get applyCurrency;

  /// No description provided for @currencyUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Currency updated to'**
  String get currencyUpdatedTo;

  /// No description provided for @phoneCountryCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Country Code'**
  String get phoneCountryCodeLabel;

  /// No description provided for @phoneCountryCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Prepended to staff phone numbers when sending WhatsApp messages'**
  String get phoneCountryCodeHelper;

  /// No description provided for @whatsAppCleaningMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}! You have a cleaning assignment on {date} at {property}, {address}.'**
  String whatsAppCleaningMessage(
      String name, String date, String property, String address);

  /// No description provided for @messageCleanerOnWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Message Cleaner on WhatsApp'**
  String get messageCleanerOnWhatsApp;

  /// No description provided for @noPhoneOnFileError.
  ///
  /// In en, this message translates to:
  /// **'This cleaner has no phone number on file.'**
  String get noPhoneOnFileError;

  /// No description provided for @couldNotOpenWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp'**
  String get couldNotOpenWhatsApp;

  /// No description provided for @whiteLabelBranding.
  ///
  /// In en, this message translates to:
  /// **'White-Label Branding'**
  String get whiteLabelBranding;

  /// No description provided for @diamondTier.
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get diamondTier;

  /// No description provided for @whiteLabelDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload your company logo to replace the CalBNB branding across the app.'**
  String get whiteLabelDesc;

  /// No description provided for @chooseLogo.
  ///
  /// In en, this message translates to:
  /// **'Choose Logo'**
  String get chooseLogo;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @logoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Logo updated!'**
  String get logoUpdated;

  /// No description provided for @logoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Logo removed.'**
  String get logoRemoved;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @propertyDisplayOrder.
  ///
  /// In en, this message translates to:
  /// **'Property Display Order'**
  String get propertyDisplayOrder;

  /// No description provided for @propertyDisplayOrderDesc.
  ///
  /// In en, this message translates to:
  /// **'Drag and drop the properties below to rearrange how they appear in the system. Click \'Save Order\' when finished.'**
  String get propertyDisplayOrderDesc;

  /// No description provided for @saveOrder.
  ///
  /// In en, this message translates to:
  /// **'Save Order'**
  String get saveOrder;

  /// No description provided for @usersTitle.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersTitle;

  /// No description provided for @userLimitReachedPrefix.
  ///
  /// In en, this message translates to:
  /// **'User limit reached'**
  String get userLimitReachedPrefix;

  /// No description provided for @userLimitReachedSuffix.
  ///
  /// In en, this message translates to:
  /// **'Upgrade your plan to add more users.'**
  String get userLimitReachedSuffix;

  /// No description provided for @upgradeAction.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeAction;

  /// No description provided for @addUserAction.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUserAction;

  /// No description provided for @searchUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email or phone...'**
  String get searchUsersHint;

  /// No description provided for @allRolesFilter.
  ///
  /// In en, this message translates to:
  /// **'All Roles'**
  String get allRolesFilter;

  /// No description provided for @ofKeyword.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get ofKeyword;

  /// No description provided for @usersKeyword.
  ///
  /// In en, this message translates to:
  /// **'users'**
  String get usersKeyword;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or filter'**
  String get tryDifferentSearch;

  /// No description provided for @addFirstUserAbove.
  ///
  /// In en, this message translates to:
  /// **'Add your first user above'**
  String get addFirstUserAbove;

  /// No description provided for @deleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUserTitle;

  /// No description provided for @deletePromptPrefix.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deletePromptPrefix;

  /// No description provided for @deletePromptSuffix.
  ///
  /// In en, this message translates to:
  /// **'? This action cannot be undone.'**
  String get deletePromptSuffix;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @editUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUserTitle;

  /// No description provided for @createNewUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New User'**
  String get createNewUserTitle;

  /// No description provided for @updateRoleDetails.
  ///
  /// In en, this message translates to:
  /// **'Update role or contact details.'**
  String get updateRoleDetails;

  /// No description provided for @registerNewUser.
  ///
  /// In en, this message translates to:
  /// **'Register a new user in the system.'**
  String get registerNewUser;

  /// No description provided for @emailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayNameLabel;

  /// No description provided for @payRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay Rate'**
  String get payRateLabel;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @createUserAction.
  ///
  /// In en, this message translates to:
  /// **'Create User'**
  String get createUserAction;

  /// No description provided for @todaysCleaningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Cleanings'**
  String get todaysCleaningsTitle;

  /// No description provided for @assignmentDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Assignment Details'**
  String get assignmentDetailsTitle;

  /// No description provided for @selectCleanerLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Cleaner'**
  String get selectCleanerLabel;

  /// No description provided for @selectInspectorLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Inspector (Optional)'**
  String get selectInspectorLabel;

  /// No description provided for @managerObservationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Manager observations for cleaner'**
  String get managerObservationsLabel;

  /// No description provided for @propertyCleaningFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Property Cleaning Fee (Charged to Owner)'**
  String get propertyCleaningFeeLabel;

  /// No description provided for @propertyInstructionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Property Instructions'**
  String get propertyInstructionsLabel;

  /// No description provided for @cleanerIncidentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Cleaner Reported Incidents'**
  String get cleanerIncidentsLabel;

  /// No description provided for @cancelCleaningAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel Cleaning'**
  String get cancelCleaningAction;

  /// No description provided for @createAssignmentAction.
  ///
  /// In en, this message translates to:
  /// **'Create Assignment'**
  String get createAssignmentAction;

  /// No description provided for @pleaseSelectCleanerError.
  ///
  /// In en, this message translates to:
  /// **'Please select a cleaner'**
  String get pleaseSelectCleanerError;

  /// No description provided for @ownerPortalTitle.
  ///
  /// In en, this message translates to:
  /// **'Owner Portal'**
  String get ownerPortalTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {username}'**
  String welcomeMessage(String username);

  /// No description provided for @assignedPropertiesCount.
  ///
  /// In en, this message translates to:
  /// **'You have {count} properties assigned.'**
  String assignedPropertiesCount(int count);

  /// No description provided for @noAssignedPropertiesDesc.
  ///
  /// In en, this message translates to:
  /// **'You do not have any properties assigned to your account yet.'**
  String get noAssignedPropertiesDesc;

  /// No description provided for @viewOnMapsTooltip.
  ///
  /// In en, this message translates to:
  /// **'View on Maps'**
  String get viewOnMapsTooltip;

  /// No description provided for @cleaningActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Cleaning Activity'**
  String get cleaningActivityTitle;

  /// No description provided for @noCleaningsScheduledFor.
  ///
  /// In en, this message translates to:
  /// **'No cleanings scheduled for {month}'**
  String noCleaningsScheduledFor(String month);

  /// No description provided for @errorLoadingActivity.
  ///
  /// In en, this message translates to:
  /// **'Error loading activity: {error}'**
  String errorLoadingActivity(String error);

  /// No description provided for @notePrefix.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String notePrefix(String note);

  /// No description provided for @incidentsReportedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Incident(s) Reported'**
  String incidentsReportedCount(int count);

  /// No description provided for @inspectorFindingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Inspector Findings:'**
  String get inspectorFindingsLabel;

  /// No description provided for @checkoutEvidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout Evidence'**
  String get checkoutEvidenceTitle;

  /// No description provided for @checkoutVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout Verification'**
  String get checkoutVerificationTitle;

  /// No description provided for @requiredChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Required Checklist'**
  String get requiredChecklistTitle;

  /// No description provided for @verifyTasksDesc.
  ///
  /// In en, this message translates to:
  /// **'Please verify the following tasks have been completed before finishing this job.'**
  String get verifyTasksDesc;

  /// No description provided for @photoEvidenceRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo Evidence Required'**
  String get photoEvidenceRequiredTitle;

  /// No description provided for @capturePhotosDesc.
  ///
  /// In en, this message translates to:
  /// **'Please capture at least 1 (up to 3) photos to prove completion.'**
  String get capturePhotosDesc;

  /// No description provided for @completeJobAction.
  ///
  /// In en, this message translates to:
  /// **'Complete Job'**
  String get completeJobAction;

  /// No description provided for @myPendingAssignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Pending Assignments'**
  String get myPendingAssignmentsTitle;

  /// No description provided for @noPendingAssignmentsDesc.
  ///
  /// In en, this message translates to:
  /// **'No pending assignments.'**
  String get noPendingAssignmentsDesc;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String genericError(String error);

  /// No description provided for @activeJobBadge.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE JOB'**
  String get activeJobBadge;

  /// No description provided for @managerNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Manager Notes'**
  String get managerNotesLabel;

  /// No description provided for @cleaningInstructionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Cleaning Instructions'**
  String get cleaningInstructionsLabel;

  /// No description provided for @reportIncidentAction.
  ///
  /// In en, this message translates to:
  /// **'Report Incident'**
  String get reportIncidentAction;

  /// No description provided for @finishJobAction.
  ///
  /// In en, this message translates to:
  /// **'Finish Job'**
  String get finishJobAction;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusPendingInspection.
  ///
  /// In en, this message translates to:
  /// **'Pending Inspection'**
  String get statusPendingInspection;

  /// No description provided for @statusFixNeeded.
  ///
  /// In en, this message translates to:
  /// **'Fix Needed'**
  String get statusFixNeeded;

  /// No description provided for @statusApprovedCompleted.
  ///
  /// In en, this message translates to:
  /// **'Approved (Completed)'**
  String get statusApprovedCompleted;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @inspectorLabel.
  ///
  /// In en, this message translates to:
  /// **'Inspector: {name}'**
  String inspectorLabel(Object name);

  /// No description provided for @checkInBadge.
  ///
  /// In en, this message translates to:
  /// **'CHECK-IN'**
  String get checkInBadge;

  /// No description provided for @checkOutBadge.
  ///
  /// In en, this message translates to:
  /// **'CHECK-OUT'**
  String get checkOutBadge;

  /// No description provided for @reservedLabel.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get reservedLabel;

  /// No description provided for @checkoutDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Checkout: {date}'**
  String checkoutDateLabel(String date);

  /// No description provided for @assignedDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned: {date}'**
  String assignedDateLabel(String date);

  /// No description provided for @inspectorFindingsFixLabel.
  ///
  /// In en, this message translates to:
  /// **'⚠ Inspector Findings requiring fixing:'**
  String get inspectorFindingsFixLabel;

  /// No description provided for @startJobAction.
  ///
  /// In en, this message translates to:
  /// **'Start Job'**
  String get startJobAction;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @addPhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhotoAction;

  /// No description provided for @submitReportAction.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReportAction;

  /// No description provided for @todaysInspectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'\'s Inspections'**
  String get todaysInspectionsTitle;

  /// No description provided for @pendingInspectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Inspections'**
  String get pendingInspectionsTitle;

  /// No description provided for @noPendingInspectionsDesc.
  ///
  /// In en, this message translates to:
  /// **'No pending inspections.'**
  String get noPendingInspectionsDesc;

  /// No description provided for @statusWaitingForCleaner.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Cleaner...'**
  String get statusWaitingForCleaner;

  /// No description provided for @statusReadyForInspection.
  ///
  /// In en, this message translates to:
  /// **'Ready for Inspection'**
  String get statusReadyForInspection;

  /// No description provided for @statusCleanerFixingIssues.
  ///
  /// In en, this message translates to:
  /// **'Cleaner is fixing issues...'**
  String get statusCleanerFixingIssues;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @cleanerLabel.
  ///
  /// In en, this message translates to:
  /// **'Cleaner: {name}'**
  String cleanerLabel(String name);

  /// No description provided for @finishedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Finished at: {date}'**
  String finishedAtLabel(String date);

  /// No description provided for @checkoutEvidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Checkout Evidence:'**
  String get checkoutEvidenceLabel;

  /// No description provided for @reportedIncidentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reported Incidents:'**
  String get reportedIncidentsLabel;

  /// No description provided for @inspectorFindingsNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Inspector Findings / Notes:'**
  String get inspectorFindingsNotesLabel;

  /// No description provided for @noTextObservationDesc.
  ///
  /// In en, this message translates to:
  /// **'No text observation'**
  String get noTextObservationDesc;

  /// No description provided for @declineFixNeededAction.
  ///
  /// In en, this message translates to:
  /// **'Decline (Fix Needed)'**
  String get declineFixNeededAction;

  /// No description provided for @approveAction.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveAction;

  /// No description provided for @addApprovalNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Approval Notes (Optional)'**
  String get addApprovalNotesTitle;

  /// No description provided for @reportFindingsFixNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Findings (Fix Needed)'**
  String get reportFindingsFixNeededTitle;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @descriptionOfIssuesLabel.
  ///
  /// In en, this message translates to:
  /// **'Description of issues'**
  String get descriptionOfIssuesLabel;

  /// No description provided for @provideTextOrPhotoError.
  ///
  /// In en, this message translates to:
  /// **'Please provide text or photo to decline'**
  String get provideTextOrPhotoError;

  /// No description provided for @approveJobAction.
  ///
  /// In en, this message translates to:
  /// **'Approve Job'**
  String get approveJobAction;

  /// No description provided for @sendToFixAction.
  ///
  /// In en, this message translates to:
  /// **'Send to Fix'**
  String get sendToFixAction;

  /// No description provided for @payrollDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Payroll Dashboard'**
  String get payrollDashboardTitle;

  /// No description provided for @weeklyEarningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Earnings'**
  String get weeklyEarningsTitle;

  /// No description provided for @noApprovedJobsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No approved cleaning jobs for this week.'**
  String get noApprovedJobsThisWeek;

  /// No description provided for @unknownCleanerLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown Cleaner'**
  String get unknownCleanerLabel;

  /// No description provided for @jobsCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} jobs completed'**
  String jobsCompletedLabel(int count);

  /// No description provided for @teamInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get teamInboxTitle;

  /// No description provided for @cleanersChannel.
  ///
  /// In en, this message translates to:
  /// **'Cleaners Channel'**
  String get cleanersChannel;

  /// No description provided for @inspectorsChannel.
  ///
  /// In en, this message translates to:
  /// **'Inspectors Channel'**
  String get inspectorsChannel;

  /// No description provided for @generalChannel.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalChannel;

  /// No description provided for @directMessages.
  ///
  /// In en, this message translates to:
  /// **'Direct Messages'**
  String get directMessages;

  /// No description provided for @noActiveCompanyFound.
  ///
  /// In en, this message translates to:
  /// **'No active company found.'**
  String get noActiveCompanyFound;

  /// No description provided for @markAllAsReadAction.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsReadAction;

  /// No description provided for @noMessagesYetDesc.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hello!'**
  String get noMessagesYetDesc;

  /// No description provided for @typeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get typeMessageHint;

  /// No description provided for @advancedReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Reports'**
  String get advancedReportsTitle;

  /// No description provided for @advancedAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Analytics'**
  String get advancedAnalyticsTitle;

  /// No description provided for @diamondTierReportingLabel.
  ///
  /// In en, this message translates to:
  /// **'Diamond-Tier Reporting · {year}'**
  String diamondTierReportingLabel(int year);

  /// No description provided for @totalCleaningsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Cleanings'**
  String get totalCleaningsLabel;

  /// No description provided for @totalRevenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenueLabel;

  /// No description provided for @totalPayrollLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Payroll'**
  String get totalPayrollLabel;

  /// No description provided for @netMarginLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Margin'**
  String get netMarginLabel;

  /// No description provided for @monthlyCleaningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Cleanings'**
  String get monthlyCleaningsTitle;

  /// No description provided for @monthlyCleaningsDesc.
  ///
  /// In en, this message translates to:
  /// **'Completed and approved cleans per month'**
  String get monthlyCleaningsDesc;

  /// No description provided for @noCleaningDataForYear.
  ///
  /// In en, this message translates to:
  /// **'No cleaning data for this year.'**
  String get noCleaningDataForYear;

  /// No description provided for @revenueVsPayrollTitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue vs Payroll'**
  String get revenueVsPayrollTitle;

  /// No description provided for @revenueVsPayrollDesc.
  ///
  /// In en, this message translates to:
  /// **'Monthly comparison of gross revenue and total payroll cost'**
  String get revenueVsPayrollDesc;

  /// No description provided for @revenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenueLabel;

  /// No description provided for @payrollLabel.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get payrollLabel;

  /// No description provided for @cleanerPerformanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Cleaner Performance'**
  String get cleanerPerformanceTitle;

  /// No description provided for @cleanerPerformanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Revenue generated vs payroll cost per cleaner'**
  String get cleanerPerformanceDesc;

  /// No description provided for @noCleanerDataForYear.
  ///
  /// In en, this message translates to:
  /// **'No cleaner data for this year.'**
  String get noCleanerDataForYear;

  /// No description provided for @cleanerHeader.
  ///
  /// In en, this message translates to:
  /// **'Cleaner'**
  String get cleanerHeader;

  /// No description provided for @jobsHeader.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobsHeader;

  /// No description provided for @revenueHeader.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenueHeader;

  /// No description provided for @payrollHeader.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get payrollHeader;

  /// No description provided for @marginHeader.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get marginHeader;

  /// No description provided for @myEarningsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Earnings'**
  String get myEarningsTitle;

  /// No description provided for @thisWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeekTitle;

  /// No description provided for @lastWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get lastWeekTitle;

  /// No description provided for @propertiesCleanedLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} properties cleaned'**
  String propertiesCleanedLabel(int count);

  /// No description provided for @comparedToLastWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'{diff} compared to last week'**
  String comparedToLastWeekLabel(String diff);

  /// No description provided for @thisWeeksDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'This Week\'s Details'**
  String get thisWeeksDetailsTitle;

  /// No description provided for @noCompletedCleaningsThisWeekDesc.
  ///
  /// In en, this message translates to:
  /// **'No completed cleanings this week.'**
  String get noCompletedCleaningsThisWeekDesc;

  /// No description provided for @propertiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get propertiesTitle;

  /// No description provided for @generateDummyProperty.
  ///
  /// In en, this message translates to:
  /// **'Generate Dummy Property (Test)'**
  String get generateDummyProperty;

  /// No description provided for @addPropertyAction.
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get addPropertyAction;

  /// No description provided for @limitReached.
  ///
  /// In en, this message translates to:
  /// **'Limit Reached'**
  String get limitReached;

  /// No description provided for @searchPropertiesHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, address, owner, or management...'**
  String get searchPropertiesHint;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @allCitiesFilter.
  ///
  /// In en, this message translates to:
  /// **'All Cities'**
  String get allCitiesFilter;

  /// No description provided for @propertyManagementLabel.
  ///
  /// In en, this message translates to:
  /// **'Property Management'**
  String get propertyManagementLabel;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @propertiesKeyword.
  ///
  /// In en, this message translates to:
  /// **'properties'**
  String get propertiesKeyword;

  /// No description provided for @noPropertiesFound.
  ///
  /// In en, this message translates to:
  /// **'No properties found'**
  String get noPropertiesFound;

  /// No description provided for @tryAdjustingSearchFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get tryAdjustingSearchFilters;

  /// No description provided for @deletePropertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Property'**
  String get deletePropertyTitle;

  /// No description provided for @deletePropertyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{propertyName}\"? This cannot be undone.'**
  String deletePropertyPrompt(String propertyName);

  /// No description provided for @stepBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get stepBasic;

  /// No description provided for @stepLocationDetails.
  ///
  /// In en, this message translates to:
  /// **'Location & Details'**
  String get stepLocationDetails;

  /// No description provided for @stepOwnerMgmt.
  ///
  /// In en, this message translates to:
  /// **'Owner & Mgmt'**
  String get stepOwnerMgmt;

  /// No description provided for @stepAccessCleaning.
  ///
  /// In en, this message translates to:
  /// **'Access & Cleaning'**
  String get stepAccessCleaning;

  /// No description provided for @syncIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Sync ID / Slug'**
  String get syncIdLabel;

  /// No description provided for @isCohostLabel.
  ///
  /// In en, this message translates to:
  /// **'Is Co-Host?'**
  String get isCohostLabel;

  /// No description provided for @isCohostHelper.
  ///
  /// In en, this message translates to:
  /// **'Enable if your company manages this property but does not own it'**
  String get isCohostHelper;

  /// No description provided for @assignToCompanyLabel.
  ///
  /// In en, this message translates to:
  /// **'Assign to Company *'**
  String get assignToCompanyLabel;

  /// No description provided for @selectCompanyHint.
  ///
  /// In en, this message translates to:
  /// **'Select company'**
  String get selectCompanyHint;

  /// No description provided for @generateAction.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generateAction;

  /// No description provided for @cleanerFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Cleaner Fee'**
  String get cleanerFeeLabel;

  /// No description provided for @companyLabel.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get companyLabel;

  /// No description provided for @propertyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Property Name'**
  String get propertyNameLabel;

  /// No description provided for @propertyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Property Type'**
  String get propertyTypeLabel;

  /// No description provided for @typeHouse.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get typeHouse;

  /// No description provided for @typeApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get typeApartment;

  /// No description provided for @typeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get typeOther;

  /// No description provided for @streetAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Street Address'**
  String get streetAddressLabel;

  /// No description provided for @stateProvinceLabel.
  ///
  /// In en, this message translates to:
  /// **'State/Province'**
  String get stateProvinceLabel;

  /// No description provided for @zipPostalCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Zip/Postal Code'**
  String get zipPostalCodeLabel;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// No description provided for @cleaningFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Cleaning Fee'**
  String get cleaningFeeLabel;

  /// No description provided for @sizeLabel.
  ///
  /// In en, this message translates to:
  /// **'AxBxC (Rooms x Baths x Floors)'**
  String get sizeLabel;

  /// No description provided for @schedulingSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Scheduling Settings (Silver+)'**
  String get schedulingSettingsLabel;

  /// No description provided for @recurringCleanCadenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Recurring Clean Cadence'**
  String get recurringCleanCadenceLabel;

  /// No description provided for @cadenceNone.
  ///
  /// In en, this message translates to:
  /// **'None (Ad-hoc)'**
  String get cadenceNone;

  /// No description provided for @cadenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get cadenceWeekly;

  /// No description provided for @cadenceBiWeekly.
  ///
  /// In en, this message translates to:
  /// **'Bi-Weekly'**
  String get cadenceBiWeekly;

  /// No description provided for @cadenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get cadenceMonthly;

  /// No description provided for @trashDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Trash Day'**
  String get trashDayLabel;

  /// No description provided for @trashDayNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get trashDayNone;

  /// No description provided for @trashDayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get trashDayMonday;

  /// No description provided for @trashDayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get trashDayTuesday;

  /// No description provided for @trashDayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get trashDayWednesday;

  /// No description provided for @trashDayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get trashDayThursday;

  /// No description provided for @trashDayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get trashDayFriday;

  /// No description provided for @trashDaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get trashDaySaturday;

  /// No description provided for @trashDaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get trashDaySunday;

  /// No description provided for @bufferHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Buffer Hours'**
  String get bufferHoursLabel;

  /// No description provided for @bufferHoursHint.
  ///
  /// In en, this message translates to:
  /// **'Hours required before next checkin'**
  String get bufferHoursHint;

  /// No description provided for @linkedOwnerAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked Owner Account (Optional)'**
  String get linkedOwnerAccountLabel;

  /// No description provided for @linkedOwnerAccountHelper.
  ///
  /// In en, this message translates to:
  /// **'Links this property to a specific Property Owner dashboard'**
  String get linkedOwnerAccountHelper;

  /// No description provided for @noneUnassigned.
  ///
  /// In en, this message translates to:
  /// **'None / Unassigned'**
  String get noneUnassigned;

  /// No description provided for @ownerNameLegacyLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner Name (For Reference)'**
  String get ownerNameLegacyLabel;

  /// No description provided for @propertyManagementCompanyLabel.
  ///
  /// In en, this message translates to:
  /// **'Property Management Company'**
  String get propertyManagementCompanyLabel;

  /// No description provided for @lockBoxPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Lock Box Pin'**
  String get lockBoxPinLabel;

  /// No description provided for @housePinLabel.
  ///
  /// In en, this message translates to:
  /// **'House Pin'**
  String get housePinLabel;

  /// No description provided for @garagePinLabel.
  ///
  /// In en, this message translates to:
  /// **'Garage Pin'**
  String get garagePinLabel;

  /// No description provided for @customCleaningChecklistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Cleaning Checklists'**
  String get customCleaningChecklistsTitle;

  /// No description provided for @addChecklistItemHint.
  ///
  /// In en, this message translates to:
  /// **'Add a new mandatory checklist item...'**
  String get addChecklistItemHint;

  /// No description provided for @addChecklistItemTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Checklist Item'**
  String get addChecklistItemTooltip;

  /// No description provided for @addInstructionPhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Add Instruction Photo'**
  String get addInstructionPhotoAction;

  /// No description provided for @editPropertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Property'**
  String get editPropertyTitle;

  /// No description provided for @addNewPropertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Property'**
  String get addNewPropertyTitle;

  /// No description provided for @setupPropertyDetailsDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the steps below to setup the property details.'**
  String get setupPropertyDetailsDesc;

  /// No description provided for @savePropertyAction.
  ///
  /// In en, this message translates to:
  /// **'Save Property'**
  String get savePropertyAction;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @backAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backAction;

  /// No description provided for @pleaseSelectCompanyError.
  ///
  /// In en, this message translates to:
  /// **'Please select a company for this property.'**
  String get pleaseSelectCompanyError;

  /// No description provided for @expressSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Express Save'**
  String get expressSaveAction;

  /// No description provided for @propertyNameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Property Name is required for Express Save.'**
  String get propertyNameRequiredError;

  /// No description provided for @subscriptionLimitReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription Limit Reached'**
  String get subscriptionLimitReachedTitle;

  /// No description provided for @subscriptionLimitReachedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your current plan limits you to {limit} properties. Please upgrade your subscription to add more properties.'**
  String subscriptionLimitReachedDesc(int limit);

  /// No description provided for @upgradePlanAction.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get upgradePlanAction;

  /// No description provided for @cleaningFeeSuffix.
  ///
  /// In en, this message translates to:
  /// **'cleaning fee'**
  String get cleaningFeeSuffix;

  /// No description provided for @lockPrefix.
  ///
  /// In en, this message translates to:
  /// **'Lock:'**
  String get lockPrefix;

  /// No description provided for @housePrefix.
  ///
  /// In en, this message translates to:
  /// **'House:'**
  String get housePrefix;

  /// No description provided for @garagePrefix.
  ///
  /// In en, this message translates to:
  /// **'Garage:'**
  String get garagePrefix;

  /// No description provided for @settingsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTabLabel;

  /// No description provided for @feedbackTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackTabLabel;

  /// No description provided for @noFeedbackLabel.
  ///
  /// In en, this message translates to:
  /// **'No operational feedback yet.'**
  String get noFeedbackLabel;

  /// No description provided for @englishToggle.
  ///
  /// In en, this message translates to:
  /// **'English (US)'**
  String get englishToggle;

  /// No description provided for @spanishToggle.
  ///
  /// In en, this message translates to:
  /// **'Español (ES)'**
  String get spanishToggle;

  /// No description provided for @confirmPlanChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Plan Change'**
  String get confirmPlanChangeTitle;

  /// No description provided for @confirmPlanChangeDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change your subscription to the {planName} plan?'**
  String confirmPlanChangeDesc(String planName);

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmAction;

  /// No description provided for @successfullyUpdatedPlan.
  ///
  /// In en, this message translates to:
  /// **'Successfully updated plan to {planName}'**
  String successfullyUpdatedPlan(String planName);

  /// No description provided for @errorUpdatingPlan.
  ///
  /// In en, this message translates to:
  /// **'Error updating plan: {error}'**
  String errorUpdatingPlan(String error);

  /// No description provided for @noActiveCompanySelected.
  ///
  /// In en, this message translates to:
  /// **'No active company selected.'**
  String get noActiveCompanySelected;

  /// No description provided for @companyDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'Company data not found.'**
  String get companyDataNotFound;

  /// No description provided for @currentPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'CURRENT PLAN'**
  String get currentPlanLabel;

  /// No description provided for @planSuffix.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planSuffix;

  /// No description provided for @activeUsersLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get activeUsersLabel;

  /// No description provided for @availablePlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Plans'**
  String get availablePlansTitle;

  /// No description provided for @availablePlansDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the perfect plan for your business needs. Upgrade or downgrade at any time.'**
  String get availablePlansDesc;

  /// No description provided for @unlimitedCount.
  ///
  /// In en, this message translates to:
  /// **'/ Unlimited'**
  String get unlimitedCount;

  /// No description provided for @perMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get perMonthLabel;

  /// No description provided for @currentPlanButton.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlanButton;

  /// No description provided for @downgradeAction.
  ///
  /// In en, this message translates to:
  /// **'Downgrade'**
  String get downgradeAction;

  /// No description provided for @mostPopularBadge.
  ///
  /// In en, this message translates to:
  /// **'MOST POPULAR'**
  String get mostPopularBadge;

  /// No description provided for @planFeatureBronze1.
  ///
  /// In en, this message translates to:
  /// **'Up to 5 Properties'**
  String get planFeatureBronze1;

  /// No description provided for @planFeatureBronze2.
  ///
  /// In en, this message translates to:
  /// **'Up to 2 Users'**
  String get planFeatureBronze2;

  /// No description provided for @planFeatureBronze3.
  ///
  /// In en, this message translates to:
  /// **'Mobile App Access'**
  String get planFeatureBronze3;

  /// No description provided for @planFeatureBronze4.
  ///
  /// In en, this message translates to:
  /// **'Photo Evidence (3/clean)'**
  String get planFeatureBronze4;

  /// No description provided for @planFeatureBronze5.
  ///
  /// In en, this message translates to:
  /// **'Basic Property Data'**
  String get planFeatureBronze5;

  /// No description provided for @planFeatureSilver1.
  ///
  /// In en, this message translates to:
  /// **'Up to 15 Properties'**
  String get planFeatureSilver1;

  /// No description provided for @planFeatureSilver2.
  ///
  /// In en, this message translates to:
  /// **'Up to 10 Users'**
  String get planFeatureSilver2;

  /// No description provided for @planFeatureSilver3.
  ///
  /// In en, this message translates to:
  /// **'Team Roles (Cleaner vs Manager)'**
  String get planFeatureSilver3;

  /// No description provided for @planFeatureGold1.
  ///
  /// In en, this message translates to:
  /// **'Up to 40 Properties'**
  String get planFeatureGold1;

  /// No description provided for @planFeatureGold2.
  ///
  /// In en, this message translates to:
  /// **'Up to 12 Users'**
  String get planFeatureGold2;

  /// No description provided for @planFeatureGold3.
  ///
  /// In en, this message translates to:
  /// **'Payroll Module & Reports'**
  String get planFeatureGold3;

  /// No description provided for @planFeatureGold4.
  ///
  /// In en, this message translates to:
  /// **'Owner Portal'**
  String get planFeatureGold4;

  /// No description provided for @planFeatureGold5.
  ///
  /// In en, this message translates to:
  /// **'Inspector Role'**
  String get planFeatureGold5;

  /// No description provided for @planFeaturePlatinum1.
  ///
  /// In en, this message translates to:
  /// **'Up to 100 Properties'**
  String get planFeaturePlatinum1;

  /// No description provided for @planFeaturePlatinum2.
  ///
  /// In en, this message translates to:
  /// **'Up to 50 Users'**
  String get planFeaturePlatinum2;

  /// No description provided for @planFeaturePlatinum3.
  ///
  /// In en, this message translates to:
  /// **'Multi-Currency Billing'**
  String get planFeaturePlatinum3;

  /// No description provided for @planFeatureDiamond1.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Properties'**
  String get planFeatureDiamond1;

  /// No description provided for @planFeatureDiamond2.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Users'**
  String get planFeatureDiamond2;

  /// No description provided for @planFeatureDiamond3.
  ///
  /// In en, this message translates to:
  /// **'White Labeling'**
  String get planFeatureDiamond3;

  /// No description provided for @planFeatureDiamond4.
  ///
  /// In en, this message translates to:
  /// **'Advanced Analytics'**
  String get planFeatureDiamond4;

  /// No description provided for @planFeatureDiamond5.
  ///
  /// In en, this message translates to:
  /// **'Priority WhatsApp Support'**
  String get planFeatureDiamond5;

  /// No description provided for @planFeatureFree1.
  ///
  /// In en, this message translates to:
  /// **'1 Property Only'**
  String get planFeatureFree1;

  /// No description provided for @planFeatureFree2.
  ///
  /// In en, this message translates to:
  /// **'1 User Only (Admin)'**
  String get planFeatureFree2;

  /// No description provided for @planFeatureFree3.
  ///
  /// In en, this message translates to:
  /// **'Basic Calendar View'**
  String get planFeatureFree3;

  /// No description provided for @planFeatureFree4.
  ///
  /// In en, this message translates to:
  /// **'Standard Checklists'**
  String get planFeatureFree4;

  /// No description provided for @planFeatureFree5.
  ///
  /// In en, this message translates to:
  /// **'Manual Status Updates'**
  String get planFeatureFree5;

  /// No description provided for @addCleanerAction.
  ///
  /// In en, this message translates to:
  /// **'Add Cleaner'**
  String get addCleanerAction;

  /// No description provided for @mainCleanerLabel.
  ///
  /// In en, this message translates to:
  /// **'Main Cleaner'**
  String get mainCleanerLabel;

  /// No description provided for @assistantCleanerLabel.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get assistantCleanerLabel;

  /// No description provided for @individualFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Fee for {name}'**
  String individualFeeLabel(String name);

  /// No description provided for @assistantPermissionNotice.
  ///
  /// In en, this message translates to:
  /// **'Assistant Role: Only the Main Cleaner can start or finish this job.'**
  String get assistantPermissionNotice;

  /// No description provided for @myPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Payments'**
  String get myPaymentsTitle;

  /// No description provided for @paymentHistoryTab.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistoryTab;

  /// No description provided for @payoutSettingsTab.
  ///
  /// In en, this message translates to:
  /// **'Payout Settings'**
  String get payoutSettingsTab;

  /// No description provided for @paymentPreferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Payment preferences saved successfully.'**
  String get paymentPreferencesSaved;

  /// No description provided for @payoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'How would you like to get paid?'**
  String get payoutQuestion;

  /// No description provided for @bankTransferOption.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bankTransferOption;

  /// No description provided for @bankNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankNameLabel;

  /// No description provided for @savingsAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Savings Account number'**
  String get savingsAccountLabel;

  /// No description provided for @cciLabel.
  ///
  /// In en, this message translates to:
  /// **'CCI (Interbank Code)'**
  String get cciLabel;

  /// No description provided for @registeredPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Registered Phone Number for {provider}'**
  String registeredPhoneLabel(String provider);

  /// No description provided for @savePaymentInfoAction.
  ///
  /// In en, this message translates to:
  /// **'Save Payment Information'**
  String get savePaymentInfoAction;

  /// No description provided for @viewProofAction.
  ///
  /// In en, this message translates to:
  /// **'View Proof'**
  String get viewProofAction;

  /// No description provided for @paidOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid on {date}'**
  String paidOnLabel(String date);

  /// No description provided for @noPaymentHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'No payment history found.'**
  String get noPaymentHistoryDesc;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @leadRegistrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Calbnb'**
  String get leadRegistrationTitle;

  /// No description provided for @leadRegistrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your company and we\'ll get in contact to help you set up.'**
  String get leadRegistrationSubtitle;

  /// No description provided for @leadNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Name / Your Name'**
  String get leadNameLabel;

  /// No description provided for @contactPreferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'How should we contact you?'**
  String get contactPreferenceLabel;

  /// No description provided for @emailOption.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailOption;

  /// No description provided for @whatsappOption.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsappOption;

  /// No description provided for @countryPickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Country Code'**
  String get countryPickerLabel;

  /// No description provided for @phoneNumberPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (including country code)'**
  String get phoneNumberPlaceholder;

  /// No description provided for @emailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your Email Address'**
  String get emailPlaceholder;

  /// No description provided for @submitLeadButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Interest'**
  String get submitLeadButton;

  /// No description provided for @leadSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Thank you! We received your request and will contact you soon.'**
  String get leadSubmittedSuccess;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @superAdminLeadsMenu.
  ///
  /// In en, this message translates to:
  /// **'Customer Leads'**
  String get superAdminLeadsMenu;

  /// No description provided for @superAdminSupportMenu.
  ///
  /// In en, this message translates to:
  /// **'Support Tickets'**
  String get superAdminSupportMenu;

  /// No description provided for @leadContactTemplateEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Calbnb: Setting up your account'**
  String get leadContactTemplateEmailTitle;

  /// No description provided for @leadContactTemplateWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}! I\'m the Calbnb admin. I saw you\'re interested in our platform. To set up your account, please provide the name of your company and the URL of your Airbnb property or your current calendar sync link (Lodgify, etc.).'**
  String leadContactTemplateWhatsApp(Object name);

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get supportTitle;

  /// No description provided for @supportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue and our team will help you shortly.'**
  String get supportSubtitle;

  /// No description provided for @newTicketButton.
  ///
  /// In en, this message translates to:
  /// **'New Support Ticket'**
  String get newTicketButton;

  /// No description provided for @noTicketsMessage.
  ///
  /// In en, this message translates to:
  /// **'No support tickets yet.'**
  String get noTicketsMessage;

  /// No description provided for @ticketStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get ticketStatusOpen;

  /// No description provided for @ticketStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get ticketStatusClosed;

  /// No description provided for @deleteTicketConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this conversation?'**
  String get deleteTicketConfirm;

  /// No description provided for @priorityTicketLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority Support'**
  String get priorityTicketLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
