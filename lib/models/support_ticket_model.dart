class SupportTicket {
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String subject;
  final String description;
  final String category; // booking_issue, payment_issue, technician_complaint, app_bug, other
  final String priority; // low, medium, high, urgent
  final String status; // open, in_progress, resolved, closed
  final String? bookingId; // If related to a specific booking
  final String? technicianId; // If complaint is about a technician
  final String? assignedAdminId;
  final List<TicketMessage> messages;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  SupportTicket({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.bookingId,
    this.technicianId,
    this.assignedAdminId,
    this.messages = const [],
    this.attachments = const [],
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String,
      customerEmail: json['customer_email'] as String,
      customerPhone: json['customer_phone'] as String?,
      subject: json['subject'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      bookingId: json['booking_id'] as String?,
      technicianId: json['technician_id'] as String?,
      assignedAdminId: json['assigned_admin_id'] as String?,
      messages: json['messages'] != null
          ? (json['messages'] as List)
              .map((m) => TicketMessage.fromJson(m as Map<String, dynamic>))
              .toList()
          : [],
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'] as List)
          : [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'subject': subject,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'booking_id': bookingId,
      'technician_id': technicianId,
      'assigned_admin_id': assignedAdminId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  SupportTicket copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? subject,
    String? description,
    String? category,
    String? priority,
    String? status,
    String? bookingId,
    String? technicianId,
    String? assignedAdminId,
    List<TicketMessage>? messages,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      bookingId: bookingId ?? this.bookingId,
      technicianId: technicianId ?? this.technicianId,
      assignedAdminId: assignedAdminId ?? this.assignedAdminId,
      messages: messages ?? this.messages,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

class TicketMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String senderRole; // customer, admin
  final String message;
  final List<String> attachments;
  final DateTime createdAt;
  final bool isRead;

  TicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.attachments = const [],
    required this.createdAt,
    this.isRead = false,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String,
      senderRole: json['sender_role'] as String,
      message: json['message'] as String,
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'] as List)
          : [],
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'message': message,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}
