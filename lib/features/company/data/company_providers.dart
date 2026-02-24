import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';

/// Convenience provider — returns the current user's companyId or null.
final companyIdProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider)?.companyId;
});
