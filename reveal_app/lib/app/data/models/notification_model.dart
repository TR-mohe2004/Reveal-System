class NotificationItem {
  final String id;
  final int? orderId;
  final String status;
  final String title;
  final String body;
  final String createdAt;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.orderId,
    this.status = '',
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      orderId: orderId,
      status: status,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id'] is int ? json['order_id'] : int.tryParse(json['order_id']?.toString() ?? ''),
      status: json['status']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      isRead: json['is_read'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'status': status,
      'title': title,
      'body': body,
      'created_at': createdAt,
      'is_read': isRead,
    };
  }
}
