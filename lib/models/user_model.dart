class UserModel {
  final String id;
  String name;
  String email;
  String? phone;
  String? avatarUrl;
  String? shopImage;
  String? bio;
  String? location;
  String role; // 'Customer', 'Seller', 'Driver'
  bool is2faEnabled;
  String? businessName;
  String? vehicleType;
  String? paymentMethod;
  List<String> wishlist;
  List<String> myListings;
  List<String> myOrders;
  DateTime joinedAt;
  int points;
  double cancellationPenalty;
  
  bool get isSeller => role == 'Seller';
  bool get isDriver => role == 'Driver';

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.shopImage,
    this.bio,
    this.location,
    this.role = 'Customer',
    this.is2faEnabled = false,
    this.businessName,
    this.vehicleType,
    this.paymentMethod,
    this.wishlist = const [],
    this.myListings = const [],
    this.myOrders = const [],
    required this.joinedAt,
    this.points = 250,
    this.cancellationPenalty = 0.0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      avatarUrl: map['avatarUrl'],
      shopImage: map['shopImage'],
      bio: map['bio'],
      location: map['location'],
      role: map['role'] ?? 'Customer',
      is2faEnabled: map['is2faEnabled'] ?? false,
      businessName: map['businessName'],
      vehicleType: map['vehicleType'],
      paymentMethod: map['paymentMethod'],
      wishlist: List<String>.from(map['wishlist'] ?? []),
      myListings: List<String>.from(map['myListings'] ?? []),
      myOrders: List<String>.from(map['myOrders'] ?? []),
      joinedAt: map['joinedAt'] != null
          ? (map['joinedAt'] is String ? DateTime.parse(map['joinedAt']) : DateTime.now())
          : DateTime.now(),
      points: map['points'] ?? 250,
      cancellationPenalty: (map['cancellationPenalty'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'shopImage': shopImage,
      'bio': bio,
      'location': location,
      'role': role,
      'is2faEnabled': is2faEnabled,
      'businessName': businessName,
      'vehicleType': vehicleType,
      'paymentMethod': paymentMethod,
      'wishlist': wishlist,
      'myListings': myListings,
      'myOrders': myOrders,
      'joinedAt': joinedAt.toIso8601String(),
      'points': points,
      'cancellationPenalty': cancellationPenalty,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? shopImage,
    String? bio,
    String? location,
    String? role,
    bool? is2faEnabled,
    String? businessName,
    String? vehicleType,
    String? paymentMethod,
    List<String>? wishlist,
    List<String>? myListings,
    List<String>? myOrders,
    DateTime? joinedAt,
    int? points,
    double? cancellationPenalty,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      shopImage: shopImage ?? this.shopImage,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      role: role ?? this.role,
      is2faEnabled: is2faEnabled ?? this.is2faEnabled,
      businessName: businessName ?? this.businessName,
      vehicleType: vehicleType ?? this.vehicleType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      wishlist: wishlist ?? this.wishlist,
      myListings: myListings ?? this.myListings,
      myOrders: myOrders ?? this.myOrders,
      joinedAt: joinedAt ?? this.joinedAt,
      points: points ?? this.points,
      cancellationPenalty: cancellationPenalty ?? this.cancellationPenalty,
    );
  }
}
