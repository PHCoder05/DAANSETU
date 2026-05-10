import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';

final inventoryProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getInventory();
  if (response.statusCode == 200) {
    return response.data['data'] as List? ?? [];
  }
  return [];
});
