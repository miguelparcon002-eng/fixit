import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/support_ticket_model.dart';
import '../core/config/supabase_config.dart';
import '../core/utils/app_logger.dart';
import 'auth_provider.dart';

// Support Ticket Service — reads/writes directly to the `support_tickets` Supabase table
class SupportTicketService {
  final _supabase = SupabaseConfig.client;

  Future<List<SupportTicket>> loadAllTickets() async {
    try {
      final response = await _supabase
          .from('support_tickets')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => SupportTicket.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.p('SupportTicketService: Error loading all tickets - $e');
      return [];
    }
  }

  Future<List<SupportTicket>> loadTicketsForUser(String customerId) async {
    try {
      final response = await _supabase
          .from('support_tickets')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => SupportTicket.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.p('SupportTicketService: Error loading user tickets - $e');
      return [];
    }
  }

  Future<SupportTicket?> createTicket(SupportTicket ticket) async {
    try {
      final data = {
        'id': ticket.id,
        'customer_id': ticket.customerId,
        'customer_name': ticket.customerName,
        'customer_email': ticket.customerEmail,
        'customer_phone': ticket.customerPhone,
        'subject': ticket.subject,
        'description': ticket.description,
        'category': ticket.category,
        'priority': ticket.priority,
        'status': ticket.status,
        'booking_id': ticket.bookingId,
        'technician_id': ticket.technicianId,
        'assigned_admin_id': ticket.assignedAdminId,
        'messages': ticket.messages.map((m) => m.toJson()).toList(),
        'attachments': ticket.attachments,
        'created_at': ticket.createdAt.toIso8601String(),
      };
      final response = await _supabase
          .from('support_tickets')
          .insert(data)
          .select()
          .single();
      AppLogger.p('SupportTicketService: Created ticket ${ticket.id}');
      return SupportTicket.fromJson(response);
    } catch (e) {
      AppLogger.p('SupportTicketService: Error creating ticket - $e');
      return null;
    }
  }

  Future<bool> updateTicket(SupportTicket ticket) async {
    try {
      await _supabase
          .from('support_tickets')
          .update({
            'subject': ticket.subject,
            'description': ticket.description,
            'status': ticket.status,
            'priority': ticket.priority,
            'assigned_admin_id': ticket.assignedAdminId,
            'messages': ticket.messages.map((m) => m.toJson()).toList(),
            'attachments': ticket.attachments,
            'updated_at': DateTime.now().toIso8601String(),
            'resolved_at': ticket.resolvedAt?.toIso8601String(),
          })
          .eq('id', ticket.id);
      AppLogger.p('SupportTicketService: Updated ticket ${ticket.id}');
      return true;
    } catch (e) {
      AppLogger.p('SupportTicketService: Error updating ticket - $e');
      return false;
    }
  }

  Future<bool> deleteTicket(String ticketId) async {
    try {
      await _supabase.from('support_tickets').delete().eq('id', ticketId);
      AppLogger.p('SupportTicketService: Deleted ticket $ticketId');
      return true;
    } catch (e) {
      AppLogger.p('SupportTicketService: Error deleting ticket - $e');
      return false;
    }
  }

  Future<bool> addMessage(String ticketId, TicketMessage message) async {
    try {
      // Fetch current messages, append new one, save back
      final response = await _supabase
          .from('support_tickets')
          .select('messages')
          .eq('id', ticketId)
          .single();
      final existing = (response['messages'] as List?) ?? [];
      final updated = [...existing, message.toJson()];
      await _supabase.from('support_tickets').update({
        'messages': updated,
        'updated_at': DateTime.now().toIso8601String(),
        'status': 'in_progress',
      }).eq('id', ticketId);
      AppLogger.p('SupportTicketService: Added message to ticket $ticketId');
      return true;
    } catch (e) {
      AppLogger.p('SupportTicketService: Error adding message - $e');
      return false;
    }
  }

  Future<bool> updateTicketStatus(String ticketId, String status) async {
    try {
      await _supabase.from('support_tickets').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        if (status == 'resolved')
          'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', ticketId);
      AppLogger.p('SupportTicketService: Updated status of $ticketId to $status');
      return true;
    } catch (e) {
      AppLogger.p('SupportTicketService: Error updating status - $e');
      return false;
    }
  }
}

// Provider for the service
final supportTicketServiceProvider = Provider((ref) => SupportTicketService());

// State notifier — all tickets (admin view)
class SupportTicketNotifier extends StateNotifier<List<SupportTicket>> {
  final SupportTicketService _service;

  SupportTicketNotifier(this._service) : super([]) {
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final tickets = await _service.loadAllTickets();
      state = tickets;
    } catch (e) {
      AppLogger.p('SupportTicketNotifier: Error loading tickets - $e');
    }
  }

  Future<void> reload() async => _loadTickets();

  Future<SupportTicket?> createTicket(SupportTicket ticket) async {
    final result = await _service.createTicket(ticket);
    if (result != null) state = [result, ...state];
    return result;
  }

  Future<bool> updateTicket(SupportTicket ticket) async {
    final result = await _service.updateTicket(ticket);
    if (result) {
      state = state.map((t) => t.id == ticket.id ? ticket : t).toList();
    }
    return result;
  }

  Future<bool> deleteTicket(String ticketId) async {
    final result = await _service.deleteTicket(ticketId);
    if (result) state = state.where((t) => t.id != ticketId).toList();
    return result;
  }

  Future<bool> addMessage(String ticketId, TicketMessage message) async {
    final result = await _service.addMessage(ticketId, message);
    if (result) {
      state = state.map((ticket) {
        if (ticket.id == ticketId) {
          return ticket.copyWith(
            messages: [...ticket.messages, message],
            updatedAt: DateTime.now(),
            status: ticket.status == 'open' ? 'in_progress' : ticket.status,
          );
        }
        return ticket;
      }).toList();
    }
    return result;
  }

  Future<bool> updateTicketStatus(String ticketId, String status) async {
    final result = await _service.updateTicketStatus(ticketId, status);
    if (result) {
      state = state.map((ticket) {
        if (ticket.id == ticketId) {
          return ticket.copyWith(
            status: status,
            updatedAt: DateTime.now(),
            resolvedAt: status == 'resolved' ? DateTime.now() : null,
          );
        }
        return ticket;
      }).toList();
    }
    return result;
  }

  SupportTicket? getTicketById(String ticketId) {
    try {
      return state.firstWhere((t) => t.id == ticketId);
    } catch (e) {
      return null;
    }
  }
}

// Main provider for all tickets (admin)
final supportTicketsProvider = StateNotifierProvider<SupportTicketNotifier, List<SupportTicket>>(
  (ref) => SupportTicketNotifier(ref.watch(supportTicketServiceProvider)),
);

// Provider for the current user's own tickets only
final customerTicketsProvider = FutureProvider<List<SupportTicket>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  final service = ref.watch(supportTicketServiceProvider);
  return service.loadTicketsForUser(user.id);
});

// Derived count providers
final openTicketsCountProvider = Provider<int>((ref) {
  final tickets = ref.watch(supportTicketsProvider);
  return tickets.where((t) => t.status == 'open').length;
});

final inProgressTicketsCountProvider = Provider<int>((ref) {
  final tickets = ref.watch(supportTicketsProvider);
  return tickets.where((t) => t.status == 'in_progress').length;
});

final resolvedTicketsCountProvider = Provider<int>((ref) {
  final tickets = ref.watch(supportTicketsProvider);
  return tickets.where((t) => t.status == 'resolved' || t.status == 'closed').length;
});

final ticketByIdProvider = Provider.family<SupportTicket?, String>((ref, ticketId) {
  final tickets = ref.watch(supportTicketsProvider);
  try {
    return tickets.firstWhere((t) => t.id == ticketId);
  } catch (e) {
    return null;
  }
});
