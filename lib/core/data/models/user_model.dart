
import 'package:intl_phone_field/countries.dart';
import 'media_model.dart';

enum UserStatus { ACTIVE, INACTIVE, PENDING, DELETED, SUSPENDED }
enum Gender { MALE, FEMALE, OTHER }
enum ApprovalStatus { APPROVED, PENDING, REJECTED }
enum UserRoleName {
  ESTATE_RESIDENT,
  MASTER,
  GENERAL_MANAGER,
  FACILITY_MANAGER,
  SECURITY,
  REGULAR
}
enum CodeTypeConstant { CHANGE_PASSWORD, SIGNUP }

class User {
  int? id;
  String? username;
  String? email;
  String? firstName;
  String? lastName;
  String? otherName;
  String? houseNumber;
  String? houseDescription;
  Gender? gender;
  String? phone;
  bool? emailVerified;
  bool? phoneVerified;
  String? device;
  Picture? picture;
  Picture? proofOfAddress;
  Country? country;
  dynamic addressPOJO;
  dynamic createdBy;
  List<dynamic>? organizations;
  UserStatus? status;
  ApprovalStatus? approvalStatus;
  List<dynamic>? userDevicePojos;
  DateTime? createdAt;

  User({
    this.id,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.otherName,
    this.houseNumber,
    this.houseDescription,
    this.gender,
    this.phone,
    this.emailVerified,
    this.phoneVerified,
    this.device,
    this.picture,
    this.proofOfAddress,
    this.country,
    this.addressPOJO,
    this.createdBy,
    this.organizations,
    this.status,
    this.approvalStatus,
    this.userDevicePojos,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      otherName: json['otherName'],
      houseNumber: json['houseNumber'],
      houseDescription: json['houseDescription'],
      gender: _parseGender(json['gender']),
      phone: json['phone'],
      emailVerified: json['emailVerified'],
      phoneVerified: json['phoneVerified'],
      device: json['device'],
      picture: json['picture'] != null ? Picture.fromJson(json['picture']) : null,
      proofOfAddress: json['proofOfAddress'] != null ? Picture.fromJson(json['proofOfAddress']) : null,
      addressPOJO: json['addressPOJO'],
      createdBy: json['createdBy'],
      organizations: json['organizations'],
      status: _parseUserStatus(json['status']),
      approvalStatus: _parseApprovalStatus(json['approvalStatus']),
      userDevicePojos: json['userDevicePojos'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'otherName': otherName,
      'houseNumber': houseNumber,
      'houseDescription': houseDescription,
      'gender': gender?.name,
      'phone': phone,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'device': device,
      'picture': picture?.toJson(),
      'proofOfAddress': proofOfAddress?.toJson(),
      'addressPOJO': addressPOJO,
      'createdBy': createdBy,
      'organizations': organizations,
      'status': status?.name,
      'approvalStatus': approvalStatus?.name,
      'userDevicePojos': userDevicePojos,
      'createdAt': createdAt?.toIso8601String(),
    };
  }


  /// Convenient getter for full name
  String get fullName => "${firstName ?? ''} ${lastName ?? ''}".trim();

  // Helpers
  static Gender? _parseGender(String? value) {
    if (value == null) return null;
    return Gender.values.firstWhere(
          (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => Gender.OTHER,
    );
  }

  static UserStatus _parseUserStatus(String? value) {
    if (value == null) return UserStatus.PENDING;
    return UserStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UserStatus.PENDING,
    );
  }

  static ApprovalStatus _parseApprovalStatus(String? value) {
    if (value == null) return ApprovalStatus.PENDING;
    return ApprovalStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ApprovalStatus.PENDING,
    );
  }
}
