import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
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
  State<AdminParticipantManagementScreen> createState() =>
      _AdminParticipantManagementScreenState();
}

class _AdminParticipantManagementScreenState
    extends State<AdminParticipantManagementScreen> {
  RegistrationsResponse? _registrationsResponse;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;

  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;

  List<EventRegistration> get _registrations =>
      _registrationsResponse?.registrations ?? [];

  static const Map<String, String> _statusOptions = {
    'pending': 'Pending Review',
    'confirmed': 'Confirmed',
    'waitlisted': 'Waitlisted',
    'cancelled': 'Cancelled',
    'rejected': 'Rejected',
  };

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRegistrations({bool reset = true}) async {
    if (reset) {
      _currentPage = 1;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final filters = <String, String>{};
      if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
        filters['status'] = _selectedStatus!;
      }
      final search = _searchController.text.trim();
      if (search.isNotEmpty) {
        filters['search'] = search;
      }

      final response = await ApiService.instance.getAdminRegistrations(
        page: _currentPage,
        filters: filters.isEmpty ? null : filters,
      );

      if (!mounted) return;
      setState(() {
        if (reset || _registrationsResponse == null) {
          _registrationsResponse = response;
        } else {
          _registrationsResponse = RegistrationsResponse(
            registrations: [..._registrations, ...response.registrations],
            total: response.total,
            hasNext: response.hasNext,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load participants: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _loadMore() {
    if (_registrationsResponse?.hasNext != true || _isLoadingMore) return;
    _currentPage += 1;
    _loadRegistrations(reset: false);
  }

  Future<void> _confirmRegistration(EventRegistration registration) async {
    try {
      await ApiService.instance.confirmAdminRegistration(registration.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participant confirmed successfully.')),
      );
      _loadRegistrations(reset: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm: $e')),
      );
    }
  }

  Future<void> _deleteRegistration(EventRegistration registration) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Participant'),
          content: Text(
            'Delete registration for ${registration.userUsername} - ${registration.event.title}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await ApiService.instance.deleteAdminRegistration(registration.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participant deleted successfully.')),
      );
      _loadRegistrations(reset: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.userProfile;
    final isAdmin = profile?.isStaff == true || profile?.isSuperuser == true;

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text('Participants'),
          backgroundColor: primaryColor,
        ),
        body: Center(
          child: _buildSurfaceCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, color: primaryColor, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Admin access only',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You do not have permission to view this page.',
                  style: TextStyle(color: textColor.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Participants'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildBackdrop(),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          else
            RefreshIndicator(
              onRefresh: () => _loadRegistrations(reset: true),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildFilters(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorCard(_errorMessage!),
                  ],
                  const SizedBox(height: 16),
                  if (_registrations.isEmpty)
                    _buildEmptyState()
                  else
                    ..._registrations.map(_buildRegistrationCard),
                  if (_registrationsResponse?.hasNext == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton(
                        onPressed: _isLoadingMore ? null : _loadMore,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: const BorderSide(color: primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: _isLoadingMore
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(primaryColor),
                                ),
                              )
                            : const Text('Load more participants'),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return _buildSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Participants',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage participants of all events.',
            style: TextStyle(color: textColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return _buildSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by user or event',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: darkColor.withOpacity(0.2)),
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _loadRegistrations(reset: true),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Status',
              filled: true,
              fillColor: bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Status'),
              ),
              ..._statusOptions.entries.map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _loadRegistrations(reset: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: whiteColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          _searchController.clear();
                          setState(() {
                            _selectedStatus = null;
                          });
                          _loadRegistrations(reset: true);
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationCard(EventRegistration registration) {
    final formatter = DateFormat('d MMM yyyy');
    final canConfirm =
        registration.status == 'pending' || registration.status == 'waitlisted';
    final statusLabel =
        _statusOptions[registration.status] ?? registration.status;
    final categoryLabel = (registration.categoryDisplayName != null &&
            registration.categoryDisplayName!.trim().isNotEmpty)
        ? registration.categoryDisplayName!
        : (registration.distanceLabel.isNotEmpty
            ? registration.distanceLabel
            : 'Open Category');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: darkColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  registration.userUsername,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(registration.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: whiteColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            registration.event.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Category: $categoryLabel',
            style: TextStyle(color: textColor.withOpacity(0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            'Registered: ${formatter.format(registration.createdAt)}',
            style: TextStyle(color: textColor.withOpacity(0.7)),
          ),
          if (registration.bibNumber != null &&
              registration.bibNumber!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'BIB: ${registration.bibNumber}',
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (canConfirm)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmRegistration(registration),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: whiteColor,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text('Confirm & Generate BIB'),
                  ),
                ),
              if (canConfirm) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _deleteRegistration(registration),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return primaryColor;
      case 'waitlisted':
        return accentColor.withOpacity(0.9);
      case 'cancelled':
      case 'rejected':
        return Colors.redAccent;
      case 'pending':
      default:
        return Colors.orangeAccent;
    }
  }

  Widget _buildEmptyState() {
    return _buildSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 40,
            color: textColor.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'No participants found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Registrations will appear here once users sign up.',
            style: TextStyle(color: textColor.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return _buildSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildSurfaceCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildBackdrop() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                bgColor,
                bgColor.withOpacity(0.9),
                whiteColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              _buildBubble(
                top: -60,
                right: -40,
                size: 200,
                color: primaryColor.withOpacity(0.12),
              ),
              _buildBubble(
                bottom: -80,
                left: -60,
                size: 260,
                color: accentColor.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
