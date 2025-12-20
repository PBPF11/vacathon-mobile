import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

// Gunakan konstanta warna yang sama dengan screen lain
const Color primaryColor = Color(0xFF177FDA);
const Color bgColor = Color(0xFFF6F9FC);
const Color whiteColor = Color(0xFFFFFFFF);
const Color darkColor = Color(0xFF0F3057);

class RegistrationDetailScreen extends StatefulWidget {
  final String referenceCode;

  const RegistrationDetailScreen({super.key, required this.referenceCode});

  @override
  State<RegistrationDetailScreen> createState() => _RegistrationDetailScreenState();
}

class _RegistrationDetailScreenState extends State<RegistrationDetailScreen> {
  late Future<EventRegistration> _registrationFuture;

  @override
  void initState() {
    super.initState();
    // Memanggil API berdasarkan referenceCode
    _registrationFuture = ApiService.instance.getRegistration(widget.referenceCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Registration Summary'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: FutureBuilder<EventRegistration>(
        future: _registrationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Data tidak ditemukan'));
          }

          final reg = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildStatusCard(reg),
                const SizedBox(height: 16),
                _buildDetailsCard(reg),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(EventRegistration reg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
          const SizedBox(height: 12),
          Text(
            reg.status.toUpperCase(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Reference: ${reg.referenceCode}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(EventRegistration reg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Event Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          _detailRow('Event Name', reg.event.title),
          _detailRow('City', reg.event.city),
          _detailRow('Category', reg.distanceLabel),
          const SizedBox(height: 16),
          const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          _detailRow('Phone', reg.phoneNumber),
          _detailRow('Emergency Contact', reg.emergencyContactName),
          _detailRow('Payment Status', reg.paymentStatus.toUpperCase()),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: darkColor)),
        ],
      ),
    );
  }
}