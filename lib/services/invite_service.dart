import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/constants.dart';

class InviteService {
  InviteService._();
  static final InviteService instance = InviteService._();

  /// Generates an invite link for the given list and invite code.
  String buildInviteLink(String listId, String inviteCode) {
    return '${AppConstants.inviteBaseUrl}?list=$listId&code=$inviteCode';
  }

  /// Builds the invite message using a short link.
  /// [shortCode] — 6-char code, e.g. "X7K2MP".
  /// [listName]  — human-readable list name shown in the message.
  String buildInviteMessage({
    required String inviterName,
    required String listName,
    required String shortCode,
    // Legacy params kept for backward-compatibility — ignored when shortCode provided.
    String? listId,
    String? inviteCode,
  }) {
    final link = '${AppConstants.joinBaseUrl}/$shortCode';
    return '👋 $inviterName has invited you to join "$listName" on ShopShare!\n\n'
        '📱 Get ShopShare on Android\n\n'
        'Tap to join:\n$link';
  }

  /// Legacy overload — builds message with raw list ID (fallback, no short link).
  String buildLegacyInviteMessage({
    required String inviterName,
    required String listId,
  }) {
    return '👋 Hi! $inviterName has invited you to join their shared shopping list on ShopShare.\n\n'
        '📋 List ID:\n$listId\n\n'
        'To join:\n'
        '1. Open ShopShare\n'
        '2. Tap the menu → Manage Lists\n'
        '3. Paste the List ID in "Join a Shared List"\n\n'
        '📱 Get ShopShare on Android';
  }

  // ─── Share via WhatsApp ─────────────────────────────────────────────────────

  Future<bool> shareViaWhatsApp({
    required String inviterName,
    required String listName,
    required String shortCode,
    String? recipientPhone,
  }) async {
    final message = Uri.encodeComponent(
      buildInviteMessage(
        inviterName: inviterName,
        listName: listName,
        shortCode: shortCode,
      ),
    );

    late final Uri uri;
    if (recipientPhone != null && recipientPhone.isNotEmpty) {
      final phone = recipientPhone.replaceAll(RegExp(r'[^\d+]'), '');
      uri = Uri.parse('https://wa.me/$phone?text=$message');
    } else {
      uri = Uri.parse('${AppConstants.whatsAppScheme}$message');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  // ─── Share via Gmail / Email ────────────────────────────────────────────────

  Future<bool> shareViaEmail({
    required String inviterName,
    required String listName,
    required String shortCode,
    String? recipientEmail,
  }) async {
    final subject = Uri.encodeComponent('You\'re invited to join "$listName" on ShopShare!');
    final body = Uri.encodeComponent(
      buildInviteMessage(
        inviterName: inviterName,
        listName: listName,
        shortCode: shortCode,
      ),
    );

    final to = recipientEmail != null ? Uri.encodeComponent(recipientEmail) : '';

    final uri = Uri.parse(
      '${AppConstants.gmailScheme}$to?subject=$subject&body=$body',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  // ─── Share via system share sheet ──────────────────────────────────────────

  Future<void> shareViaSystem({
    required String inviterName,
    required String listName,
    required String shortCode,
  }) async {
    final message = buildInviteMessage(
      inviterName: inviterName,
      listName: listName,
      shortCode: shortCode,
    );
    await SharePlus.instance.share(
      ShareParams(text: message, subject: 'Join my ShopShare list!'),
    );
  }

  // ─── Build short join link ──────────────────────────────────────────────────

  String buildShortLink(String shortCode) {
    return '${AppConstants.joinBaseUrl}/$shortCode';
  }

  // ─── Legacy: copy raw invite link (kept for backward-compat) ───────────────

  String getShareableLink(String listId, String inviteCode) {
    return buildInviteLink(listId, inviteCode);
  }
}