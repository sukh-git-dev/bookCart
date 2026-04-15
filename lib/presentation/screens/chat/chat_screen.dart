import 'package:bookcart/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const List<_ChatPreview> _allChats = [
    _ChatPreview(
      name: 'Aman Verma',
      bookTitle: 'Engineering Mechanics',
      status: 'Interested buyer',
      lastMessage: 'Is this book still available?',
      time: '10:24 AM',
      unreadCount: 2,
      priceTag: 'Rs 420',
      messages: [
        _ChatMessage(
          text: 'Hi, I saw your listing for Engineering Mechanics.',
          isMine: false,
          time: '10:11 AM',
        ),
        _ChatMessage(
          text: 'Yes, it is available and in good condition.',
          isMine: true,
          time: '10:14 AM',
        ),
        _ChatMessage(
          text: 'Is this book still available?',
          isMine: false,
          time: '10:24 AM',
        ),
      ],
    ),
    _ChatPreview(
      name: 'Priya Das',
      bookTitle: 'Mathematics Basics',
      status: 'Negotiating',
      lastMessage: 'Can you share the condition of the pages?',
      time: 'Yesterday',
      unreadCount: 0,
      priceTag: 'Rs 280',
      messages: [
        _ChatMessage(
          text: 'Can you share the condition of the pages?',
          isMine: false,
          time: 'Yesterday',
        ),
        _ChatMessage(
          text: 'Pages are clean and only lightly used.',
          isMine: true,
          time: 'Yesterday',
        ),
      ],
    ),
    _ChatPreview(
      name: 'Rahul Sen',
      bookTitle: 'Competitive Exam Toolkit',
      status: 'Pickup planned',
      lastMessage: 'I can pick it up this evening.',
      time: 'Mon',
      unreadCount: 0,
      priceTag: 'Rs 550',
      messages: [
        _ChatMessage(
          text: 'I can pick it up this evening.',
          isMine: false,
          time: 'Mon',
        ),
        _ChatMessage(
          text: 'That works. Message me before you arrive.',
          isMine: true,
          time: 'Mon',
        ),
      ],
    ),
    _ChatPreview(
      name: 'Sneha Kapoor',
      bookTitle: 'Modern Physics',
      status: 'New message',
      lastMessage: 'Can you hold this till tomorrow afternoon?',
      time: 'Sun',
      unreadCount: 1,
      priceTag: 'Rs 360',
      messages: [
        _ChatMessage(
          text: 'Can you hold this till tomorrow afternoon?',
          isMine: false,
          time: 'Sun',
        ),
        _ChatMessage(
          text: 'Yes, I can keep it aside till 2 PM.',
          isMine: true,
          time: 'Sun',
        ),
      ],
    ),
  ];

  late final TextEditingController _searchController;
  int _selectedChatIndex = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredChats = _allChats.where((chat) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) {
        return true;
      }

      return chat.name.toLowerCase().contains(query) ||
          chat.bookTitle.toLowerCase().contains(query) ||
          chat.lastMessage.toLowerCase().contains(query) ||
          chat.status.toLowerCase().contains(query);
    }).toList();

    if (filteredChats.isEmpty) {
      _selectedChatIndex = 0;
    } else if (_selectedChatIndex >= filteredChats.length) {
      _selectedChatIndex = 0;
    }

    final selectedChat = filteredChats.isEmpty
        ? null
        : filteredChats[_selectedChatIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1000;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, isWide ? 24.h : 130.h),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 1260 : 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isWide) ...[
                    const _ChatHeroCard(),
                    SizedBox(height: 22.h),
                  ],
                  Text(
                    'Chats',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Open a conversation to view buyer messages and reply about listings.',
                    style: TextStyle(
                      fontSize: 14.sp,
                      height: 1.45,
                      color: AppColors.muted,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search buyer chats or book name',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? Container(
                              margin: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: AppColors.primary,
                                size: 18.sp,
                              ),
                            )
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _query = '';
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: AppColors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 16.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22.r),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22.r),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22.r),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: _ChatStatCard(
                          label: 'Unread',
                          value:
                              '${_allChats.fold<int>(0, (sum, chat) => sum + chat.unreadCount)}',
                          icon: Icons.mark_chat_unread_rounded,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _ChatStatCard(
                          label: 'Books',
                          value: '${_allChats.length}',
                          icon: Icons.menu_book_rounded,
                        ),
                      ),
                      if (isWide) ...[
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _ChatStatCard(
                            label: 'Pickup ready',
                            value:
                                '${_allChats.where((chat) => chat.status == 'Pickup planned').length}',
                            icon: Icons.local_shipping_rounded,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 18.h),
                  _RecentConversationSummary(chatCount: filteredChats.length),
                  SizedBox(height: 18.h),
                  if (isWide)
                    SizedBox(
                      height: 720.h,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 380.w,
                            child: _InboxPanel(
                              chats: filteredChats,
                              selectedIndex: _selectedChatIndex,
                              onSelect: (index) {
                                setState(() {
                                  _selectedChatIndex = index;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 18.w),
                          Expanded(
                            child: selectedChat == null
                                ? const _EmptyConversationState()
                                : _ConversationPanel(chat: selectedChat),
                          ),
                        ],
                      ),
                    )
                  else
                    _MobileInboxList(chats: filteredChats),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InboxPanel extends StatelessWidget {
  const _InboxPanel({
    required this.chats,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_ChatPreview> chats;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 12.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Conversations',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${chats.length} visible threads',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Text(
                    'Inbox',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Expanded(
            child: chats.isEmpty
                ? const _EmptyConversationState(compact: true)
                : ListView.separated(
                    padding: EdgeInsets.all(14.w),
                    itemCount: chats.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return _ChatTile(
                        chat: chat,
                        isSelected: index == selectedIndex,
                        onTap: () => onSelect(index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MobileInboxList extends StatelessWidget {
  const _MobileInboxList({required this.chats});

  final List<_ChatPreview> chats;

  @override
  Widget build(BuildContext context) {
    if (chats.isEmpty) {
      return const _EmptyConversationState();
    }

    return Column(
      children: chats
          .map(
            (chat) => Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: _ChatTile(
                chat: chat,
                isSelected: false,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _ChatDetailScreen(chat: chat),
                    ),
                  );
                },
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ConversationPanel extends StatelessWidget {
  const _ConversationPanel({required this.chat});

  final _ChatPreview chat;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                  child: Text(
                    chat.name.characters.first,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.name,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${chat.bookTitle}  •  ${chat.status}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                _HeaderBadge(label: chat.priceTag),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat.bookTitle,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Discuss condition, pricing, and pickup details here.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _HeaderBadge(label: chat.status),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 18.h),
              itemCount: chat.messages.length,
              itemBuilder: (_, index) {
                final message = chat.messages[index];
                return Align(
                  alignment: message.isMine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    constraints: BoxConstraints(maxWidth: 360.w),
                    decoration: BoxDecoration(
                      color: message.isMine
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                        bottomLeft: Radius.circular(
                          message.isMine ? 20.r : 8.r,
                        ),
                        bottomRight: Radius.circular(
                          message.isMine ? 8.r : 20.r,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 13.sp,
                            height: 1.45,
                            color: message.isMine
                                ? Colors.white
                                : AppColors.dark,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          message.time,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: message.isMine
                                ? Colors.white.withValues(alpha: 0.76)
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Reply to ${chat.name.split(' ').first}',
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18.r),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18.r),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  width: 52.w,
                  height: 52.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentConversationSummary extends StatelessWidget {
  const _RecentConversationSummary({required this.chatCount});

  final int chatCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.forum_outlined,
              color: AppColors.primary,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Conversations',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$chatCount active buyer chats',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Text(
              'Inbox',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatDetailScreen extends StatelessWidget {
  const _ChatDetailScreen({required this.chat});

  final _ChatPreview chat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: AppColors.primary.withValues(alpha: 0.14),
              child: Text(
                chat.name.characters.first,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chat.name),
                  Text(
                    chat.bookTitle,
                    style: TextStyle(fontSize: 12.sp, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
          child: _ConversationPanel(chat: chat),
        ),
      ),
    );
  }
}

class _ChatHeroCard extends StatelessWidget {
  const _ChatHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.dark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Buyer Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'Track every inquiry, negotiate faster, and lock pickup plans without leaving the seller workspace.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Inbox-first on mobile, split-view on larger screens.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            width: 96.w,
            height: 118.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(26.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 18.h,
                  child: Icon(
                    Icons.mark_chat_unread_rounded,
                    color: Colors.white,
                    size: 38.sp,
                  ),
                ),
                Positioned(
                  bottom: 18.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'Live',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatStatCard extends StatelessWidget {
  const _ChatStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: TextStyle(fontSize: 11.sp, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.chat,
    required this.isSelected,
    required this.onTap,
  });

  final _ChatPreview chat;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24.r),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.background : AppColors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.3 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26.r,
              backgroundColor: AppColors.surface,
              child: Text(
                chat.name.characters.first,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          chat.name,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        chat.time,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    chat.bookTitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    chat.lastMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.35,
                      color: AppColors.muted,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 9.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          'Book Chat',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Icon(
                        Icons.done_all_rounded,
                        size: 18.sp,
                        color: AppColors.secondary,
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 9.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: Text(
                          chat.time,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      if (chat.unreadCount > 0) ...[
                        SizedBox(width: 10.w),
                        Container(
                          width: 34.w,
                          height: 34.w,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${chat.unreadCount}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _EmptyConversationState extends StatelessWidget {
  const _EmptyConversationState({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: compact ? null : Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(28.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68.w,
                height: 68.w,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary,
                  size: 30.sp,
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'No conversations found',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Try a different search term to find a buyer conversation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  height: 1.45,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatPreview {
  const _ChatPreview({
    required this.name,
    required this.bookTitle,
    required this.status,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.priceTag,
    required this.messages,
  });

  final String name;
  final String bookTitle;
  final String status;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final String priceTag;
  final List<_ChatMessage> messages;
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isMine,
    required this.time,
  });

  final String text;
  final bool isMine;
  final String time;
}
