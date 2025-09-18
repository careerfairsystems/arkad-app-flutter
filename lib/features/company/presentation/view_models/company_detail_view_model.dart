import 'package:flutter/foundation.dart';

import '../../../../shared/errors/app_error.dart';
import '../../domain/entities/company.dart';
import '../commands/get_company_by_id_command.dart';

/// ViewModel for managing company detail screen state
class CompanyDetailViewModel extends ChangeNotifier {
  CompanyDetailViewModel({required GetCompanyByIdCommand getCompanyByIdCommand})
    : _getCompanyByIdCommand = getCompanyByIdCommand {
    _getCompanyByIdCommand.addListener(_onCommandChanged);
  }

  final GetCompanyByIdCommand _getCompanyByIdCommand;

  // Message state for UI feedback
  String? _message;

  // Command getter
  GetCompanyByIdCommand get getCompanyByIdCommand => _getCompanyByIdCommand;

  // Message getter for UI
  String? get message => _message;

  // State getters
  Company? get company => _getCompanyByIdCommand.result;
  bool get isLoading => _getCompanyByIdCommand.isExecuting;
  bool get hasError => _getCompanyByIdCommand.hasError;
  AppError? get error => _getCompanyByIdCommand.error;
  bool get isInitialized => _getCompanyByIdCommand.result != null;

  /// Load company details by ID
  Future<void> loadCompany(int companyId) async {
    await _getCompanyByIdCommand.getCompanyById(companyId);
  }

  /// Clear any errors
  void clearError() {
    _getCompanyByIdCommand.clearError();
    notifyListeners();
  }

  /// Handle session application request
  void handleSessionApplication() {
    _message = 'Student session application coming soon!';
    notifyListeners();
  }

  /// Clear message after UI has consumed it (call from UI)
  void clearMessage() {
    if (_message != null) {
      _message = null;
      notifyListeners();
    }
  }

  /// Listen to command state changes
  void _onCommandChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _getCompanyByIdCommand.removeListener(_onCommandChanged);
    super.dispose();
  }
}
