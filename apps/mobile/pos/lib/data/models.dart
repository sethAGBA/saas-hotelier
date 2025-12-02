import 'package:flutter/foundation.dart';

enum MenuAvailability { available, outOfStock, seasonal }

class MenuItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final String emoji;
  final String description;
  final String? imagePath;
  final double vatRate;
  final MenuAvailability availability;

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.emoji,
    required this.description,
    this.imagePath,
    this.vatRate = 0,
    this.availability = MenuAvailability.available,
  });

  bool get isAvailable => availability == MenuAvailability.available;

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final availabilityLabel = json['availability'] as String?;
    MenuAvailability availability;
    if (availabilityLabel != null) {
      availability = MenuAvailability.values.firstWhere(
        (value) => value.name == availabilityLabel,
        orElse: () => MenuAvailability.available,
      );
    } else {
      final legacyAvailable = json['isAvailable'] as bool? ?? true;
      availability = legacyAvailable
          ? MenuAvailability.available
          : MenuAvailability.outOfStock;
    }
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      emoji: json['emoji'] as String,
      description: json['description'] as String,
      imagePath: json['imagePath'] as String?,
      vatRate: (json['vatRate'] as num?)?.toDouble() ?? 0,
      availability: availability,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'category': category,
    'emoji': emoji,
    'description': description,
    'imagePath': imagePath,
    'vatRate': vatRate,
    'availability': availability.name,
    'isAvailable': isAvailable,
  };

  MenuItem copyWith({
    String? name,
    double? price,
    String? category,
    String? emoji,
    String? description,
    String? imagePath,
    double? vatRate,
    MenuAvailability? availability,
  }) {
    return MenuItem(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      vatRate: vatRate ?? this.vatRate,
      availability: availability ?? this.availability,
    );
  }
}

class UserProfile {
  final String name;
  final PosRole role;
  final String pin;

  const UserProfile({
    required this.name,
    required this.role,
    required this.pin,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role.name,
        'pin': pin,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? 'Utilisateur',
      role: PosRole.values.firstWhere(
        (value) => value.name == json['role'],
        orElse: () => PosRole.staff,
      ),
      pin: json['pin'] as String? ??
          ((json['role'] == PosRole.manager.name) ? '7777' : '1111'),
    );
  }
}

class AppSettings {
  final String restaurantName;
  final String staffPin;
  final String managerPin;
  final String pdfDirectory;
  final List<UserProfile> users;
  final int tableCount;
  final List<String> categories;

  const AppSettings({
    required this.restaurantName,
    required this.staffPin,
    required this.managerPin,
    required this.pdfDirectory,
    required this.users,
    this.tableCount = 12,
    this.categories = const ['Entrées', 'Plats', 'Desserts', 'Boissons'],
  });

  AppSettings copyWith({
    String? restaurantName,
    String? staffPin,
    String? managerPin,
    String? pdfDirectory,
    List<UserProfile>? users,
    int? tableCount,
    List<String>? categories,
  }) {
    return AppSettings(
      restaurantName: restaurantName ?? this.restaurantName,
      staffPin: staffPin ?? this.staffPin,
      managerPin: managerPin ?? this.managerPin,
      pdfDirectory: pdfDirectory ?? this.pdfDirectory,
      users: users ?? this.users,
      tableCount: tableCount ?? this.tableCount,
      categories: categories ?? this.categories,
    );
  }

  Map<String, dynamic> toJson() => {
    'restaurantName': restaurantName,
    'staffPin': staffPin,
    'managerPin': managerPin,
    'pdfDirectory': pdfDirectory,
    'users': users.map((user) => user.toJson()).toList(),
    'tableCount': tableCount,
    'categories': categories,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rawUsers = json['users'] as List<dynamic>? ?? [];
    final rawTableCount = json['tableCount'];
    final parsedTableCount = rawTableCount is int && rawTableCount > 0
        ? rawTableCount
        : 12;
    return AppSettings(
      restaurantName: json['restaurantName'] as String? ?? 'Restaurant POS',
      staffPin: json['staffPin'] as String? ?? '1111',
      managerPin: json['managerPin'] as String? ?? '7777',
      pdfDirectory: json['pdfDirectory'] as String? ?? '',
      users: rawUsers
          .map(
            (entry) =>
                UserProfile.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList(),
      tableCount: parsedTableCount,
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((entry) => entry.toString())
          .where((value) => value.isNotEmpty)
          .toList(),
    );
  }
}

class SalesLine {
  final String itemId;
  final String name;
  final int quantity;
  final double total;

  const SalesLine({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'name': name,
    'quantity': quantity,
    'total': total,
  };

  factory SalesLine.fromJson(Map<String, dynamic> json) {
    return SalesLine(
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int? ?? 0,
      total: (json['total'] as num).toDouble(),
    );
  }
}

class CatalogLogEntry {
  final String id;
  final String itemId;
  final String itemName;
  final String action;
  final String details;
  final String user;
  final DateTime timestamp;

  const CatalogLogEntry({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.action,
    required this.details,
    required this.user,
    required this.timestamp,
  });

  factory CatalogLogEntry.fromJson(Map<String, dynamic> json) {
    return CatalogLogEntry(
      id: json['id'] as String,
      itemId: json['itemId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      action: json['action'] as String? ?? '',
      details: json['details'] as String? ?? '',
      user: json['user'] as String? ?? 'Inconnu',
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': itemId,
        'itemName': itemName,
        'action': action,
        'details': details,
        'user': user,
        'timestamp': timestamp.toIso8601String(),
      };
}

class PaymentFragment {
  final String method;
  final double amount;

  const PaymentFragment({required this.method, required this.amount});

  Map<String, dynamic> toJson() => {
        'method': method,
        'amount': amount,
      };

  factory PaymentFragment.fromJson(Map<String, dynamic> json) {
    return PaymentFragment(
      method: json['method'] as String? ?? 'Inconnu',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SalesRecord {
  final String id;
  final DateTime timestamp;
  final double amount;
  final double tip;
  final String paymentMethod;
  final int tableNumber;
  final List<SalesLine> lines;
  final List<PaymentFragment> payments;

  const SalesRecord({
    required this.id,
    required this.timestamp,
    required this.amount,
    required this.tip,
    required this.paymentMethod,
    required this.tableNumber,
    required this.lines,
    this.payments = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'amount': amount,
    'tip': tip,
    'paymentMethod': paymentMethod,
    'tableNumber': tableNumber,
    'lines': lines.map((line) => line.toJson()).toList(),
    'payments': payments.map((p) => p.toJson()).toList(),
  };

  factory SalesRecord.fromJson(Map<String, dynamic> json) {
    final lines = (json['lines'] as List<dynamic>? ?? [])
        .map(
          (line) => SalesLine.fromJson(Map<String, dynamic>.from(line as Map)),
        )
        .toList();
    return SalesRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      amount: (json['amount'] as num).toDouble(),
      tip: (json['tip'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String? ?? 'Unknown',
      tableNumber: json['tableNumber'] as int? ?? 0,
      lines: lines,
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map(
            (entry) =>
                PaymentFragment.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList(),
    );
  }
}

class OrderItem {
  final MenuItem menuItem;
  int quantity;
  String? notes;

  OrderItem({required this.menuItem, this.quantity = 1, this.notes});

  Map<String, dynamic> toJson() => {
    'menuItemId': menuItem.id,
    'quantity': quantity,
    'notes': notes,
  };

  static OrderItem? fromJson(
    Map<String, dynamic> json,
    Map<String, MenuItem> catalog,
  ) {
    final menuItem = catalog[json['menuItemId']];
    if (menuItem == null) {
      debugPrint('Menu item ${json['menuItemId']} missing from catalog');
      return null;
    }
    return OrderItem(
      menuItem: menuItem,
      quantity: json['quantity'] as int? ?? 1,
      notes: json['notes'] as String?,
    );
  }
}

class DiningTable {
  final int number;
  bool isOccupied;
  List<OrderItem> orders;
  DateTime? occupiedSince;
  double? lastBillTotal;
  double? lastTipAmount;
  String? lastPaymentMethod;
  DateTime? lastPaidAt;
  List<ProductionTicket> tickets;
  List<SalesLine>? lastReceiptLines;
  double? lastSubtotal;
  double? lastDiscountAmount;
  String? lastReceiptPath;

  DiningTable({
    required this.number,
    this.isOccupied = false,
    List<OrderItem>? orders,
    this.occupiedSince,
    this.lastBillTotal,
    this.lastTipAmount,
    this.lastPaymentMethod,
    this.lastPaidAt,
    List<ProductionTicket>? tickets,
    this.lastReceiptLines,
    this.lastSubtotal,
    this.lastDiscountAmount,
    this.lastReceiptPath,
  }) : orders = orders ?? [],
       tickets = tickets ?? [];

  double get total {
    return orders.fold(
      0,
      (sum, item) => sum + (item.menuItem.price * item.quantity),
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'isOccupied': isOccupied,
    'occupiedSince': occupiedSince?.toIso8601String(),
    'orders': orders.map((o) => o.toJson()).toList(),
    'lastBillTotal': lastBillTotal,
    'lastTipAmount': lastTipAmount,
    'lastPaymentMethod': lastPaymentMethod,
    'lastPaidAt': lastPaidAt?.toIso8601String(),
    'tickets': tickets.map((ticket) => ticket.toJson()).toList(),
    'lastReceiptLines':
        lastReceiptLines?.map((line) => line.toJson()).toList(),
    'lastSubtotal': lastSubtotal,
    'lastDiscountAmount': lastDiscountAmount,
    'lastReceiptPath': lastReceiptPath,
  };

  static DiningTable fromJson(
    Map<String, dynamic> json,
    Map<String, MenuItem> catalog,
  ) {
    final orderList = (json['orders'] as List<dynamic>? ?? [])
        .map(
          (o) =>
              OrderItem.fromJson(Map<String, dynamic>.from(o as Map), catalog),
        )
        .whereType<OrderItem>()
        .toList();

    return DiningTable(
      number: json['number'] as int,
      isOccupied: json['isOccupied'] as bool? ?? false,
      occupiedSince: json['occupiedSince'] != null
          ? DateTime.tryParse(json['occupiedSince'] as String)
          : null,
      orders: orderList,
      lastBillTotal: (json['lastBillTotal'] as num?)?.toDouble(),
      lastTipAmount: (json['lastTipAmount'] as num?)?.toDouble(),
      lastPaymentMethod: json['lastPaymentMethod'] as String?,
      lastPaidAt: json['lastPaidAt'] != null
          ? DateTime.tryParse(json['lastPaidAt'] as String)
          : null,
      tickets: (json['tickets'] as List<dynamic>? ?? [])
          .map(
            (entry) => ProductionTicket.fromJson(
              Map<String, dynamic>.from(entry as Map),
              catalog,
            ),
          )
          .toList(),
      lastReceiptLines:
          (json['lastReceiptLines'] as List<dynamic>?)?.map(
            (entry) =>
                SalesLine.fromJson(Map<String, dynamic>.from(entry as Map)),
          ).toList(),
      lastSubtotal: (json['lastSubtotal'] as num?)?.toDouble(),
      lastDiscountAmount: (json['lastDiscountAmount'] as num?)?.toDouble(),
      lastReceiptPath: json['lastReceiptPath'] as String?,
    );
  }
}

const List<MenuItem> seedMenuItems = [
  MenuItem(
    id: '1',
    name: 'Pizza Margherita',
    price: 12.99,
    category: 'Plats',
    emoji: '🍕',
    description: 'Tomate, mozzarella, basilic',
  ),
  MenuItem(
    id: '2',
    name: 'Burger Maison',
    price: 15.5,
    category: 'Plats',
    emoji: '🍔',
    description: 'Bœuf, cheddar, bacon',
  ),
  MenuItem(
    id: '3',
    name: 'Salade César',
    price: 10.99,
    category: 'Entrées',
    emoji: '🥗',
    description: 'Poulet, parmesan, croûtons',
  ),
  MenuItem(
    id: '4',
    name: 'Pâtes Carbonara',
    price: 13.99,
    category: 'Plats',
    emoji: '🍝',
    description: 'Crème, lardons, parmesan',
  ),
  MenuItem(
    id: '5',
    name: 'Sushi Mix',
    price: 18.99,
    category: 'Plats',
    emoji: '🍱',
    description: 'Assortiment de 12 pièces',
  ),
  MenuItem(
    id: '6',
    name: 'Tiramisu',
    price: 6.5,
    category: 'Desserts',
    emoji: '🍰',
    description: 'Mascarpone, café, cacao',
  ),
  MenuItem(
    id: '7',
    name: 'Tarte Tatin',
    price: 7.0,
    category: 'Desserts',
    emoji: '🥧',
    description: 'Pommes caramélisées',
  ),
  MenuItem(
    id: '8',
    name: 'Coca-Cola',
    price: 3.5,
    category: 'Boissons',
    emoji: '🥤',
    description: '33cl',
  ),
  MenuItem(
    id: '9',
    name: 'Café Espresso',
    price: 2.5,
    category: 'Boissons',
    emoji: '☕',
    description: 'Arabica intenso',
  ),
  MenuItem(
    id: '10',
    name: 'Vin Rouge',
    price: 5.5,
    category: 'Boissons',
    emoji: '🍷',
    description: 'Verre 15cl',
  ),
  MenuItem(
    id: '11',
    name: 'Soupe du Jour',
    price: 5.99,
    category: 'Entrées',
    emoji: '🍲',
    description: 'Légumes frais',
  ),
  MenuItem(
    id: '12',
    name: 'Crème Brûlée',
    price: 6.99,
    category: 'Desserts',
    emoji: '🍮',
    description: 'Vanille Madagascar',
  ),
];

List<DiningTable> buildSeedTables({int count = 12}) {
  return List<DiningTable>.generate(
    count,
    (index) => DiningTable(number: index + 1),
  );
}

enum PosRole { staff, manager }

enum TicketType { kitchen, bar }

enum TicketStatus { pending, inProgress, ready, served }

class ProductionTicket {
  final String id;
  final TicketType type;
  final TicketStatus status;
  final DateTime createdAt;
  final List<OrderItem> items;
  final int tableNumber;

  const ProductionTicket({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.tableNumber,
  });

  ProductionTicket copyWith({
    TicketType? type,
    TicketStatus? status,
    DateTime? createdAt,
    List<OrderItem>? items,
  }) {
    return ProductionTicket(
      id: id,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      tableNumber: tableNumber,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(),
    'tableNumber': tableNumber,
  };

  factory ProductionTicket.fromJson(
    Map<String, dynamic> json,
    Map<String, MenuItem> catalog,
  ) {
    final ticketItems = (json['items'] as List<dynamic>)
        .map(
          (entry) => OrderItem.fromJson(
            Map<String, dynamic>.from(entry as Map),
            catalog,
          ),
        )
        .whereType<OrderItem>()
        .toList();

    return ProductionTicket(
      id: json['id'] as String,
      type: TicketType.values.firstWhere((value) => value.name == json['type']),
      status: TicketStatus.values.firstWhere(
        (value) => value.name == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      items: ticketItems,
      tableNumber: json['tableNumber'] as int,
    );
  }
}
