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

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _venueController = TextEditingController();
  final _participantLimitController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _registrationOpenDate;
  DateTime _registrationDeadline = DateTime.now().add(const Duration(days: 30));
  bool _featured = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _venueController.dispose();
    _participantLimitController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, DateTime? initialDate, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _selectDateTime(BuildContext context, DateTime initialDate, Function(DateTime) onDateTimeSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (time != null) {
        final DateTime dateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        onDateTimeSelected(dateTime);
      }
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final eventData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'city': _cityController.text.trim(),
        'country': _countryController.text.trim(),
        'venue': _venueController.text.trim().isEmpty ? null : _venueController.text.trim(),
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        'registration_open_date': _registrationOpenDate?.toIso8601String(),
        'registration_deadline': _registrationDeadline.toIso8601String(),
        'participant_limit': int.tryParse(_participantLimitController.text.trim()) ?? 0,
        'featured': _featured,
        'status': 'upcoming',
      };

      final createdEvent = await ApiService.instance.createEvent(eventData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event "${createdEvent.title}" created successfully')),
        );
        Navigator.pop(context, createdEvent);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: primaryColor,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createEvent,
            style: TextButton.styleFrom(foregroundColor: whiteColor),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: whiteColor),
                  )
                : const Text('Create'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter event description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // City and Country
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter city';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter country';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Venue
              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(
                  labelText: 'Venue (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Maximum Registrants
              TextFormField(
                controller: _participantLimitController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Registrants *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter 0 for unlimited',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter maximum registrants';
                  }
                  final num = int.tryParse(value.trim());
                  if (num == null || num < 0) {
                    return 'Please enter a valid number (>= 0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Start Date
              ListTile(
                title: Text(
                  _startDate == null
                      ? 'Select Start Date *'
                      : 'Start Date: ${_startDate!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDateTime(
                  context,
                  _startDate ?? DateTime.now(),
                  (date) => setState(() => _startDate = date),
                ),
              ),

              // End Date
              ListTile(
                title: Text(
                  _endDate == null
                      ? 'Select End Date (optional)'
                      : 'End Date: ${_endDate!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDateTime(
                  context,
                  _endDate ?? (_startDate ?? DateTime.now()),
                  (date) => setState(() => _endDate = date),
                ),
              ),

              // Registration Open Date
              ListTile(
                title: Text(
                  _registrationOpenDate == null
                      ? 'Registration Opens (optional)'
                      : 'Registration Opens: ${_registrationOpenDate!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDateTime(
                  context,
                  _registrationOpenDate ?? DateTime.now(),
                  (date) => setState(() => _registrationOpenDate = date),
                ),
              ),

              // Registration Deadline
              ListTile(
                title: Text(
                  'Registration Deadline: ${_registrationDeadline.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDateTime(
                  context,
                  _registrationDeadline,
                  (date) => setState(() => _registrationDeadline = date),
                ),
              ),

              // Featured
              SwitchListTile(
                title: const Text('Featured Event'),
                value: _featured,
                onChanged: (value) => setState(() => _featured = value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}