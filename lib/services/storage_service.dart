import '../models/emergency_contact.dart';
import '../models/incident_report.dart';
import '../models/user_profile.dart';
import '../utils/demo_data_helper.dart';

/// In-memory and local state storage for contacts, reports, and user profile.
class StorageService {
  late UserProfile _userProfile;
  late List<EmergencyContact> _emergencyContacts;
  late List<IncidentReport> _incidentReports;

  // App Settings
  int sosCountdownDuration = 10;
  bool soundAlertsEnabled = true;
  bool simulationModeEnabled = true;
  bool autoNightModeEnabled = true;

  StorageService() {
    _userProfile = const UserProfile();
    _emergencyContacts = DemoDataHelper.getInitialContacts();
    _incidentReports = DemoDataHelper.getInitialIncidents();
  }

  UserProfile get userProfile => _userProfile;
  List<EmergencyContact> get emergencyContacts => List.unmodifiable(_emergencyContacts);
  List<IncidentReport> get incidentReports => List.unmodifiable(_incidentReports);

  void updateUserProfile(UserProfile profile) {
    _userProfile = profile;
  }

  void addEmergencyContact(EmergencyContact contact) {
    _emergencyContacts.add(contact);
  }

  void removeEmergencyContact(String id) {
    _emergencyContacts.removeWhere((c) => c.id == id);
  }

  void updateEmergencyContact(EmergencyContact contact) {
    final index = _emergencyContacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      _emergencyContacts[index] = contact;
    }
  }

  void addIncidentReport(IncidentReport report) {
    _incidentReports.insert(0, report);
  }

  void clearIncidentReports() {
    _incidentReports.clear();
  }
}
