import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nimbus_2k26_frontend/chat/providers/community_chat_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CommunityChatProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('ensureInitialized creates always-open public room', () async {
      final provider = CommunityChatProvider();

      await provider.ensureInitialized();

      expect(provider.isInitialized, isTrue);
      final publicRoom = provider.roomByName(
        CommunityChatProvider.publicRoomName,
      );
      expect(publicRoom, isNotNull);
      expect(publicRoom!.isPublic, isTrue);
      expect(publicRoom.isLocked, isFalse);
      expect(publicRoom.password, isNull);
      expect(publicRoom.messages.isNotEmpty, isTrue);
    });

    test(
      'createRoom creates unlocked custom room and prevents duplicate names',
      () async {
        final provider = CommunityChatProvider();
        await provider.ensureInitialized();

        final firstCreate = await provider.createRoom(
          name: 'Hostel Chat',
          createdById: 'user-1',
          createdByName: 'Alpha',
          lockRoom: false,
        );
        expect(firstCreate, isNull);

        final createdRoom = provider.roomByName('Hostel Chat');
        expect(createdRoom, isNotNull);
        expect(createdRoom!.isPublic, isFalse);
        expect(createdRoom.isLocked, isFalse);
        expect(createdRoom.password, isNull);

        final duplicateCaseInsensitive = await provider.createRoom(
          name: 'hostel chat',
          createdById: 'user-2',
          createdByName: 'Beta',
          lockRoom: false,
        );
        expect(
          duplicateCaseInsensitive,
          equals('A room with this name already exists.'),
        );
      },
    );

    test('locked room validates password correctly', () async {
      final provider = CommunityChatProvider();
      await provider.ensureInitialized();

      final badPasswordResult = await provider.createRoom(
        name: 'Locked Room',
        createdById: 'user-1',
        createdByName: 'Alpha',
        lockRoom: true,
        password: '123',
      );
      expect(
        badPasswordResult,
        equals('Password must be at least 4 characters.'),
      );

      final createLocked = await provider.createRoom(
        name: 'Locked Room',
        createdById: 'user-1',
        createdByName: 'Alpha',
        lockRoom: true,
        password: 'pass1234',
      );
      expect(createLocked, isNull);

      expect(
        provider.verifyRoomPassword(
          roomName: 'Locked Room',
          password: 'pass1234',
        ),
        isTrue,
      );
      expect(
        provider.verifyRoomPassword(roomName: 'Locked Room', password: 'wrong'),
        isFalse,
      );

      expect(
        provider.verifyRoomPassword(
          roomName: CommunityChatProvider.publicRoomName,
          password: 'anything',
        ),
        isTrue,
      );
    });

    test('updateRoomLock enforces ownership and room type rules', () async {
      final provider = CommunityChatProvider();
      await provider.ensureInitialized();

      final createResult = await provider.createRoom(
        name: 'Owners Only',
        createdById: 'owner-id',
        createdByName: 'Owner',
        lockRoom: false,
      );
      expect(createResult, isNull);

      final nonOwnerAttempt = await provider.updateRoomLock(
        roomName: 'Owners Only',
        requesterUserId: 'other-id',
        shouldLock: true,
        password: 'abcd',
      );
      expect(
        nonOwnerAttempt,
        equals('Only the room creator can change room lock settings.'),
      );

      final publicRoomAttempt = await provider.updateRoomLock(
        roomName: CommunityChatProvider.publicRoomName,
        requesterUserId: 'system',
        shouldLock: true,
        password: 'abcd',
      );
      expect(publicRoomAttempt, equals('Public room cannot be locked.'));

      final ownerLock = await provider.updateRoomLock(
        roomName: 'Owners Only',
        requesterUserId: 'owner-id',
        shouldLock: true,
        password: 'abcd',
      );
      expect(ownerLock, isNull);
      expect(provider.roomByName('Owners Only')!.isLocked, isTrue);
      expect(provider.roomByName('Owners Only')!.password, equals('abcd'));

      final ownerUnlock = await provider.updateRoomLock(
        roomName: 'Owners Only',
        requesterUserId: 'owner-id',
        shouldLock: false,
      );
      expect(ownerUnlock, isNull);
      expect(provider.roomByName('Owners Only')!.isLocked, isFalse);
      expect(provider.roomByName('Owners Only')!.password, isNull);
    });

    test('sendMessage validates inputs and appends chat messages', () async {
      final provider = CommunityChatProvider();
      await provider.ensureInitialized();

      final createResult = await provider.createRoom(
        name: 'Messaging Room',
        createdById: 'owner-id',
        createdByName: 'Owner',
        lockRoom: false,
      );
      expect(createResult, isNull);

      final emptyMessageAttempt = await provider.sendMessage(
        roomName: 'Messaging Room',
        senderNickname: 'Nick',
        text: '   ',
      );
      expect(emptyMessageAttempt, equals('Message cannot be empty.'));

      final emptyNicknameAttempt = await provider.sendMessage(
        roomName: 'Messaging Room',
        senderNickname: '   ',
        text: 'Hello',
      );
      expect(emptyNicknameAttempt, equals('Nickname is required.'));

      final sendResult = await provider.sendMessage(
        roomName: 'Messaging Room',
        senderNickname: 'Nick',
        text: 'Hello world',
      );
      expect(sendResult, isNull);

      final room = provider.roomByName('Messaging Room')!;
      final lastMessage = room.messages.last;
      expect(lastMessage.senderNickname, equals('Nick'));
      expect(lastMessage.text, equals('Hello world'));
      expect(lastMessage.isSystem, isFalse);
    });

    test(
      'state persists via SharedPreferences and reloads into new provider',
      () async {
        final providerA = CommunityChatProvider();
        await providerA.ensureInitialized();

        await providerA.createRoom(
          name: 'Persist Room',
          createdById: 'owner-id',
          createdByName: 'Owner',
          lockRoom: true,
          password: 'persist123',
        );
        await providerA.sendMessage(
          roomName: 'Persist Room',
          senderNickname: 'OwnerNick',
          text: 'Persistent message',
        );

        final providerB = CommunityChatProvider();
        await providerB.ensureInitialized();

        final restored = providerB.roomByName('Persist Room');
        expect(restored, isNotNull);
        expect(restored!.isLocked, isTrue);
        expect(restored.password, equals('persist123'));
        expect(
          restored.messages.any((m) => m.text == 'Persistent message'),
          isTrue,
        );
        expect(
          providerB.roomByName(CommunityChatProvider.publicRoomName),
          isNotNull,
        );
      },
    );
  });
}
