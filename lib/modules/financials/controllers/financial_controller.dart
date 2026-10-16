import 'financial_dashboard_controller.dart';
import 'owner_statement_controller.dart';

export 'financial_dashboard_controller.dart';
export 'owner_statement_controller.dart';

/// Backward-compatible class for FinancialController
class FinancialController extends FinancialDashboardController {
  FinancialController(super.repo, super.petRepo);
}

typedef OwnerAccountStatementController = OwnerStatementController;
