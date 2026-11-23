/// UserProfile stores rider personal and safety credentials.
class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String vehicleModel;
  final String vehiclePlateNumber;
  final String bloodGroup;
  final String medicalNotes;
  final bool isLoggedIn;

  const UserProfile({
    this.id = 'RDR-2026-904',
    this.fullName = 'Yogesh Sharma',
    this.email = 'yogesh.iot@smarthelmet.io',
    this.phone = '+91 98765 43210',
    this.vehicleModel = 'KTM Duke 390 / EV Smart Bike',
    this.vehiclePlateNumber = 'MH 12 SH 2026',
    this.bloodGroup = 'O+ Positive',
    this.medicalNotes = 'No known drug allergies. Wear contact lenses.',
    this.isLoggedIn = true,
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? vehicleModel,
    String? vehiclePlateNumber,
    String? bloodGroup,
    String? medicalNotes,
    bool? isLoggedIn,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehiclePlateNumber: vehiclePlateNumber ?? this.vehiclePlateNumber,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}
