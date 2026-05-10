import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../config/theme.dart';
import '../../../../shared/models/donation.dart';
import '../../../../shared/models/user.dart';
import '../../../../shared/providers/auth_provider.dart';
import 'volunteer_task_card.dart';

/// Specialized dashboard for Volunteers - Swiggy Partner style
class VolunteerDashboardView extends ConsumerStatefulWidget {
  final List<Donation> donations;
  final VoidCallback onRefresh;
  
  const VolunteerDashboardView({
    super.key,
    required this.donations,
    required this.onRefresh,
  });

  @override
  ConsumerState<VolunteerDashboardView> createState() => _VolunteerDashboardViewState();
}

enum VolunteerTab { available, active, completed }

class _VolunteerDashboardViewState extends ConsumerState<VolunteerDashboardView> {
  VolunteerTab _currentTab = VolunteerTab.available;
  bool _isOnline = true;
  bool _isMapView = false;
  Donation? _selectedDonationOnMap;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    
    // Filter available vs active vs completed pickups
    final availablePickups = widget.donations.where((d) => d.status == 'available').toList();
    final myActiveTasks = widget.donations.where((d) => 
      (d.status == 'claimed' || d.status == 'in-transit') && 
      d.claimedBy == user?.id
    ).toList();
    final completedTasks = widget.donations.where((d) => 
      d.status == 'delivered' && d.claimedBy == user?.id
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 0. Online/Offline Toggle
        _buildOnlineToggle(),

        // 1. Volunteer Stats Header
        _buildStatsHeader(user),
        
        // 2. Task Toggle (Available vs Active vs Completed)
        _buildTaskToggle(),
        
        // 3. Content Area
        Expanded(
          child: !_isOnline 
            ? _buildOfflinePlaceholder()
            : _currentTab == VolunteerTab.available && _isMapView
                ? _buildVolunteerMap(availablePickups)
                : _buildCurrentTabContent(availablePickups, myActiveTasks, completedTasks),
        ),
      ],
    );
  }

  Widget _buildOnlineToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _isOnline ? const Color(0xFF1BAC4B).withOpacity(0.1) : AppTheme.gray.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isOnline ? const Color(0xFF1BAC4B).withOpacity(0.2) : AppTheme.gray.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _isOnline ? const Color(0xFF1BAC4B) : AppTheme.gray,
                  shape: BoxShape.circle,
                  boxShadow: _isOnline ? [
                    BoxShadow(color: const Color(0xFF1BAC4B).withOpacity(0.4), blurRadius: 8, spreadRadius: 2)
                  ] : null,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _isOnline ? "READY FOR PICKUPS" : "OFFLINE",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                  color: _isOnline ? const Color(0xFF1BAC4B) : AppTheme.gray,
                ),
              ),
            ],
          ),
          Switch.adaptive(
            value: _isOnline,
            activeColor: const Color(0xFF1BAC4B),
            onChanged: (val) {
              HapticFeedback.mediumImpact();
              setState(() => _isOnline = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabChip(VolunteerTab.available, "Available"),
                  _buildTabChip(VolunteerTab.active, "Active"),
                  _buildTabChip(VolunteerTab.completed, "History"),
                ],
              ),
            ),
          ),
          if (_currentTab == VolunteerTab.available)
            Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.lightGray),
              ),
              child: IconButton(
                icon: Icon(_isMapView ? Icons.list_rounded : Icons.map_rounded, color: AppTheme.primaryRed),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isMapView = !_isMapView);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabChip(VolunteerTab tab, String label) {
    final isSelected = _currentTab == tab;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentTab = tab);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed : AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryRed : AppTheme.lightGray),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.darkGray,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(List<Donation> available, List<Donation> active, List<Donation> completed) {
    switch (_currentTab) {
      case VolunteerTab.available:
        return _buildTaskList(available, "No pickups available nearby.", Icons.explore_rounded, false);
      case VolunteerTab.active:
        return Column(
          children: [
            if (active.isNotEmpty) _buildTransitSummary(active),
            Expanded(child: _buildTaskList(active, "No active pickups. Go find one!", Icons.local_shipping_rounded, true)),
          ],
        );
      case VolunteerTab.completed:
        return _buildTaskList(completed, "You haven't completed any tasks yet.", Icons.history_rounded, false);
    }
  }

  Widget _buildTaskList(List<Donation> list, String emptyMessage, IconData emptyIcon, bool isActive) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: AppTheme.lightGray),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(color: AppTheme.gray)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) => VolunteerTaskCard(
        donation: list[index],
        isActive: isActive,
        onTap: () => context.push('/donations/track/${list[index].id}'),
      ).animate().fadeIn(delay: Duration(milliseconds: index * 100)).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildTransitSummary(List<Donation> active) {
    final itemsCount = active.length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$itemsCount ${itemsCount == 1 ? 'Donation' : 'Donations'} in Transit",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text(
                  "Keep it safe! Your effort matters.",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "IN TRANSIT",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ),
    ).animate().slideX(begin: -0.1, end: 0).fadeIn();
  }

  Widget _buildStatsHeader(User? user) {
    final stats = user?.volunteerStats;
    final deliveries = stats?.totalDeliveries ?? 0;
    final rating = stats?.rating ?? 0.0;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            children: [
              // Daily Goal Progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: (deliveries % 5) / 5, // Goal of 5 deliveries
                      strokeWidth: 8,
                      backgroundColor: AppTheme.lightGray.withOpacity(0.3),
                      color: AppTheme.primaryRed,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${deliveries % 5}/5',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Text(
                        'GOAL',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.gray),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Vertical Divider
              Container(width: 1, height: 60, color: AppTheme.lightGray),
              const SizedBox(width: 24),
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Done", "$deliveries", Icons.shopping_bag_rounded, AppTheme.primaryRed),
                    _buildStatItem("Points", "${stats?.totalPoints ?? 0}", Icons.monetization_on_rounded, Colors.green),
                    _buildStatItem("Trust", "${stats?.reliabilityScore ?? 100}%", Icons.verified_user_rounded, Colors.blue),
                    _buildStatItem("Rating", rating > 0 ? rating.toStringAsFixed(1) : "N/A", Icons.star_rounded, AppTheme.accentOrange),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        
        // Impact Chart
        _buildImpactChart(),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: AppTheme.gray, fontSize: 10)),
      ],
    );
  }

  Widget _buildImpactChart() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "WEEKLY PERFORMANCE",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.gray, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildChartBar("Mon", 0.4),
                _buildChartBar("Tue", 0.7),
                _buildChartBar("Wed", 0.9),
                _buildChartBar("Thu", 0.5),
                _buildChartBar("Fri", 1.0, isToday: true),
                _buildChartBar("Sat", 0.3),
                _buildChartBar("Sun", 0.0),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildChartBar(String day, double heightFactor, {bool isToday = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: 80 * heightFactor,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isToday 
                ? [AppTheme.primaryRed, const Color(0xFFC0392B)]
                : [AppTheme.lightGray, AppTheme.lightGray.withOpacity(0.5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? AppTheme.primaryRed : AppTheme.gray,
          ),
        ),
      ],
    );
  }

  Widget _buildVolunteerMap(List<Donation> available) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: const LatLng(19.0760, 72.8777), // Default to Mumbai
            initialZoom: 13,
            onTap: (_, __) => setState(() => _selectedDonationOnMap = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.daansetu.app',
            ),
            MarkerLayer(
              markers: available.map((d) {
                final loc = d.pickupLocation;
                final isSelected = _selectedDonationOnMap?.id == d.id;
                
                return Marker(
                  point: LatLng(loc.lat, loc.lng),
                  width: isSelected ? 60 : 40,
                  height: isSelected ? 60 : 40,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedDonationOnMap = d);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.all(isSelected ? 8 : 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryRed : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.cardShadow,
                        border: Border.all(color: AppTheme.primaryRed, width: 2),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.location_on_rounded, 
                          color: isSelected ? Colors.white : AppTheme.primaryRed, 
                          size: isSelected ? 24 : 18
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        
        // Selected Donation Card Overlay
        if (_selectedDonationOnMap != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.offWhite,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.inventory_2_rounded, color: AppTheme.primaryRed),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedDonationOnMap!.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(_selectedDonationOnMap!.ngo?.name ?? 'NGO', style: const TextStyle(color: AppTheme.gray, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _selectedDonationOnMap = null),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.push('/donations/${_selectedDonationOnMap!.id}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.offWhite,
                            foregroundColor: AppTheme.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("DETAILS"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Claim logic
                            context.push('/donations/track/${_selectedDonationOnMap!.id}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("CLAIM"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutBack),
          ),
      ],
    );
  }

  Widget _buildOfflinePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.power_settings_new_rounded, size: 80, color: AppTheme.lightGray),
          const SizedBox(height: 24),
          const Text(
            "You are currently offline",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Go online to see available pickups nearby.",
            style: TextStyle(color: AppTheme.gray),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() => _isOnline = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1BAC4B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("GO ONLINE"),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}
