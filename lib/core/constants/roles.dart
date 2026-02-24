enum AppRole {
  superAdmin('Super Admin'),
  administrator('Administrator'),
  manager('Manager'),
  cleaner('Cleaner'),
  inspector('Inspector');

  final String displayName;
  const AppRole(this.displayName);
}
