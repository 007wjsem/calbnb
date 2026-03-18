enum AppRole {
  superAdmin('Super Admin'),
  administrator('Administrator'),
  manager('Manager'),
  cleaner('Cleaner'),
  inspector('Inspector'),
  owner('Property Owner');

  final String displayName;
  const AppRole(this.displayName);
}
