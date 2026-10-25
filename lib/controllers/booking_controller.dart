import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/seat_lock.dart';

// All business logic lives here, not in the widgets.
class BookingController extends ChangeNotifier {
  BookingController({SeatLockStore? store})
      : _store = store ?? SeatLockStore() {
    // Every second, drop expired locks and refresh the countdown
    // display so the seat map stays live.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _store.releaseExpired(DateTime.now());
      notifyListeners();
    });
  }

  final SeatLockStore _store;
  Timer? _timer;

  // Demo cinema: rows A-H, seats 1-12, including H12 from the reel.
  static const List<String> rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
  static const int seatsPerRow = 12;

  static List<String> get allSeats {
    final seats = <String>[];
    for (final row in rows) {
      for (var number = 1; number <= seatsPerRow; number++) {
        seats.add('$row$number');
      }
    }
    return seats;
  }

  static const Duration lockDuration = Duration(minutes: 10);

  String? selectedSeat;
  String currentUser = 'You';
  String? message;
  bool raceNaiveMode = false;
  List<String> raceLog = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  SeatState stateOf(String seatId) => _store.stateOf(seatId, DateTime.now());
  String? lockedBy(String seatId) => _store.lockedBy(seatId, DateTime.now());
  String? bookedBy(String seatId) => _store.bookedBy(seatId);

  DateTime? lockExpiresAt(String seatId) {
    return _store.lockExpiresAt(seatId, DateTime.now());
  }

  void selectSeat(String seatId) {
    selectedSeat = seatId;
    message = null;
    notifyListeners();
  }

  // Lock the selected seat for the current user (NX semantics).
  void lockSelectedSeat() {
    final seatId = selectedSeat;
    if (seatId == null) return;
    final ok = _store.tryLock(seatId, currentUser, lockDuration, DateTime.now());
    message = ok
        ? '$seatId locked for you for 10 minutes. Pay before the timer ends!'
        : '$seatId is already locked or booked. Try another seat.';
    notifyListeners();
  }

  // Pay for the selected seat: only works with a live lock.
  void payForSelectedSeat() {
    final seatId = selectedSeat;
    if (seatId == null) return;
    final ok = _store.confirmBooking(seatId, currentUser, DateTime.now());
    message = ok
        ? 'Payment done! $seatId is booked for you.'
        : 'Payment failed: your lock expired before confirmation. '
            'The seat is free again - this is the reel\'s teaser question.';
    notifyListeners();
  }

  // Demo only: expire the selected seat's lock right now, as if
  // 10 minutes passed without payment.
  void expireSelectedLockNow() {
    final seatId = selectedSeat;
    if (seatId == null) return;
    _store.removeLock(seatId);
    message = '$seatId lock expired. The seat is free again.';
    notifyListeners();
  }

  // Race demo: User A and User B both try for H12 at once.
  // Naive mode: both checked "free" first, so both book (the bug).
  // Lock mode: only the first tryLock wins (the fix).
  void runRaceDemo() {
    const seatId = 'H12';
    raceLog = [];
    _store.reset();
    if (raceNaiveMode) {
      raceLog.add('User A checks H12: free.');
      raceLog.add('User B checks H12: free (same instant).');
      _store.naiveBookUnchecked(seatId, 'User A');
      _store.naiveBookUnchecked(seatId, 'User B');
      raceLog.add('Both book H12. One seat, two tickets, both charged. BUG!');
      raceLog.add('Final booking holder: ${_store.bookedBy(seatId)} '
          '(User A\'s booking was silently overwritten).');
    } else {
      final aWins = _store.tryLock(seatId, 'User A', lockDuration, DateTime.now());
      final bWins = _store.tryLock(seatId, 'User B', lockDuration, DateTime.now());
      raceLog.add('User A tries lock H12: ${aWins ? 'locked' : 'refused'}.');
      raceLog.add('User B tries lock H12: ${bWins ? 'locked' : 'refused'}.');
      raceLog.add('Only User A holds the seat. User B must pick another seat.');
    }
    selectedSeat = seatId;
    notifyListeners();
  }

  void setRaceMode(bool naive) {
    raceNaiveMode = naive;
    notifyListeners();
  }

  void resetAll() {
    _store.reset();
    selectedSeat = null;
    message = null;
    raceLog = [];
    notifyListeners();
  }
}
