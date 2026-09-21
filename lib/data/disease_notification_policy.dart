import '../models/disease_event.dart';

enum DiseaseAlertImportance { normal, high, critical }

class DiseaseNotificationPolicy {
  const DiseaseNotificationPolicy();

  String dedupeKey(DiseaseEvent event) => event.id;

  DiseaseAlertImportance importance(DiseaseEvent event) {
    if (event.diseaseType == 'ASF' || event.diseaseType == '구제역') {
      return DiseaseAlertImportance.critical;
    }
    if (event.diseaseType == 'PRRS') {
      return DiseaseAlertImportance.high;
    }
    return DiseaseAlertImportance.normal;
  }

  bool shouldNotify({
    required DiseaseEvent event,
    required Set<String> interestDistrictCodes,
    required Set<String> adjacentDistrictCodes,
    required bool nationwideImportantEnabled,
  }) {
    if (!event.isDomestic || !event.canRenderMarker) return false;

    if (event.districtCode.isNotEmpty &&
        interestDistrictCodes.contains(event.districtCode)) {
      return true;
    }

    if (event.districtCode.isNotEmpty &&
        adjacentDistrictCodes.contains(event.districtCode)) {
      return true;
    }

    return nationwideImportantEnabled &&
        (event.diseaseType == 'ASF' || event.diseaseType == '구제역');
  }
}
