import 'package:flutter_test/flutter_test.dart';

import 'package:shopping_app/models/member.dart';
import 'package:shopping_app/utils/constants.dart';

void main() {
  group('Member', () {
    Member makeMember({
      String id = 'id-1',
      String listId = 'list-1',
      String? userId,
      String email = 'alice@example.com',
      String displayName = 'Alice',
      String? photoUrl,
      String status = MemberStatus.pending,
      String invitedBy = 'uid-0',
      String invitedByName = 'Owner',
    }) {
      return Member(
        id: id,
        listId: listId,
        userId: userId,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        invitedAt: DateTime(2024, 1, 1),
        status: status,
        invitedBy: invitedBy,
        invitedByName: invitedByName,
      );
    }

    test('creates with required fields', () {
      final member = makeMember();

      expect(member.id, 'id-1');
      expect(member.displayName, 'Alice');
      expect(member.email, 'alice@example.com');
      expect(member.status, MemberStatus.pending);
      expect(member.photoUrl, isNull);
    });

    test('isPending / isAccepted flags', () {
      final pending = makeMember(status: MemberStatus.pending);
      final accepted = makeMember(status: MemberStatus.accepted);

      expect(pending.isPending, isTrue);
      expect(pending.isAccepted, isFalse);
      expect(accepted.isPending, isFalse);
      expect(accepted.isAccepted, isTrue);
    });

    test('toLocalMap / fromMap round-trip', () {
      final original = makeMember(
        id: 'id-2',
        userId: 'uid-2',
        photoUrl: 'https://example.com/alice.jpg',
        status: MemberStatus.accepted,
      );

      final map = original.toLocalMap();
      final restored = Member.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.displayName, original.displayName);
      expect(restored.email, original.email);
      expect(restored.status, original.status);
      expect(restored.photoUrl, original.photoUrl);
      expect(restored.userId, original.userId);
    });

    test('copyWith preserves unchanged fields', () {
      final original = makeMember(id: 'id-3', displayName: 'Dave');
      final updated = original.copyWith(displayName: 'David');

      expect(updated.displayName, 'David');
      expect(updated.email, original.email);
      expect(updated.status, original.status);
      expect(updated.id, original.id);
    });

    test('equality is based on id', () {
      final a = makeMember(id: 'same');
      final b = makeMember(id: 'same', displayName: 'Other');
      final c = makeMember(id: 'different');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      final a = makeMember(id: 'same');
      final b = makeMember(id: 'same', displayName: 'Other');

      expect(a.hashCode, b.hashCode);
    });
  });
}
