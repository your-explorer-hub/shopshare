import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/providers/invite_screen_provider.dart';

void main() {
  group('InviteScreenProvider - Initial State', () {
    test('INV-PROV-01: default expandedListId is null', () {
      final provider = InviteScreenProvider();
      expect(provider.expandedListId, isNull);
    });

    test('INV-PROV-02: default isJoining is false', () {
      final provider = InviteScreenProvider();
      expect(provider.isJoining, isFalse);
    });

    test('INV-PROV-03: default joinError is null', () {
      final provider = InviteScreenProvider();
      expect(provider.joinError, isNull);
    });

    test('INV-PROV-04: default isSendingInvite is false', () {
      final provider = InviteScreenProvider();
      expect(provider.isSendingInvite, isFalse);
    });

    test('INV-PROV-05: default emailInviteError is null', () {
      final provider = InviteScreenProvider();
      expect(provider.emailInviteError, isNull);
    });
  });

  group('InviteScreenProvider - List Expansion', () {
    test('INV-PROV-06: toggleExpandedList expands list', () {
      final provider = InviteScreenProvider();
      provider.toggleExpandedList('list-1');
      expect(provider.expandedListId, 'list-1');
    });

    test('INV-PROV-07: toggleExpandedList collapses same list', () {
      final provider = InviteScreenProvider();
      provider.toggleExpandedList('list-1');
      provider.toggleExpandedList('list-1');
      expect(provider.expandedListId, isNull);
    });

    test('INV-PROV-08: toggleExpandedList switches to different list', () {
      final provider = InviteScreenProvider();
      provider.toggleExpandedList('list-1');
      provider.toggleExpandedList('list-2');
      expect(provider.expandedListId, 'list-2');
    });

    test('INV-PROV-09: toggleExpandedList notifies listeners', () {
      final provider = InviteScreenProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.toggleExpandedList('list-1');

      expect(notified, isTrue);
    });
  });

  group('InviteScreenProvider - Join Operation', () {
    test('INV-PROV-10: setJoining(true) sets isJoining', () {
      final provider = InviteScreenProvider();
      provider.setJoining(true);
      expect(provider.isJoining, isTrue);
    });

    test('INV-PROV-11: setJoining(true) clears previous error', () {
      final provider = InviteScreenProvider();
      provider.setJoinError('Previous error');
      provider.setJoining(true);
      expect(provider.joinError, isNull);
    });

    test('INV-PROV-12: setJoining(false) sets isJoining to false', () {
      final provider = InviteScreenProvider();
      provider.setJoining(true);
      provider.setJoining(false);
      expect(provider.isJoining, isFalse);
    });

    test('INV-PROV-13: setJoining notifies listeners', () {
      final provider = InviteScreenProvider();
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setJoining(true);
      provider.setJoining(false);

      expect(notifyCount, 2);
    });

    test('INV-PROV-14: setJoinError sets error message', () {
      final provider = InviteScreenProvider();
      provider.setJoinError('Invalid link');
      expect(provider.joinError, 'Invalid link');
    });

    test('INV-PROV-15: setJoinError stops isJoining', () {
      final provider = InviteScreenProvider();
      provider.setJoining(true);
      provider.setJoinError('Network error');
      expect(provider.isJoining, isFalse);
      expect(provider.joinError, 'Network error');
    });

    test('INV-PROV-16: setJoinError notifies listeners', () {
      final provider = InviteScreenProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setJoinError('Error occurred');

      expect(notified, isTrue);
    });

    test('INV-PROV-17: clearJoinError clears error', () {
      final provider = InviteScreenProvider();
      provider.setJoinError('Error');
      provider.clearJoinError();
      expect(provider.joinError, isNull);
    });

    test('INV-PROV-18: clearJoinError notifies listeners', () {
      final provider = InviteScreenProvider();
      provider.setJoinError('Error');
      var notified = false;
      provider.addListener(() => notified = true);

      provider.clearJoinError();

      expect(notified, isTrue);
    });

    test('INV-PROV-19: clearJoinError is safe when no error', () {
      final provider = InviteScreenProvider();
      expect(() => provider.clearJoinError(), returnsNormally);
    });
  });

  group('InviteScreenProvider - Email Invite Operation', () {
    test('INV-PROV-20: setSendingInvite(true) sets isSendingInvite', () {
      final provider = InviteScreenProvider();
      provider.setSendingInvite(true);
      expect(provider.isSendingInvite, isTrue);
    });

    test('INV-PROV-21: setSendingInvite(true) clears previous error', () {
      final provider = InviteScreenProvider();
      provider.setEmailInviteError('Previous error');
      provider.setSendingInvite(true);
      expect(provider.emailInviteError, isNull);
    });

    test('INV-PROV-22: setSendingInvite(false) sets isSendingInvite to false', () {
      final provider = InviteScreenProvider();
      provider.setSendingInvite(true);
      provider.setSendingInvite(false);
      expect(provider.isSendingInvite, isFalse);
    });

    test('INV-PROV-23: setSendingInvite notifies listeners', () {
      final provider = InviteScreenProvider();
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setSendingInvite(true);
      provider.setSendingInvite(false);

      expect(notifyCount, 2);
    });

    test('INV-PROV-24: setEmailInviteError sets error message', () {
      final provider = InviteScreenProvider();
      provider.setEmailInviteError('Invalid email');
      expect(provider.emailInviteError, 'Invalid email');
    });

    test('INV-PROV-25: setEmailInviteError stops isSendingInvite', () {
      final provider = InviteScreenProvider();
      provider.setSendingInvite(true);
      provider.setEmailInviteError('Email failed');
      expect(provider.isSendingInvite, isFalse);
      expect(provider.emailInviteError, 'Email failed');
    });

    test('INV-PROV-26: setEmailInviteError notifies listeners', () {
      final provider = InviteScreenProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setEmailInviteError('Error occurred');

      expect(notified, isTrue);
    });

    test('INV-PROV-27: clearEmailInviteError clears error', () {
      final provider = InviteScreenProvider();
      provider.setEmailInviteError('Error');
      provider.clearEmailInviteError();
      expect(provider.emailInviteError, isNull);
    });

    test('INV-PROV-28: clearEmailInviteError notifies listeners', () {
      final provider = InviteScreenProvider();
      provider.setEmailInviteError('Error');
      var notified = false;
      provider.addListener(() => notified = true);

      provider.clearEmailInviteError();

      expect(notified, isTrue);
    });

    test('INV-PROV-29: clearEmailInviteError is safe when no error', () {
      final provider = InviteScreenProvider();
      expect(() => provider.clearEmailInviteError(), returnsNormally);
    });
  });

  group('InviteScreenProvider - Reset Functionality', () {
    test('INV-PROV-30: reset restores all defaults', () {
      final provider = InviteScreenProvider();

      // Set non-default values
      provider.toggleExpandedList('list-1');
      provider.setJoining(true);
      provider.setJoinError('Join error');
      provider.setSendingInvite(true);
      provider.setEmailInviteError('Email error');

      // Reset
      provider.reset();

      // Verify all defaults restored
      expect(provider.expandedListId, isNull);
      expect(provider.isJoining, isFalse);
      expect(provider.joinError, isNull);
      expect(provider.isSendingInvite, isFalse);
      expect(provider.emailInviteError, isNull);
    });

    test('INV-PROV-31: reset notifies listeners', () {
      final provider = InviteScreenProvider();
      provider.setJoining(true);
      var notified = false;
      provider.addListener(() => notified = true);

      provider.reset();

      expect(notified, isTrue);
    });

    test('INV-PROV-32: reset is idempotent', () {
      final provider = InviteScreenProvider();
      provider.reset();
      provider.reset();

      expect(provider.isJoining, isFalse);
      expect(provider.joinError, isNull);
    });
  });

  group('InviteScreenProvider - State Machine Scenarios', () {
    test('INV-PROV-33: successful join flow', () {
      final provider = InviteScreenProvider();

      // Start joining
      provider.setJoining(true);
      expect(provider.isJoining, isTrue);
      expect(provider.joinError, isNull);

      // Join succeeds (handled externally)
      provider.setJoining(false);
      expect(provider.isJoining, isFalse);
      expect(provider.joinError, isNull);
    });

    test('INV-PROV-34: failed join flow', () {
      final provider = InviteScreenProvider();

      // Start joining
      provider.setJoining(true);
      expect(provider.isJoining, isTrue);

      // Join fails
      provider.setJoinError('Invalid link code');
      expect(provider.isJoining, isFalse);
      expect(provider.joinError, 'Invalid link code');
    });

    test('INV-PROV-35: retry after join error', () {
      final provider = InviteScreenProvider();

      // First attempt fails
      provider.setJoining(true);
      provider.setJoinError('Network error');

      // Retry - error should clear
      provider.setJoining(true);
      expect(provider.isJoining, isTrue);
      expect(provider.joinError, isNull);
    });

    test('INV-PROV-36: successful email invite flow', () {
      final provider = InviteScreenProvider();

      // Start sending
      provider.setSendingInvite(true);
      expect(provider.isSendingInvite, isTrue);
      expect(provider.emailInviteError, isNull);

      // Send succeeds
      provider.setSendingInvite(false);
      expect(provider.isSendingInvite, isFalse);
      expect(provider.emailInviteError, isNull);
    });

    test('INV-PROV-37: failed email invite flow', () {
      final provider = InviteScreenProvider();

      // Start sending
      provider.setSendingInvite(true);
      expect(provider.isSendingInvite, isTrue);

      // Send fails
      provider.setEmailInviteError('Invalid email format');
      expect(provider.isSendingInvite, isFalse);
      expect(provider.emailInviteError, 'Invalid email format');
    });

    test('INV-PROV-38: retry after email invite error', () {
      final provider = InviteScreenProvider();

      // First attempt fails
      provider.setSendingInvite(true);
      provider.setEmailInviteError('Network timeout');

      // Retry - error should clear
      provider.setSendingInvite(true);
      expect(provider.isSendingInvite, isTrue);
      expect(provider.emailInviteError, isNull);
    });

    test('INV-PROV-39: join and email invite are independent', () {
      final provider = InviteScreenProvider();

      // Set join state
      provider.setJoining(true);
      provider.setJoinError('Join error');

      // Email invite state should be unaffected
      expect(provider.isSendingInvite, isFalse);
      expect(provider.emailInviteError, isNull);
    });

    test('INV-PROV-40: list expansion during operations', () {
      final provider = InviteScreenProvider();

      // Start operations
      provider.setJoining(true);
      provider.setSendingInvite(true);

      // Toggle list - should not affect operations
      provider.toggleExpandedList('list-1');

      expect(provider.expandedListId, 'list-1');
      expect(provider.isJoining, isTrue);
      expect(provider.isSendingInvite, isTrue);
    });
  });
}
