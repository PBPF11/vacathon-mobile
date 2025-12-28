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
  final Event? event;

  const CreateEventScreen({super.key, this.event});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _participantLimitController = TextEditingController();
  final _raceCategoriesController = TextEditingController();
  final _popularityScoreController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime _registrationDeadline = DateTime.now().add(const Duration(days: 30));
  String _status = 'upcoming';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description;
      _cityController.text = widget.event!.city;
      _participantLimitController.text = widget.event!.participantLimit.toString();
      _raceCategoriesController.text = widget.event!.categories.map((c) => c.name).join(', ');
      _popularityScoreController.text = widget.event!.popularityScore.toString();
      _startDate = widget.event!.startDate;
      _endDate = widget.event!.endDate;
      _registrationDeadline = widget.event!.registrationDeadline;
      _status = widget.event!.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _participantLimitController.dispose();
    _raceCategoriesController.dispose();
    _popularityScoreController.dispose();
    super.dispose();
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

  Future<void> _saveEvent() async {
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
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        'registration_deadline': _registrationDeadline.toIso8601String(),
        'participant_limit': int.tryParse(_participantLimitController.text.trim()) ?? 0,
        'status': _status,
        'popularity_score': int.tryParse(_popularityScoreController.text.trim()) ?? 0,
        'race_categories': _raceCategoriesController.text.trim(),
      };

      final savedEvent = widget.event != null
          ? await ApiService.instance.updateEvent(widget.event!.id, eventData)
          : await ApiService.instance.createEvent(eventData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event "${savedEvent.title}" ${widget.event != null ? 'updated' : 'created'} successfully')),
        );
        Navigator.pop(context, savedEvent);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${widget.event != null ? 'update' : 'create'} event: $e')),
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
        title: Text(widget.event != null ? 'Edit Event' : 'Create Event'),
        backgroundColor: primaryColor,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
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

                    // City
                    TextFormField(
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

                    // Race Categories
                    TextFormField(
                      controller: _raceCategoriesController,
                      decoration: const InputDecoration(
                        labelText: 'Race Categories',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. 5K, 10K, Marathon',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
                        DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      ],
                      onChanged: (value) => setState(() => _status = value!),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select status';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Popularity Score
                    TextFormField(
                      controller: _popularityScoreController,
                      decoration: const InputDecoration(
                        labelText: 'Popularity Score',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final num = int.tryParse(value.trim());
                          if (num == null || num < 0) {
                            return 'Please enter a valid number (>= 0)';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Participant Limit
                    TextFormField(
                      controller: _participantLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Participant Limit *',
                        border: OutlineInputBorder(),
                        hintText: 'Enter 0 for unlimited',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter participant limit';
                        }
                        final num = int.tryParse(value.trim());
                        if (num == null || num < 0) {
                          return 'Please enter a valid number (>= 0)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: whiteColor,
                border: Border(top: BorderSide(color: darkColor.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: whiteColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: whiteColor),
                            )
                          : const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}