import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';

// CSS Variables from reference
const Color primaryColor = Color(0xFF177FDA);
const Color accentColor = Color(0xFFBBEE63);
const Color darkColor = Color(0xFF0F3057);
const Color textColor = Color(0xFF1B1B1B);
const Color bgColor = Color(0xFFF6F9FC);
const Color whiteColor = Color(0xFFFFFFFF);

class AdminEventFormScreen extends StatelessWidget {
  final Event? event;

  const AdminEventFormScreen({super.key, this.event});

  @override
  Widget build(BuildContext context) {
    final title = event != null ? 'Edit Event' : 'Add Event';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminEventFormContent(event: event),
      ),
    );
  }
}

class AdminEventFormContent extends StatefulWidget {
  final Event? event;
  final bool showClose;
  final bool inDialog;

  const AdminEventFormContent({
    super.key,
    this.event,
    this.showClose = false,
    this.inDialog = false,
  });

  @override
  State<AdminEventFormContent> createState() => _AdminEventFormContentState();
}

class _AdminEventFormContentState extends State<AdminEventFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _popularityController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _deadlineController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _deadline;
  String _status = 'upcoming';

  List<EventCategory> _categories = [];
  final Set<int> _selectedCategoryIds = {};

  bool _isLoadingCategories = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  bool get _isEditing => widget.event != null;

  static const Map<String, String> _statusOptions = {
    'upcoming': 'Upcoming',
    'ongoing': 'Ongoing',
    'completed': 'Completed',
  };

  @override
  void initState() {
    super.initState();
    _populateInitialValues();
    _loadCategories();
  }

  void _populateInitialValues() {
    final event = widget.event;
    if (event == null) {
      _popularityController.text = '0';
      return;
    }

    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _cityController.text = event.city;
    _popularityController.text = event.popularityScore.toString();

    _startDate = event.startDate;
    _endDate = event.endDate;
    _deadline = event.registrationDeadline;
    _status = _statusOptions.containsKey(event.status) ? event.status : 'upcoming';

    _startDateController.text = _formatDate(event.startDate);
    _endDateController.text = event.endDate != null ? _formatDate(event.endDate!) : '';
    _deadlineController.text = _formatDate(event.registrationDeadline);

    for (final category in event.categories) {
      _selectedCategoryIds.add(category.id);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) {
      return;
    }
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedImage = image;
      _selectedImageBytes = bytes;
    });
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _errorMessage = null;
    });

    try {
      final categories = await ApiService.instance.getEventCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load categories: $e';
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _pickDate({
    required DateTime? currentValue,
    required ValueChanged<DateTime?> onSelected,
  }) async {
    final initial = currentValue ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: whiteColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _deadline == null) {
      setState(() {
        _errorMessage = 'Start date and registration deadline are required.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final popularityScore = int.tryParse(_popularityController.text.trim()) ?? 0;

    final payload = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'city': _cityController.text.trim(),
      'start_date': _formatDate(_startDate!),
      'end_date': _endDate != null ? _formatDate(_endDate!) : null,
      'registration_deadline': _formatDate(_deadline!),
      'categories': _selectedCategoryIds.toList(),
      'status': _status,
      'popularity_score': popularityScore,
    };

    try {
      if (_isEditing) {
        if (_selectedImage != null) {
          await ApiService.instance.updateEventWithImage(
            widget.event!.id,
            payload,
            _selectedImage,
          );
        } else {
          await ApiService.instance.updateEventAdmin(widget.event!.id, payload);
        }
      } else {
        if (_selectedImage != null) {
          await ApiService.instance.createEventWithImage(
            payload,
            _selectedImage!,
          );
        } else {
          await ApiService.instance.createEventAdmin(payload);
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(_isEditing ? 'updated' : 'created');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to save event: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _popularityController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Edit Event' : 'Add Event';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(widget.inDialog ? 18 : 24),
        boxShadow: widget.inDialog
            ? []
            : [
                BoxShadow(
                  color: darkColor.withOpacity(0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showClose)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: bgColor,
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.all(6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.close),
                ),
              ),
            if (widget.showClose) const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fill the form below to ${_isEditing ? 'edit' : 'create'} the event.',
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('Title'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration('Description'),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: _inputDecoration('City'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'City is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _startDateController,
              readOnly: true,
              onTap: () async {
                await _pickDate(
                  currentValue: _startDate,
                  onSelected: (value) {
                    setState(() {
                      _startDate = value;
                      _startDateController.text =
                          value != null ? _formatDate(value) : '';
                    });
                  },
                );
              },
              decoration: _inputDecoration('Start Date').copyWith(
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Start date is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endDateController,
              readOnly: true,
              onTap: () async {
                await _pickDate(
                  currentValue: _endDate ?? _startDate,
                  onSelected: (value) {
                    setState(() {
                      _endDate = value;
                      _endDateController.text =
                          value != null ? _formatDate(value) : '';
                    });
                  },
                );
              },
              decoration: _inputDecoration('End Date').copyWith(
                suffixIcon: _endDate != null
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _endDate = null;
                            _endDateController.text = '';
                          });
                        },
                      )
                    : const Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deadlineController,
              readOnly: true,
              onTap: () async {
                await _pickDate(
                  currentValue: _deadline ?? _startDate,
                  onSelected: (value) {
                    setState(() {
                      _deadline = value;
                      _deadlineController.text =
                          value != null ? _formatDate(value) : '';
                    });
                  },
                );
              },
              decoration: _inputDecoration('Registration Deadline')
                  .copyWith(suffixIcon: const Icon(Icons.calendar_today)),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Registration deadline is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Event Banner',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withOpacity(0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _selectedImageBytes != null
                    ? Image.memory(
                        _selectedImageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : (widget.event?.bannerImage != null &&
                            widget.event!.bannerImage!.isNotEmpty)
                        ? Image.network(
                            widget.event!.bannerImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 40,
                                  color: textColor.withOpacity(0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No banner uploaded',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: whiteColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon: const Icon(Icons.upload),
                  label: Text(
                    _selectedImage == null ? 'Upload Photo' : 'Replace Photo',
                  ),
                ),
                const SizedBox(width: 12),
                if (_selectedImage != null)
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : _clearSelectedImage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: const BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text('Remove'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Race Categories',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoadingCategories)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else if (_categories.isEmpty)
              Text(
                'No categories available. Add categories in the Django admin.',
                style: TextStyle(color: textColor.withOpacity(0.6)),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final selected = _selectedCategoryIds.contains(category.id);
                  return FilterChip(
                    label: Text(category.displayName),
                    selected: selected,
                    selectedColor: accentColor.withOpacity(0.3),
                    checkmarkColor: primaryColor,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedCategoryIds.add(category.id);
                        } else {
                          _selectedCategoryIds.remove(category.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: _inputDecoration('Status'),
              items: _statusOptions.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _status = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _popularityController,
              decoration: _inputDecoration('Popularity Score'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return null;
                }
                final parsed = int.tryParse(value.trim());
                if (parsed == null || parsed < 0) {
                  return 'Popularity score must be a non-negative integer';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: whiteColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
