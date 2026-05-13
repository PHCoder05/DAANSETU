import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../shared/models/donation.dart';
import '../../../../shared/widgets/smart_donation_image.dart';

class NgoInventoryView extends StatelessWidget {
  final List<Donation> inventory;
  final VoidCallback onRefresh;
  final Function(Donation item, String action) onAction;

  const NgoInventoryView({
    super.key,
    required this.inventory,
    required this.onRefresh,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final expiringSoon = inventory.where((d) {
      if (d.expiryDate == null) return false;
      final daysLeft = d.expiryDate!.difference(DateTime.now()).inDays;
      return daysLeft >= 0 && daysLeft <= 3;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Inventory Stats
        _buildInventoryStats(),

        // 2. Expiring Soon Highlight
        if (expiringSoon.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.timer_rounded, color: AppTheme.error, size: 20),
                const SizedBox(width: 8),
                Text(
                  'EXPIRING SOON',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: expiringSoon.length,
              itemBuilder: (context, index) => _buildExpiringCard(expiringSoon[index]),
            ),
          ),
        ],

        // 3. All Inventory
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            'Current Inventory (${inventory.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        
        Expanded(
          child: inventory.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: inventory.length,
                itemBuilder: (context, index) => _buildInventoryItem(inventory[index]),
              ),
        ),
      ],
    );
  }

  Widget _buildInventoryStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Items', '${inventory.length}', Icons.inventory_2_rounded, AppTheme.primaryRed),
          _buildStatItem('Needs Action', '${inventory.where((d) => d.expiryDate != null && d.expiryDate!.isBefore(DateTime.now().add(const Duration(days: 2)))).length}', Icons.warning_amber_rounded, AppTheme.warning),
          _buildStatItem('Recently Added', '${inventory.where((d) => d.deliveryDate != null && d.deliveryDate!.isAfter(DateTime.now().subtract(const Duration(days: 1)))).length}', Icons.new_releases_rounded, AppTheme.success),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: AppTheme.gray, fontSize: 10)),
      ],
    );
  }

  Widget _buildExpiringCard(Donation item) {
    final daysLeft = item.expiryDate!.difference(DateTime.now()).inDays;
    
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 80,
              width: double.infinity,
              child: SmartDonationImage(
                imageUrl: item.images.isNotEmpty ? item.images.first : null,
                category: item.category,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    daysLeft == 0 ? 'Expires Today' : 'Expires in $daysLeft days',
                    style: const TextStyle(color: AppTheme.error, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryItem(Donation item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightGray.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 60,
              height: 60,
              child: SmartDonationImage(
                imageUrl: item.images.isNotEmpty ? item.images.first : null,
                category: item.category,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  "Added ${DateFormat('MMM dd').format(item.deliveryDate ?? item.updatedAt)}",
                  style: const TextStyle(color: AppTheme.gray, fontSize: 11),
                ),
                if (item.expiryDate != null)
                  Text(
                    "Exp: ${DateFormat('MMM dd, yyyy').format(item.expiryDate!)}",
                    style: TextStyle(
                      color: item.expiryDate!.isBefore(DateTime.now().add(const Duration(days: 2))) 
                        ? AppTheme.error 
                        : AppTheme.gray,
                      fontSize: 11,
                      fontWeight: item.expiryDate!.isBefore(DateTime.now().add(const Duration(days: 2))) 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ),
          _buildActionButtons(item),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Donation item) {
    return Row(
      children: [
        IconButton(
          onPressed: () => onAction(item, 'used'),
          icon: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 20),
          tooltip: 'Mark as Used',
        ),
        IconButton(
          onPressed: () => onAction(item, 'disposed'),
          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.gray, size: 20),
          tooltip: 'Remove from Inventory',
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.lightGray),
          SizedBox(height: 16),
          Text('Inventory is empty', style: TextStyle(color: AppTheme.gray, fontSize: 16)),
          Text('Claim and receive donations to see them here.', style: TextStyle(color: AppTheme.gray, fontSize: 12)),
        ],
      ),
    );
  }
}
