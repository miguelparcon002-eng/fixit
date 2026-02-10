import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  // Sample services - in production, fetch from Supabase
  final List<Map<String, dynamic>> _services = [
    {
      'id': '1',
      'name': 'Screen Repair',
      'category': 'Mobile Phone',
      'price': '₱1,500 - ₱3,500',
      'duration': '1-2 hours',
      'isActive': true,
      'description': 'Professional screen replacement for all phone models',
    },
    {
      'id': '2',
      'name': 'Battery Replacement',
      'category': 'Mobile Phone',
      'price': '₱500 - ₱1,500',
      'duration': '30-60 mins',
      'isActive': true,
      'description': 'Original and aftermarket battery replacements',
    },
    {
      'id': '3',
      'name': 'Laptop Screen Repair',
      'category': 'Laptop',
      'price': '₱2,500 - ₱6,000',
      'duration': '2-3 hours',
      'isActive': true,
      'description': 'LCD/LED screen replacement for laptops',
    },
    {
      'id': '4',
      'name': 'Data Recovery',
      'category': 'Other',
      'price': '₱1,000 - ₱3,000',
      'duration': '2-4 hours',
      'isActive': false,
      'description': 'Recover lost or deleted files',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      appBar: AppBar(
        backgroundColor: AppTheme.deepBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Manage Services',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.deepBlue, AppTheme.lightBlue],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.build_circle,
                    label: 'Active Services',
                    value: '${_services.where((s) => s['isActive'] == true).length}',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.category,
                    label: 'Categories',
                    value: '${_services.map((s) => s['category']).toSet().length}',
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Services List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Services',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddServiceDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add New'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._services.map((service) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ServiceCard(
                    service: service,
                    onToggle: () => _toggleServiceStatus(service['id']),
                    onEdit: () => _editService(service),
                    onDelete: () => _deleteService(service['id']),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Service'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Service creation feature coming soon!'),
              SizedBox(height: 12),
              Text(
                'You will be able to add services with:\n• Service name\n• Category\n• Pricing\n• Estimated duration\n• Description\n• Images',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleServiceStatus(String id) {
    setState(() {
      final index = _services.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        _services[index]['isActive'] = !_services[index]['isActive'];
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Service status updated'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _editService(Map<String, dynamic> service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit service: ${service['name']}'),
        backgroundColor: AppTheme.lightBlue,
      ),
    );
  }

  void _deleteService(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _services.removeWhere((s) => s['id'] == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Service deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = service['isActive'] as bool;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppTheme.deepBlue : Colors.grey.shade300,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        service['category'],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (_) => onToggle(),
                activeThumbColor: AppTheme.deepBlue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            service['description'],
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
              const SizedBox(width: 4),
              Text(
                service['price'],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                service['duration'],
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.deepBlue,
                    side: const BorderSide(color: AppTheme.deepBlue),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
