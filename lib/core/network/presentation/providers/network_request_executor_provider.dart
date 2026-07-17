import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/network_request_executor.dart';

final networkRequestExecutorProvider = Provider<NetworkRequestExecutor>((ref) {
  return const NetworkRequestExecutor();
});
