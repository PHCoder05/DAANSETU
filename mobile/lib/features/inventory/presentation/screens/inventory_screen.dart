import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

import '../providers/inventory_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: const Text('NGO Inventory', style: TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryRed,
          unselectedLabelColor: AppTheme.gray,
          indicatorColor: AppTheme.primaryRed,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'In Stock'),
            Tab(text: 'Distributed'),
          ],
        ),
      ),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
        error: (err, stack) => Center(child: Text('Error loading inventory: $err')),
        data: (items) {
          final inStock = items.where((d) => d['status'] == 'in_stock').toList();
          final distributed = items.where((d) => d['status'] == 'distributed').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInventoryList(inStock, true),
              _buildInventoryList(distributed, false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInventoryList(List<dynamic> items, bool isInStock) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: AppTheme.lightGray),
            const SizedBox(height: 16),
            Text(
              isInStock ? 'Your stock is empty.' : 'No distribution records yet.',
              style: const TextStyle(color: AppTheme.gray, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ).animate().fadeIn().scale(),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        return _InventoryCard(
          item: item, 
          isInStock: isInStock, 
          onDistribute: () => _showDistributeModal(item),
        );
      },
    ).animate().fadeIn();
  }

  void _showDistributeModal(dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DistributeForm(
        item: item,
        onSuccess: () {
          ref.invalidate(inventoryProvider);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _DistributeForm extends ConsumerStatefulWidget {
  final dynamic item;
  final VoidCallback onSuccess;

  const _DistributeForm({required this.item, required this.onSuccess});

  @override
  ConsumerState<_DistributeForm> createState() => _DistributeFormState();
}

class _DistributeFormState extends ConsumerState<_DistributeForm> {
  final _formKey = GlobalKey<FormState>();
  final _beneficiaryController = TextEditingController();
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController();
  bool _isLoading = false;
  File? _proofImageFile;
  String? _proofImageBase64;

  @override
  void initState() {
    super.initState();
    _quantityController.text = (widget.item['quantity'] ?? 0).toString();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 800,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      
      setState(() {
        _proofImageFile = file;
        _proofImageBase64 = 'data:image/jpeg;base64,$base64String';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final maxQuantity = item['quantity'] ?? 0;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Deliver Impact',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.black),
            ),
            Text(
              'Hand over stock to beneficiaries.',
              style: TextStyle(color: AppTheme.gray, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            
            // Item Info Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryRed.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2, color: AppTheme.primaryRed),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Available: $maxQuantity Units', style: const TextStyle(fontSize: 12, color: AppTheme.darkGray)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            TextFormField(
              controller: _beneficiaryController,
              decoration: AppTheme.inputDecoration('Beneficiary Name / Group').copyWith(
                prefixIcon: const Icon(Icons.people_outline, size: 20),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _locationController,
              decoration: AppTheme.inputDecoration('Distribution Point').copyWith(
                prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: AppTheme.inputDecoration('Quantity to Hand Over').copyWith(
                prefixIcon: const Icon(Icons.numbers_outlined, size: 20),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final q = int.tryParse(v);
                if (q == null || q <= 0) return 'Invalid quantity';
                if (q > maxQuantity) return 'Max available: $maxQuantity';
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Photo Evidence Section
            const Text(
              'Proof of Handover',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.offWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.lightGray, width: 2),
                  image: _proofImageFile != null
                      ? DecorationImage(image: FileImage(_proofImageFile!), fit: BoxFit.cover)
                      : null,
                ),
                child: _proofImageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined, color: AppTheme.gray, size: 32),
                          const SizedBox(height: 8),
                          Text('Tap to Capture Photo', style: TextStyle(color: AppTheme.gray, fontWeight: FontWeight.bold)),
                          const Text('Mandatory Verification', style: TextStyle(color: AppTheme.primaryRed, fontSize: 10)),
                        ],
                      )
                    : Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                          onPressed: () => setState(() {
                            _proofImageFile = null;
                            _proofImageBase64 = null;
                          }),
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Confirm Handover', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_proofImageBase64 == null) {
      CustomSnackBar.error(context, 'Photo evidence is required for verification.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.distributeItem(widget.item['id'], {
        'beneficiaryName': _beneficiaryController.text.trim(),
        'location': _locationController.text.trim(),
        'quantity': int.parse(_quantityController.text.trim()),
        'proofImage': _proofImageBase64,
      });
      CustomSnackBar.success(context, 'Impact logged successfully');
      widget.onSuccess();
    } catch (e) {
      CustomSnackBar.error(context, 'Failed to log distribution');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _InventoryCard extends StatelessWidget {
  final dynamic item;
  final bool isInStock;
  final VoidCallback onDistribute;

  const _InventoryCard({required this.item, required this.isInStock, required this.onDistribute});

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? 'Unknown Item';
    final quantity = item['quantity'] ?? 0;
    final receivedAt = item['receivedAt'] != null ? DateTime.parse(item['receivedAt']) : DateTime.now();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryRed),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item['category'] ?? 'General'} • $quantity Units',
                      style: TextStyle(color: AppTheme.darkGray, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.gray),
              const SizedBox(width: 6),
              Text(
                'Received ${DateFormat.yMMMd().format(receivedAt)}',
                style: TextStyle(color: AppTheme.gray, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (item['distributionHistory']?.isNotEmpty == true)
                Row(
                  children: [
                    Icon(Icons.history, size: 14, color: AppTheme.success),
                    const SizedBox(width: 4),
                    const Text('Logged', style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
            ],
          ),
          if (isInStock) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onDistribute,
                icon: const Icon(Icons.volunteer_activism, size: 18),
                label: const Text('Distribute'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = item['status'] == 'in_stock' ? 'In Stock' : 'Distributed';
    final color = item['status'] == 'in_stock' ? AppTheme.success : AppTheme.darkGray;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
