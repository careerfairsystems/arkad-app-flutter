import 'package:arkad/schemas/company.dart';

abstract class CompanyProvider {
  List<Company> getCompanies();
}

class MemoryCompanyProvider implements CompanyProvider {
  List<Company>? _companies = null;


  List<Company> initCompanies(List<Company> companies) {
    // TODO 
    return 
  }

  List<Company> getCompanies(){
    List<Company> companies = _companies ?? [];
  }
}
