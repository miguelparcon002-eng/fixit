import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/support_ticket_model.dart';
import '../core/config/supabase_config.dart';
import 'auth_provider.dart';

// Storage key for support tickets
const String _ticketsStorageKey = 'support_tickets';
const String _messagesStorageKey = 'ticket_messages';
const String _tableName = 'local_storage';

// Support Ticket Service
class SupportTicketService {
  // Save tickets to Supabase
  Future<void> saveTickets(List<SupportTicket> tickets) async {
    try {
      final jsonData = json.encode(tickets.map((t) => t.toJson()).toList());

      final existing = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .eq('key', _ticketsStorageKey)
          .maybeSingle();

      if (existing != null) {
        await SupabaseConfig.client
            .from(_tableName)
            .update({'value': jsonData, 'updated_at': DateTime.now().toIso8601String()})
            .eq('key', _ticketsStorageKey);
      } else {
        await SupabaseConfig.client
            .from(_tableName)
            .insert({
              'key': _ticketsStorageKey,
              'value': jsonData,
              'updated_at': DateTime.now().toIso8601String()
            });
      }
      print('SupportTicketService: Saved ${tickets.length} tickets');
    } catch (e) {
      print('SupportTicketService: Error saving tickets - $e');
    }
  }

  // Load tickets from Supabase
  Future<List<SupportTicket>> loadTickets() async {
    try {
      final response = await SupabaseConfig.client
          .from(_tableName)
          .select('value')
          .eq('key', _ticketsStorageKey)
          .maybeSingle();

      if (response != null && response['value'] != null) {
        final List<dynamic> decoded = json.decode(response['value'] as String);
        final tickets = decoded.map((item) => SupportTicket.fromJson(item)).toList();
        print('SupportTicketService: Loaded ${tickets.length} tickets');
        return tickets;
      }
      print('SupportTicketService: No tickets found');
      return [];
    } catch (e) {
      print('SupportTicketService: Error loading tickets - $e');
      return [];
    }
  }

  // Create a new ticket
  Future<SupportTicket?> createTicket(SupportTicket ticket) async {
    try {
      final tickets = await loadTickets();
      tickets.add(ticket);
      await saveTickets(tickets);
      print('SupportTicketService: Created ticket ${ticket.id}');
      return ticket;
    } catch (e) {
      print('SupportTicketService: Error creating ticket - $e');
      return null;
    }
  }

  // Update ticket
  Future<bool> updateTicket(SupportTicket updatedTicket) async {
    try {
      final tickets = await loadTickets();
      final index = tickets.indexWhere((t) => t.id == updatedTicket.id);
      if (index != -1) {
        tickets[index] = updatedTicket;
        await saveTickets(tickets);
        print('SupportTicketService: Updated ticket ${updatedTicket.id}');
        return true;
      }
      return false;
    } catch (e) {
      print('SupportTicketService: Error updating ticket - $e');
      return false;
    }
  }

  // Delete ticket
  Future<bool> deleteTicket(String ticketId) async {
    try {
      final tickets = await loadTickets();
      tickets.removeWhere((t) => t.id == ticketId);
      await saveTickets(tickets);
      print('SupportTicketService: Deleted ticket $ticketId');
      return true;
    } catch (e) {
      print('SupportTicketService: Error deleting ticket - $e');
      return false;
    }
  }

  // Add message to ticket
  Future<bool> addMessage(String ticketId, TicketMessage message) async {
    try {
      final tickets = await loadTickets();
      final index = tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        final ticket = tickets[index];
        final updatedMessages = [...ticket.messages, message];
        tickets[index] = ticket.copyWith(
          messages: updatedMessages,
          updatedAt: DateTime.now(),
          status: ticket.status == 'open' ? 'in_progress' : ticket.status,
        );
        await saveTickets(tickets);
        print('SupportTicketService: Added message to ticket $ticketId');
        return true;
      }
      return false;
    } catch (e) {
      print('SupportTicketService: Error adding message - $e');
      return false;
    }
  }

  // Update ticket status
  Future<bool> updateTicketStatus(String ticketId, String status) async {
    try {
      final tickets = await loadTickets();
      final index = tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        tickets[index] = tickets[index].copyWith(
          status: status,
          updatedAt: DateTime.now(),
          resolvedAt: status == 'resolved' ? DateTime.now() : null,
        );
        await saveTickets(tickets);
        print('SupportTicketService: Updated status of ticket $ticketId to $status');
        return true;
      }
      return false;
    } catch (e) {
      print('SupportTicketService: Error updating status - $e');
      return false;
    }
  }

  // Get ticket by ID
  Future<SupportTicket?> getTicketById(String ticketId) async {
    try {
      final tickets = await loadTickets();
      return tickets.firstWhere(
        (t) => t.id == ticketId,
        orElse: () => throw Exception('Ticket not found'),
      );
    } catch (e) {
      print('SupportTicketService: Error getting ticket - $e');
      return null;
    }
  }

  // Get tickets by customer ID
  Future<List<SupportTicket>> getTicketsByCustomerId(String customerId) async {
    try {
      final tickets = await loadTickets();
      return tickets.where((t) => t.customerId == customerId).toList();
    } catch (e) {
      print('SupportTicketService: Error getting customer tickets - $e');
      return [];
    }
  }
}

// Provider for the service
final supportTicketServiceProvider = Provider((ref) => SupportTicketService());

// State notifier for managing tickets
class SupportTicketNotifier extends StateNotifier<List<SupportTicket>> {
  final SupportTicketService _service;
  bool _isInitialized = false;

  SupportTicketNotifier(this._service) : super([]) {
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    if (_isInitialized) return;
    try {
      final tickets = await _service.loadTickets();
      state = tickets;
      _isInitialized = true;
    } catch (e) {
      print('SupportTicketNotifier: Error loading tickets - $e');
      _isInitialized = true;
    }
  }

  Future<void> reload() async {
    _isInitialized = false;
    await _loadTickets();
  }

  Future<SupportTicket?> createTicket(SupportTicket ticket) async {
    final result = await _service.createTicket(ticket);
    if (result != null) {
      state = [...state, result];
    }
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
    if (result) {
      state = state.where((t) => t.id != ticketId).toList();
    }
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

  // Get ticket by ID from state
  SupportTicket? getTicketById(String ticketId) {
    try {
      return state.firstWhere((t) => t.id == ticketId);
    } catch (e) {
      return null;
    }
  }
}

// Main provider for all tickets (for admin)
final supportTicketsProvider = StateNotifierProvider<SupportTicketNotifier, List<SupportTicket>>(
  (ref) => SupportTicketNotifier(ref.watch(supportTicketServiceProvider)),
);

// Provider for customer's own tickets
final customerTicketsProvider = Provider<List<SupportTicket>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  final allTickets = ref.watch(supportTicketsProvider);

  if (user == null) return [];
  return allTickets.where((t) => t.customerId == user.id).toList();
});

// Provider for open tickets count
final openTicketsCountProvider = Provider<int>((ref) {
  final tickets = ref.watch(supportTicketsProvider);
  return tickets.where((t) => t.status == 'open').length;
});

// Provider for in-progress tickets count
final inProgressTicketsCountProvider = Provider<int>((ref) {
  final tickets = ref.watch(supportTicketsProvider);
  return tickets.where((t) => t.status == 'in_progress').length;
});

// Provider for resolved tickets count
final resolvedTicketsCountProvider = Provider<int>((ref) {
  final tickets = ref.watch(supportTicketsProvider);
  return tickets.where((t) => t.status == 'resolved' || t.status == 'closed').length;
});

// Provider for single ticket by ID
final ticketByIdProvider = Provider.family<SupportTicket?, String>((ref, ticketId) {
  final tickets = ref.watch(supportTicketsProvider);
  try {
    return tickets.firstWhere((t) => t.id == ticketId);
  } catch (e) {
    return null;
  }
});
