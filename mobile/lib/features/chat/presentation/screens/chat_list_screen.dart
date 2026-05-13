import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../core/api/api_client.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getConversations();
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['data'] != null && data['data']['conversations'] != null) {
           final List conversations = data['data']['conversations'];
           
           setState(() {
             _conversations = conversations.map((conv) {
               final otherUser = conv['otherUser'];
               final lastMessage = conv['lastMessage'];
               
               return {
                 'id': otherUser['_id'] ?? otherUser['id'],
                 'name': otherUser['name'] ?? 'User',
                 'image': otherUser['profileImage'],
                 'lastMessage': lastMessage['content'] ?? '',
                 'time': DateTime.tryParse(lastMessage['createdAt']) ?? DateTime.now(),
                 'role': otherUser['role'] ?? 'user',
               };
             }).toList();
           });
        }
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      if (mounted) {
        // CustomSnackBar.error(context, 'Failed to load messages');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: CustomScrollView(
        slivers: [
          // Glassmorphism Header
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppTheme.primaryRed,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Messages',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryRed, Color(0xFFD32F2F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      Icons.chat_bubble_rounded,
                      size: 150,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          // Content
          if (_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppLoader.listSkeleton(itemCount: 6),
              ),
            )
          else if (_conversations.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppTheme.primaryRed.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No messages yet', 
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start connecting with NGOS and Donors!',
                      style: TextStyle(color: AppTheme.gray),
                    ),
                  ],
                ).animate().fade().scale(),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final chat = _conversations[index];
                    return _ChatListItem(chat: chat)
                        .animate(delay: Duration(milliseconds: index * 50))
                        .fade()
                        .slideX(begin: 0.1, end: 0);
                  },
                  childCount: _conversations.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final Map<String, dynamic> chat;
  
  const _ChatListItem({required this.chat});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/chat/${chat['id']}', extra: {'name': chat['name']});
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.offWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.3), width: 2),
                  ),
                  child: ClipOval(
                    child: chat['image'] != null
                      ? Image.network(
                          '${AppConstants.apiBaseUrl.replaceAll('/api', '')}${chat['image']}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                  chat['name'].isNotEmpty ? chat['name'][0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                      color: AppTheme.primaryRed,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                  ),
                              ),
                          ),
                        )
                      : Center(
                          child: Text(
                            chat['name'].isNotEmpty ? chat['name'][0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: AppTheme.primaryRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            chat['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.charcoal,
                            ),
                          ),
                          Text(
                            _formatTime(chat['time']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.gray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chat['lastMessage'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.gray,
                          fontSize: 14, 
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
      return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}
