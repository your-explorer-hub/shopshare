# ShopShare Backend Plan

Purpose: Persistent plan file so every new session can resume instantly.
Last updated: 2026-05-13
Current phase: Phase 1 - Backend Data Layer (IN PROGRESS)

## Phase 1 Scope: Backend Only - No UI changes

Files changed:
- lib/utils/constants.dart - Add MemberStatus.declined
- lib/database/app_database.dart - v5 to v6, invitations table + CRUD
- lib/services/firestore_service.dart - 5 new/modified methods
- lib/providers/shopping_provider.dart - New state + 5 methods

## Firestore invitations Schema
Path: invitations/{inviteId}
Fields: inviteId, listId, listName, invitedByUid, invitedByName,
  recipientEmail (lowercase), status (pending/accepted/declined),
  createdAt Timestamp, expiresAt Timestamp (createdAt + 15 days)

## Step 1 - constants.dart
Add MemberStatus.declined = 'declined'

## Step 2 - AppDatabase v6
New table invitations: id, list_id, list_name, invited_by_name,
  recipient_email, status DEFAULT pending, created_at, expires_at
New methods: upsertInvitation, deleteInvitation, getPendingInvitations, clearInvitations
Update clearAll() to also delete invitations rows

## Step 3 - FirestoreService
A. sendEmailInvite() NEW - 6 validations, expiresAt = createdAt + 15 days
B. getPendingInvitesForUser() NEW - one-time fetch (status==pending, not expired)
C. watchPendingInvitesForUser() NEW - real-time stream for badge count
D. acceptInvitation() MODIFY - add expiry check, status check, tier limit check
E. declineInvite() NEW - status=declined + delete pending member doc
F. getJoinedSharedLists() NEW - client-side filter (type==shared && ownerId!=userId)

sendEmailInvite validations in order:
1. invitedByUid == list.ownerId (only owner can invite)
2. recipientEmail != ownerEmail case-insensitive (no self-invite)
3. members count < maxMembersPerList(ownerTier)
4. member with email not already in list
5. no pending invite already exists for this email+list
6. user account exists for recipientEmail

## Step 4 - ShoppingProvider
New state: _pendingInvites, _joinedSharedLists, _invitesLoading, _inviteStreamSub
New getters: pendingInvites, joinedSharedLists, pendingInviteCount, invitesLoading
New methods: initInviteStream, sendEmailInvite, acceptInvite, declineInvite,
  loadJoinedSharedLists, disposeInviteStream

## Phase 2 - UI (future)
- Home screen invite badge (pendingInviteCount)
- Invite inbox screen with accept/decline
- Email invite send screen
- Lists I Joined section

## Design Decisions
- Expiry: 15 days
- Decline: status=declined + delete pending member doc (not reusable)
- Self-invite: case-insensitive email compare
- getJoinedSharedLists: client-side filter (no extra Firestore query)
- SQLite cache: yes for offline badge count support
