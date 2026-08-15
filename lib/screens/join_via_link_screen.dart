import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/shopping_provider.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

class JoinViaLinkScreen extends StatefulWidget {
  final String shortCode;
  const JoinViaLinkScreen({super.key, required this.shortCode});

  @override
  State<JoinViaLinkScreen> createState() => _JoinViaLinkScreenState();
}

class _JoinViaLinkScreenState extends State<JoinViaLinkScreen> {
  bool _loading = true;
  bool _joining = false;
  bool _joined = false;
  String? _error;
  Map<String, dynamic>? _inviteData;

  @override
  void initState() {
    super.initState();
    _resolveInvite();
  }

  Future<void> _resolveInvite() async {
    try {
      final data = await FirestoreService.instance
          .getInviteByShortCode(widget.shortCode);
      if (!mounted) return;
      if (data == null) {
        setState(() {
          _loading = false;
          _error = 'This invite link is invalid or has expired.';
        });
      } else {
        setState(() {
          _loading = false;
          _inviteData = data;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load invite. Please try again.';
      });
    }
  }

  Future<void> _joinList() async {
    final user = context.read<AuthProvider>().userProfile;
    if (user == null || _inviteData == null) return;

    setState(() { _joining = true; _error = null; });

    try {
      final listId = _inviteData!['listId'] as String;
      await FirestoreService.instance.joinListById(
        listId: listId,
        userId: user.id,
        displayName: user.displayName,
        email: user.email ?? '',
        photoUrl: user.photoUrl,
      );
      if (!mounted) return;
      context.read<ShoppingProvider>().loadJoinedSharedLists(user.id);
      setState(() { _joining = false; _joined = true; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _joining = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final listName = _inviteData?['listName'] as String? ?? 'Shared List';
    final inviterName = _inviteData?['invitedByName'] as String? ?? 'Someone';

    return Scaffold(
      appBar: AppBar(title: const Text('Join List')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _loading
              ? const CircularProgressIndicator()
              : _joined
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.green, size: 64),
                        const SizedBox(height: 16),
                        Text('You joined "$listName"!',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => context.go(AppConstants.routeHome),
                          child: const Text('Go to Home'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.group_add_rounded,
                            size: 64, color: Colors.purple),
                        const SizedBox(height: 16),
                        if (_error != null) ...[
                          Text(_error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () =>
                                context.go(AppConstants.routeHome),
                            child: const Text('Go to Home'),
                          ),
                        ] else ...[
                          Text('$inviterName invited you to join',
                              style: const TextStyle(fontSize: 14),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text('"$listName"',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 32),
                          FilledButton(
                            onPressed: _joining ? null : _joinList,
                            child: _joining
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Text('Join List'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () =>
                                context.go(AppConstants.routeHome),
                            child: const Text('Not now'),
                          ),
                        ],
                      ],
                    ),
        ),
      ),
    );
  }
}