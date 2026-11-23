/// EmergencyContact represents guardian, hospital, or police contacts.
class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final bool isPrimary;
  final bool notifyViaSms;
  final bool notifyViaCall;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isPrimary = false,
    this.notifyViaSms = true,
    this.notifyViaCall = true,
  });

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
    bool? isPrimary,
    bool? notifyViaSms,
    bool? notifyViaCall,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      notifyViaSms: notifyViaSms ?? this.notifyViaSms,
      notifyViaCall: notifyViaCall ?? this.notifyViaCall,
    );
  }
}
