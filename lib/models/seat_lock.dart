// Seat-lock logic, modelled on the reel's Redis solution.
// Pure Dart, no Flutter dependency, so it is easy to unit test.
//
// The reel's idea, in plain words:
// - Naive booking: check if a seat is free, then book it.
//   When two users check at the same instant, both see "free"
//   and both book. One seat, two tickets, both charged.
//   That bug is called a race condition.
// - Seat lock: before booking, try to lock the seat, and only
//   lock it if no lock already exists (Redis NX). Whoever
//   arrives first gets the seat; the second one is refused.
// - The lock has a timer (Redis EX 600 = 10 minutes). If
//   payment is not completed in time, the lock auto-releases
//   and the seat becomes free again. Only a completed payment
//   writes the final booking.

enum SeatState { free, locked, booked }

class SeatLock {
  SeatLock({required this.seatId, required this.user, required this.expiresAt});

  final String seatId;
  final String user;
  final DateTime expiresAt;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);
}

// A tiny in-memory stand-in for Redis, with the same semantics
// the reel teaches: SET key user NX EX seconds.
class SeatLockStore {
  final Map<String, SeatLock> _locks = {};
  final Map<String, String> _bookings = {};

  SeatState stateOf(String seatId, DateTime now) {
    if (_bookings.containsKey(seatId)) return SeatState.booked;
    final lock = _locks[seatId];
    if (lock == null || lock.isExpiredAt(now)) return SeatState.free;
    return SeatState.locked;
  }

  String? lockedBy(String seatId, DateTime now) {
    final lock = _locks[seatId];
    if (lock == null || lock.isExpiredAt(now)) return null;
    return lock.user;
  }

  // NX: only lock if no live lock and no booking exists.
  bool tryLock(String seatId, String user, Duration ttl, DateTime now) {
    if (stateOf(seatId, now) != SeatState.free) return false;
    _locks[seatId] = SeatLock(
      seatId: seatId,
      user: user,
      expiresAt: now.add(ttl),
    );
    return true;
  }

  // Remove locks whose timer has run out.
  void releaseExpired(DateTime now) {
    _locks.removeWhere((_, lock) => lock.isExpiredAt(now));
  }

  DateTime? lockExpiresAt(String seatId, DateTime now) {
    final lock = _locks[seatId];
    if (lock == null || lock.isExpiredAt(now)) return null;
    return lock.expiresAt;
  }

  void removeLock(String seatId) {
    _locks.remove(seatId);
  }

  int get lockCount => _locks.length;

  // Payment completed: only works if this user still holds
  // a live lock. This is the reel's teaser question: if the
  // lock expired before payment confirmation, the seat is
  // no longer yours and the booking must NOT go through.
  bool confirmBooking(String seatId, String user, DateTime now) {
    if (lockedBy(seatId, now) != user) return false;
    _locks.remove(seatId);
    _bookings[seatId] = user;
    return true;
  }

  String? bookedBy(String seatId) => _bookings[seatId];

  // Deliberately naive, for the race demo only: check, then
  // book, with no lock. If two callers both checked "free"
  // first, both bookings land - the bug the reel warns about.
  void naiveBookUnchecked(String seatId, String user) {
    _bookings[seatId] = user;
  }

  void reset() {
    _locks.clear();
    _bookings.clear();
  }
}
