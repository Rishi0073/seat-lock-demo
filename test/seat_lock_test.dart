import 'package:flutter_test/flutter_test.dart';
import 'package:seat_lock_demo/models/seat_lock.dart';

void main() {
  final now = DateTime(2026, 10, 24, 22, 0);

  test('NX lock: first arrival wins, second is refused', () {
    final store = SeatLockStore();
    expect(store.tryLock('H12', 'User A', const Duration(minutes: 10), now),
        isTrue);
    expect(store.tryLock('H12', 'User B', const Duration(minutes: 10), now),
        isFalse);
    expect(store.lockedBy('H12', now), 'User A');
  });

  test('Lock expires after 10 minutes and the seat frees up', () {
    final store = SeatLockStore();
    store.tryLock('H12', 'User A', const Duration(minutes: 10), now);
    final later = now.add(const Duration(minutes: 10, seconds: 1));
    expect(store.stateOf('H12', later), SeatState.free);
    expect(store.tryLock('H12', 'User B', const Duration(minutes: 10), later),
        isTrue);
  });

  test('Payment only confirms while the lock is still held', () {
    final store = SeatLockStore();
    store.tryLock('H12', 'User A', const Duration(minutes: 10), now);
    expect(store.confirmBooking('H12', 'User A', now), isTrue);
    expect(store.bookedBy('H12'), 'User A');

    final store2 = SeatLockStore();
    store2.tryLock('H12', 'User A', const Duration(minutes: 10), now);
    final afterExpiry = now.add(const Duration(minutes: 11));
    expect(store2.confirmBooking('H12', 'User A', afterExpiry), isFalse);
    expect(store2.bookedBy('H12'), isNull);
  });

  test('Naive check-then-book double-books the same seat', () {
    final store = SeatLockStore();
    // Both users checked "free" first, then both booked.
    store.naiveBookUnchecked('H12', 'User A');
    store.naiveBookUnchecked('H12', 'User B');
    expect(store.bookedBy('H12'), 'User B');
  });
}
