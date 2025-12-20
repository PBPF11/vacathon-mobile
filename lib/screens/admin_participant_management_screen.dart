import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

// CSS Variables from reference
const Color primaryColor = Color(0xFF177FDA);
const Color accentColor = Color(0xFFBBEE63);
const Color darkColor = Color(0xFF0F3057);
const Color textColor = Color(0xFF1B1B1B);
const Color bgColor = Color(0xFFF6F9FC);
const Color whiteColor = Color(0xFFFFFFFF);

class AdminParticipantManagementScreen extends StatefulWidget {
  const AdminParticipantManagementScreen({super.key});

  @override
  State<AdminParticipantManagementScreen> createState() => _AdminParticipantManagementScreenState();
}

class _AdminParticipantManagementScreenState extends State<AdminParticipantManagementScreen> {
  List<UserRaceHistory> _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      // For now, we'll use dummy data since the admin API might not be implemented
      // In a real implementation, this would call an admin participants API
      setState(() {
        _participants = [
          UserRaceHistory(
            id: 1,
            event: Event(
              id: 1,
              title: 'Jakarta Marathon 2024',
              slug: 'jakarta-marathon-2024',
              description: 'Test event',
              city: 'Jakarta',
              country: 'Indonesia',
              startDate: DateTime(2025, 1, 1),
              registrationDeadline: DateTime(2025, 12, 31),
              status: 'upcoming',
              popularityScore: 95,
              participantLimit: 5000,
              registeredCount: 3247,
              featured: true,
              categories: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            category: '21K Half Marathon',
            registrationDate: DateTime(2024, 10, 1),
            status: 'registered',
            bibNumber: 'BIB-1001',
            updatedAt: DateTime.now(),
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      print('[ADMIN] Failed to load participants: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load participants: $e')),
        );
      }
    }
  }

  Future<void> _confirmParticipant(UserRaceHistory participant) async {
    try {
      // For now, we'll just show a message since the API might not be implemented
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Participant confirmed (API not implemented)')),
      );
      // Reload participants
      await _loadParticipants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm participant: $e')),
      );
    }
  }

  Future<void> _deleteParticipant(UserRaceHistory participant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Participant'),
        content: const Text('Are you sure you want to remove this participant? This will also cancel their registration.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // For now, we'll just show a message since the API might not be implemented
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Participant deleted (API not implemented)')),
      );
      // Reload participants
      await _loadParticipants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete participant: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Participant Management'),
        backgroundColor: primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _participants.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No participants found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Participants will appear here once they register',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _participants.length,
        itemBuilder: (context, index) {
          final participant = _participants[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: darkColor.withOpacity(0.1),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: primaryColor,
                        child: Text(
                          'U', // Placeholder for user initial
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User ${participant.id}', // Placeholder name
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                            Text(
                              participant.event.title,
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(participant.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          participant.statusDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Category: ${participant.category}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Registered: ${_formatDate(participant.registrationDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  if (participant.bibNumber != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'BIB: ${participant.bibNumber}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (participant.status == 'pending' || participant.status == 'registered')
                        ElevatedButton(
                          onPressed: () => _confirmParticipant(participant),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Confirm'),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _deleteParticipant(participant),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'registered':
      case 'upcoming':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}