import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/models/user.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/app_loader.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<User> _users = [];
  List<User> _pendingNgos = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _roleFilter = 'all';
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      
      // Load Users
      final usersResponse = await apiClient.getUsers(limit: 50);
      if (usersResponse.statusCode == 200 && usersResponse.data != null) {
        final responseData = usersResponse.data['data'];
        final List<dynamic> usersData = responseData?['data'] ?? responseData ?? [];
        _users = usersData.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
      }

      // Load Pending NGOs
      final pendingResponse = await apiClient.getPendingNgos();
      if (pendingResponse.statusCode == 200 && pendingResponse.data != null) {
        final responseData = pendingResponse.data['data'];
        final List<dynamic> pendingData = responseData?['data'] ?? responseData ?? [];
        _pendingNgos = pendingData.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
      }

    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, 'Failed to load data');
        debugPrint('AdminUsersScreen error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyNgo(String userId, bool approve) async {
    HapticFeedback.mediumImpact();
    
    // Show confirmation bottom sheet
    final confirmed = await _showConfirmationSheet(
      title: approve ? 'Verify NGO' : 'Reject NGO',
      message: approve 
          ? 'This NGO will be able to claim donations after verification.'
          : 'This NGO will not be able to claim donations.',
      confirmText: approve ? 'Verify' : 'Reject',
      confirmColor: approve ? AppTheme.success : AppTheme.error,
      icon: approve ? Icons.verified_rounded : Icons.cancel_rounded,
    );
    
    if (confirmed != true) return;
    
    try {
      final apiClient = ref.read(apiClientProvider);
      final status = approve ? 'verified' : 'rejected';
      final response = await apiClient.verifyNgo(userId, status);
      
      if (response.statusCode == 200) {
        HapticFeedback.heavyImpact();
        if (!mounted) return;
        CustomSnackBar.success(context, 'NGO ${approve ? "verified" : "rejected"} successfully!');
        _loadData();
      }
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.error(context, 'Action failed');
    }
  }

  Future<void> _toggleUserStatus(User user) async {
    HapticFeedback.mediumImpact();
    
    final newStatus = !user.active;
    final confirmed = await _showConfirmationSheet(
      title: newStatus ? 'Activate User' : 'Deactivate User',
      message: newStatus 
          ? '${user.name} will be able to use the platform.'
          : '${user.name} will be blocked from using the platform.',
      confirmText: newStatus ? 'Activate' : 'Deactivate',
      confirmColor: newStatus ? AppTheme.success : AppTheme.error,
      icon: newStatus ? Icons.check_circle_rounded : Icons.block_rounded,
    );
    
    if (confirmed != true) return;
    
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.toggleUserStatus(user.id);
      
      if (response.statusCode == 200) {
        HapticFeedback.heavyImpact();
        if (!mounted) return;
        CustomSnackBar.success(context, 'User ${newStatus ? "activated" : "deactivated"}');
        _loadData();
      }
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.error(context, 'Action failed');
    }
  }
  
  Future<bool?> _showConfirmationSheet({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required IconData icon,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: confirmColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: confirmColor, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.gray, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(confirmText),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Custom App Bar
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            // Tab Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryRed,
                  unselectedLabelColor: AppTheme.gray,
                  indicatorColor: AppTheme.primaryRed,
                  indicatorWeight: 3,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Pending NGOs'),
                          if (_pendingNgos.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.warning,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_pendingNgos.length}',
                                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('All Users'),
                          if (_users.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accentBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_users.length}',
                                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: _isLoading
              ? _buildLoadingState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPendingNgosList(),
                    _buildAllUsersList(),
                  ],
                ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title Row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Management',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_users.length} users • ${_pendingNgos.length} pending',
                      style: const TextStyle(fontSize: 12, color: AppTheme.gray),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _loadData();
                },
                icon: const Icon(Icons.refresh_rounded),
                color: AppTheme.gray,
              ),
            ],
          ),
        ],
      ),
    ).animate().fade().slideY(begin: -0.1, end: 0);
  }
  
  Widget _buildLoadingState() {
    return const ListSkeleton(itemCount: 6);
  }

  Widget _buildPendingNgosList() {
    if (_pendingNgos.isEmpty) {
      return _buildEmptyState(
        icon: Icons.verified_user_rounded,
        title: 'All caught up!',
        subtitle: 'No pending NGO verifications',
        color: AppTheme.success,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryRed,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingNgos.length,
        itemBuilder: (context, index) {
          final ngo = _pendingNgos[index];
          return _PendingNgoCard(
            ngo: ngo,
            onVerify: () => _verifyNgo(ngo.id, true),
            onReject: () => _verifyNgo(ngo.id, false),
          ).animate(delay: (index * 100).ms).fade().slideX(begin: -0.05, end: 0);
        },
      ),
    );
  }

  Widget _buildAllUsersList() {
    // Apply filters
    var filteredUsers = _users.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user.name.toLowerCase().contains(_searchQuery) ||
          user.email.toLowerCase().contains(_searchQuery);
      final matchesRole = _roleFilter == 'all' || user.role == _roleFilter;
      return matchesSearch && matchesRole;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryRed,
      child: CustomScrollView(
        slivers: [
          // Search & Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        hintStyle: TextStyle(color: AppTheme.gray.withValues(alpha: 0.6)),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.gray),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.close_rounded, color: AppTheme.gray),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Role Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: _roleFilter == 'all',
                          onTap: () => setState(() => _roleFilter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Donors',
                          icon: Icons.person_rounded,
                          color: AppTheme.success,
                          isSelected: _roleFilter == 'donor',
                          onTap: () => setState(() => _roleFilter = 'donor'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'NGOs',
                          icon: Icons.business_rounded,
                          color: AppTheme.primaryBlue,
                          isSelected: _roleFilter == 'ngo',
                          onTap: () => setState(() => _roleFilter = 'ngo'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Admins',
                          icon: Icons.admin_panel_settings_rounded,
                          color: AppTheme.primaryRed,
                          isSelected: _roleFilter == 'admin',
                          onTap: () => setState(() => _roleFilter = 'admin'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // User List
          if (filteredUsers.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(
                icon: Icons.person_search_rounded,
                title: 'No users found',
                subtitle: 'Try adjusting your search or filters',
                color: AppTheme.gray,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final user = filteredUsers[index];
                    return _UserCard(
                      user: user,
                      onToggleStatus: () => _toggleUserStatus(user),
                    ).animate(delay: (index * 50).ms).fade().slideY(begin: 0.05, end: 0);
                  },
                  childCount: filteredUsers.length,
                ),
              ),
            ),
          
          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: color),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.gray),
          ),
        ],
      ).animate().fade().scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

// ============== Helper Widgets ==============

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  
  _SliverTabBarDelegate(this.tabBar);
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }
  
  @override
  double get maxExtent => tabBar.preferredSize.height;
  
  @override
  double get minExtent => tabBar.preferredSize.height;
  
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _FilterChip({
    required this.label,
    this.icon,
    this.color,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.charcoal;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : AppTheme.lightGray,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isSelected ? chipColor : AppTheme.gray),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? chipColor : AppTheme.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onToggleStatus;
  
  const _UserCard({
    required this.user,
    required this.onToggleStatus,
  });
  
  Color _getRoleColor() {
    switch (user.role) {
      case 'admin': return AppTheme.primaryRed;
      case 'ngo': return AppTheme.primaryBlue;
      default: return AppTheme.success;
    }
  }
  
  IconData _getRoleIcon() {
    switch (user.role) {
      case 'admin': return Icons.admin_panel_settings_rounded;
      case 'ngo': return Icons.business_rounded;
      default: return Icons.person_rounded;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [roleColor.withValues(alpha: 0.8), roleColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: user.profileImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(user.profileImage!, fit: BoxFit.cover),
                  )
                : Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getRoleIcon(), size: 12, color: roleColor),
                          const SizedBox(width: 4),
                          Text(
                            user.role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: roleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 12, color: AppTheme.gray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: user.active 
                            ? AppTheme.success.withValues(alpha: 0.1)
                            : AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: user.active ? AppTheme.success : AppTheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.active ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: user.active ? AppTheme.success : AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (user.verified) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified_rounded, size: 14, color: AppTheme.primaryBlue),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Toggle Button
          if (user.role != 'admin')
            IconButton(
              onPressed: onToggleStatus,
              icon: Icon(
                user.active ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                color: user.active ? AppTheme.success : AppTheme.gray,
                size: 36,
              ),
            ),
        ],
      ),
    );
  }
}

class _PendingNgoCard extends StatelessWidget {
  final User ngo;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  
  const _PendingNgoCard({
    required this.ngo,
    required this.onVerify,
    required this.onReject,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.warning.withValues(alpha: 0.1),
                  AppTheme.warning.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      ngo.name.isNotEmpty ? ngo.name[0].toUpperCase() : 'N',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ngo.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ngo.email,
                        style: const TextStyle(fontSize: 13, color: AppTheme.gray),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warning,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pending_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'PENDING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (ngo.ngoDetails?.description != null) ...[
                  Text(
                    ngo.ngoDetails!.description!,
                    style: const TextStyle(color: AppTheme.darkGray, fontSize: 13, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Info Row
                Row(
                  children: [
                    if (ngo.ngoDetails?.registrationNumber != null)
                      _InfoBadge(
                        icon: Icons.badge_outlined,
                        label: 'Reg: ${ngo.ngoDetails!.registrationNumber}',
                      ),
                    if (ngo.phone != null) ...[
                      const SizedBox(width: 8),
                      _InfoBadge(
                        icon: Icons.phone_outlined,
                        label: ngo.phone!,
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onVerify,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Verify'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  
  const _InfoBadge({required this.icon, required this.label});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.gray),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.darkGray),
          ),
        ],
      ),
    );
  }
}
