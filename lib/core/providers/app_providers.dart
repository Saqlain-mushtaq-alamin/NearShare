import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/permission_service.dart';

/// Shared app-wide services.
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});
