import 'dart:convert';
import 'lib/features/company/domain/company.dart';
import 'lib/features/company/domain/subscription.dart';

void main() {
  final jsonStr = """
{
  "comp_1773161119019": {
    "createdAt": 1773161119019,
    "majorReleasesUsed": 0,
    "name": "R & Z Corp",
    "ownerUid": "",
    "properties": {
      "-OnC-QjV8k_78uYVPEb_": {
        "address": "D2 COND. ALTO BUJAMA LOTE 7",
        "city": "MALA",
        "cleaningFee": 200,
        "companyId": "1773161119019",
        "country": "PERU",
        "name": "CAB - D2L7",
        "order": 1,
        "ownerName": "HELGA PATRICIA ZEBALLOS CANELO",
        "ownerPhone": "51952024614",
        "propertyType": "House",
        "size": "4x4",
        "state": "LIMA"
      }
    },
    "propertyCount": 0,
    "subscriptionStatus": "active",
    "subscriptionTier": "free"
  }
}
""";
  final map = json.decode(jsonStr);
  map.forEach((k, v) {
    try {
      final comp = Company.fromMap(k, v);
      print("Parsed successfully: \${comp.name}");
    } catch(e, st) {
      print("Error parsing company: \$e\\n\$st");
    }
  });
}
