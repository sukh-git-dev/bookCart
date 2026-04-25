import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/core/utils/app_animation_utils.dart';
import 'package:bookcart/data/models/chat_model.dart';
import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/logic/cubits/auth_cubit.dart';
import 'package:bookcart/logic/cubits/chat_cubit.dart';
import 'package:bookcart/logic/cubits/chat_state.dart';
import 'package:bookcart/presentation/widgets/app_loading_indicator.dart';
import 'package:bookcart/presentation/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TextEditingController _searchController;
  String _query = '';
  String? _watchingUserId;

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

  void _watchChats(UserModel? user) {
    if (user == null || _watchingUserId == user.id) {
      return;
    }

    _watchingUserId = user.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<ChatCubit>().watchChatsForUser(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    _watchChats(user);

    if (user == null) {
      return const Center(
        child: AppLoadingIndicator(label: 'Loading your chat account...'),
      );
    }

    return BlocConsumer<ChatCubit, ChatState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppToast.show(
            context,
            message: state.errorMessage!,
            type: AppToastType.error,
          );
          context.read<ChatCubit>().clearFeedback();
          return;
        }

        if (state.successMessage != null) {
          context.read<ChatCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        final query = _query.trim().toLowerCase();
        final filteredThreads = state.threads.where((thread) {
          if (query.isEmpty) {
            return true;
          }

          return thread.displayNameFor(user.id).toLowerCase().contains(query) ||
              thread.bookTitle.toLowerCase().contains(query) ||
              thread.displayLastMessage.toLowerCase().contains(query);
        }).toList();
        final selectedThread = state.selectedThread;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1000;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20.w,
                16.h,
                20.w,
                isWide ? 24.h : 130.h,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 1260 : 760),
                  child: AppStaggeredColumn(
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
                        'Buyer and seller messages update live as new replies arrive.',
                        style: TextStyle(
                          fontSize: 14.sp,
                          height: 1.45,
                          color: AppColors.muted,
                        ),
                      ),
                      SizedBox(height: 18.h),
                      _ChatSearchField(
                        controller: _searchController,
                        query: _query,
                        onChanged: (value) {
                          setState(() {
                            _query = value;
                          });
                        },
                        onClear: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                          });
                        },
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: _ChatStatCard(
                              label: 'Live chats',
                              value: '${state.threads.length}',
                              icon: Icons.forum_rounded,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _ChatStatCard(
                              label: 'Visible',
                              value: '${filteredThreads.length}',
                              icon: Icons.menu_book_rounded,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18.h),
                      if (state.isLoadingThreads)
                        const _ChatLoadingCard()
                      else if (isWide)
                        SizedBox(
                          height: 720.h,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 390.w,
                                child: _ThreadList(
                                  threads: filteredThreads,
                                  selectedThreadId: selectedThread?.id,
                                  currentUserId: user.id,
                                  onSelect: (thread) => context
                                      .read<ChatCubit>()
                                      .selectThread(thread.id),
                                ),
                              ),
                              SizedBox(width: 18.w),
                              Expanded(
                                child: selectedThread == null
                                    ? const _EmptyConversationState()
                                    : _ConversationPanel(
                                        thread: selectedThread,
                                        messages: state.messages,
                                        currentUser: user,
                                        isSending: state.isSending,
                                      ),
                              ),
                            ],
                          ),
                        )
                      else
                        _MobileThreadList(
                          threads: filteredThreads,
                          currentUser: user,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ChatSearchField extends StatelessWidget {
  const _ChatSearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search chats or book name',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: query.isEmpty
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
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
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
          borderSide: BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _ThreadList extends StatelessWidget {
  const _ThreadList({
    required this.threads,
    required this.selectedThreadId,
    required this.currentUserId,
    required this.onSelect,
  });

  final List<ChatThreadModel> threads;
  final String? selectedThreadId;
  final String currentUserId;
  final ValueChanged<ChatThreadModel> onSelect;

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
                  child: Text(
                    'Recent Conversations',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                _HeaderBadge(label: 'Live'),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Expanded(
            child: threads.isEmpty
                ? const _EmptyConversationState(compact: true)
                : ListView.separated(
                    padding: EdgeInsets.all(14.w),
                    itemCount: threads.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final thread = threads[index];
                      return _ThreadTile(
                        thread: thread,
                        currentUserId: currentUserId,
                        isSelected: thread.id == selectedThreadId,
                        onTap: () => onSelect(thread),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MobileThreadList extends StatelessWidget {
  const _MobileThreadList({required this.threads, required this.currentUser});

  final List<ChatThreadModel> threads;
  final UserModel currentUser;

  @override
  Widget build(BuildContext context) {
    if (threads.isEmpty) {
      return const _EmptyConversationState();
    }

    return Column(
      children: [
        for (final thread in threads)
          Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: _ThreadTile(
              thread: thread,
              currentUserId: currentUser.id,
              isSelected: false,
              onTap: () {
                context.read<ChatCubit>().selectThread(thread.id);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _MobileConversationScreen(
                      thread: thread,
                      currentUser: currentUser,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _MobileConversationScreen extends StatelessWidget {
  const _MobileConversationScreen({
    required this.thread,
    required this.currentUser,
  });

  final ChatThreadModel thread;
  final UserModel currentUser;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        final liveThread = state.selectedThread ?? thread;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 0,
            title: Row(
              children: [
                _Avatar(name: liveThread.displayNameFor(currentUser.id)),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(liveThread.displayNameFor(currentUser.id)),
                      Text(
                        liveThread.bookTitle,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.muted,
                        ),
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
              child: _ConversationPanel(
                thread: liveThread,
                messages: state.messages,
                currentUser: currentUser,
                isSending: state.isSending,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConversationPanel extends StatefulWidget {
  const _ConversationPanel({
    required this.thread,
    required this.messages,
    required this.currentUser,
    required this.isSending,
  });

  final ChatThreadModel thread;
  final List<ChatMessageModel> messages;
  final UserModel currentUser;
  final bool isSending;

  @override
  State<_ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends State<_ConversationPanel> {
  late final TextEditingController _messageController;
  late final ScrollController _messagesScrollController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _messagesScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToLatest());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messagesScrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final sent = await context.read<ChatCubit>().sendMessage(
      sender: widget.currentUser,
      text: text,
    );
    if (!mounted || !sent) {
      return;
    }

    _messageController.clear();
    _jumpToLatest();
  }

  @override
  void didUpdateWidget(covariant _ConversationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thread.id != widget.thread.id ||
        oldWidget.messages.length != widget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToLatest());
    }
  }

  void _jumpToLatest() {
    if (!mounted || !_messagesScrollController.hasClients) {
      return;
    }

    _messagesScrollController.animateTo(
      _messagesScrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final otherName = widget.thread.displayNameFor(widget.currentUser.id);
    final visibleMessages = widget.messages.reversed.toList(growable: false);

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
                _Avatar(name: otherName),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${widget.thread.bookTitle}  •  ${widget.thread.statusFor(widget.currentUser.id)}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                _HeaderBadge(label: widget.thread.priceTag),
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
                    child: Text(
                      widget.thread.bookTitle,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  _HeaderBadge(label: 'Live'),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Expanded(
            child: visibleMessages.isEmpty
                ? const _EmptyMessagesState()
                : ListView.builder(
                    controller: _messagesScrollController,
                    reverse: true,
                    padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 18.h),
                    itemCount: visibleMessages.length,
                    itemBuilder: (_, index) {
                      final message = visibleMessages[index];
                      return _MessageBubble(
                        message: message,
                        isMine: message.senderId == widget.currentUser.id,
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
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Reply to ${otherName.split(' ').first}',
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
                    color: widget.isSending
                        ? AppColors.muted
                        : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: widget.isSending ? null : _send,
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

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.thread,
    required this.currentUserId,
    required this.isSelected,
    required this.onTap,
  });

  final ChatThreadModel thread;
  final String currentUserId;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = thread.displayNameFor(currentUserId);

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
            _Avatar(name: name),
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
                          name,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        thread.displayTime,
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
                    thread.bookTitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    thread.displayLastMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.35,
                      color: AppColors.muted,
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessageModel message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        constraints: BoxConstraints(maxWidth: 360.w),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft: Radius.circular(isMine ? 20.r : 8.r),
            bottomRight: Radius.circular(isMine ? 8.r : 20.r),
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
                color: isMine ? Colors.white : AppColors.dark,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              message.displayTime,
              style: TextStyle(
                fontSize: 10.sp,
                color: isMine
                    ? Colors.white.withValues(alpha: 0.76)
                    : AppColors.muted,
              ),
            ),
          ],
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
                  'Live chats for book inquiries, offers, and pickup plans.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Messages sync instantly for both buyer and seller.',
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
            child: Icon(
              Icons.mark_chat_unread_rounded,
              color: Colors.white,
              size: 40.sp,
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
          Expanded(
            child: Column(
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
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    return CircleAvatar(
      radius: 24.r,
      backgroundColor: AppColors.primary.withValues(alpha: 0.14),
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 16.sp,
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

class _ChatLoadingCard extends StatelessWidget {
  const _ChatLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(28.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: AppColors.border),
      ),
      child: const AppLoadingIndicator(label: 'Loading live chats...'),
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
                'No conversations yet',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Open a book and tap Chat Now to start a live thread.',
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

class _EmptyMessagesState extends StatelessWidget {
  const _EmptyMessagesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.w),
        child: Text(
          'No messages yet. Send the first reply.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.sp,
            height: 1.45,
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
