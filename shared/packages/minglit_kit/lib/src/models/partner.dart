class Partner {
  final String id;
  final String name;
  final String? introduction;
  final String? address;
  final String? contactPhone;
  final String? contactEmail;
  final String? representativeName;
  final String? bizName;
  final String? bizNumber;
  final String? profileImageUrl;
  final bool isActive;

  Partner({
    required this.id,
    required this.name,
    this.introduction,
    this.address,
    this.contactPhone,
    this.contactEmail,
    this.representativeName,
    this.bizName,
    this.bizNumber,
    this.profileImageUrl,
    this.isActive = true,
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'],
      name: json['name'],
      introduction: json['introduction'],
      address: json['address'],
      contactPhone: json['contact_phone'],
      contactEmail: json['contact_email'],
      representativeName: json['representative_name'],
      bizName: json['biz_name'],
      bizNumber: json['biz_number'],
      profileImageUrl: json['profile_image_url'],
      isActive: json['is_active'] ?? true,
    );
  }
}
