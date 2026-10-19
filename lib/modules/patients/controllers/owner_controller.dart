export 'owner_detail_controller.dart';
export 'owners_list_controller.dart';

import 'owner_detail_controller.dart';

/// Legacy facade for backwards compatibility with any remaining references.
class OwnerController extends OwnerDetailController {
  OwnerController(super.petRepo, super.financialRepo);

  Future<void> loadOwners() async {
    await loadOwnerData();
  }
}
