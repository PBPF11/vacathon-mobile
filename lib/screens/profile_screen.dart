import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';

// CSS Variables from reference
const Color primaryColor = Color(0xFF177FDA);
const Color accentColor = Color(0xFFBBEE63);
const Color darkColor = Color(0xFF0F3057);
const Color textColor = Color(0xFF1B1B1B);
const Color bgColor = Color(0xFFF6F9FC);
const Color whiteColor = Color(0xFFFFFFFF);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late UserProfile _profile;
  bool _isLoading = false;
  bool _isInitialized = false;

  // Form controllers
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _instagramController = TextEditingController();
  final _stravaController = TextEditingController();

  String? _selectedFavoriteDistance;
  DateTime? _selectedBirthDate;

  final List<String> _distanceOptions = [
    '5K', '10K', '21K', '42K', 'ULTRA'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userProfile != null) {
      _profile = authProvider.userProfile!;
      _populateFormFields();
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _populateFormFields() {
    _displayNameController.text = _profile.displayName;
    _bioController.text = _profile.bio ?? '';
    _cityController.text = _profile.city ?? '';
    _countryController.text = _profile.country ?? '';
    _emergencyContactNameController.text = _profile.emergencyContactName ?? '';
    _emergencyContactPhoneController.text = _profile.emergencyContactPhone ?? '';
    _websiteController.text = _profile.website ?? '';
    _instagramController.text = _profile.instagramHandle ?? '';
    _stravaController.text = _profile.stravaProfile ?? '';
    _selectedFavoriteDistance = _profile.favoriteDistance;
    _selectedBirthDate = _profile.birthDate;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProfile = UserProfile(
        id: _profile.id,
        username: _profile.username,
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        avatarUrl: _profile.avatarUrl,
        favoriteDistance: _selectedFavoriteDistance,
        emergencyContactName: _emergencyContactNameController.text.trim().isEmpty
            ? null : _emergencyContactNameController.text.trim(),
        emergencyContactPhone: _emergencyContactPhoneController.text.trim().isEmpty
            ? null : _emergencyContactPhoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        instagramHandle: _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
        stravaProfile: _stravaController.text.trim().isEmpty ? null : _stravaController.text.trim(),
        birthDate: _selectedBirthDate,
        createdAt: _profile.createdAt,
        updatedAt: DateTime.now(),
        history: _profile.history,
        achievements: _profile.achievements,
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateProfile({
        'display_name': updatedProfile.displayName,
        'bio': updatedProfile.bio,
        'city': updatedProfile.city,
        'country': updatedProfile.country,
        'favorite_distance': updatedProfile.favoriteDistance,
        'emergency_contact_name': updatedProfile.emergencyContactName,
        'emergency_contact_phone': updatedProfile.emergencyContactPhone,
        'website': updatedProfile.website,
        'instagram_handle': updatedProfile.instagramHandle,
        'strava_profile': updatedProfile.stravaProfile,
        'birth_date': updatedProfile.birthDate?.toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: primaryColor,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withOpacity(0.15),
                        ),
                        child: _profile.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  _profile.avatarUrl!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Text(
                                  _profile.displayName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Implement image picker
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Image picker coming soon')),
                          );
                        },
                        child: const Text(
                          'Change Photo',
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Basic Information
                _buildSectionTitle('Basic Information'),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Display name is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                    hintText: 'Tell others about your running journey...',
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _countryController,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedFavoriteDistance,
                  decoration: const InputDecoration(
                    labelText: 'Favorite Distance',
                    border: OutlineInputBorder(),
                  ),
                  items: _distanceOptions.map((distance) {
                    return DropdownMenuItem(
                      value: distance,
                      child: Text(distance),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFavoriteDistance = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                InkWell(
                  onTap: _selectBirthDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Birth Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedBirthDate != null
                              ? '${_selectedBirthDate!.month}/${_selectedBirthDate!.day}/${_selectedBirthDate!.year}'
                              : 'Select birth date',
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Emergency Contact
                _buildSectionTitle('Emergency Contact'),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emergencyContactNameController,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Contact Name',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emergencyContactPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Contact Phone',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 32),

                // Social Links
                _buildSectionTitle('Social Links'),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website',
                    border: OutlineInputBorder(),
                    hintText: 'https://yourwebsite.com',
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _instagramController,
                  decoration: const InputDecoration(
                    labelText: 'Instagram Handle',
                    border: OutlineInputBorder(),
                    hintText: '@yourhandle',
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _stravaController,
                  decoration: const InputDecoration(
                    labelText: 'Strava Profile',
                    border: OutlineInputBorder(),
                    hintText: 'https://strava.com/athletes/yourid',
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _stravaController.dispose();
    super.dispose();
  }
}