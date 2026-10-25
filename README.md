# Seat Lock Demo — Movie Ticket Booking

A Flutter demo app built from the @ashmit.codes system-design reel
about race conditions in movie-ticket seat booking (framed around
the film Ramayana).

## The idea (from the reel)

Two users click the same seat in the same second. The naive flow —
check if the seat is free, then book it — breaks at scale: both
requests check at the same time, both see "free", both book.
One seat, two tickets, both users charged. That is a race condition.

The fix: a Redis seat lock, e.g. `SET seat:H12 userA NX EX 600`.

- NX: lock only if no lock already exists. Whoever arrives first
  gets the seat.
- EX 600: the lock lives 600 seconds (10 minutes). No payment in
  that time, and the lock auto-releases. Payment completed, and
  only then is the final booking written to the database.

The reel's teaser: payment at 9:59, lock expires before
confirmation — what happens to the seat? In this demo, the
payment is refused and the seat goes free again, because a
booking is only final while the lock is still held.

## Features

- Seat map for Ramayana advance booking (rows A-H, seats 1-12,
  including H12 from the reel)
- Lock a seat for 10 minutes, with a live countdown
- Pay & Book: only works while your lock is still live
- Simulate 10 minutes passing: the lock expires, seat frees up
- Race Demo: run User A vs User B on H12 in naive mode (bug:
  double booking) and in lock mode (fix: first arrival wins)
- Learn tab: the race condition, NX/EX explained, and the
  teaser question answered

Demo note: the lock is simulated in memory in this app. It is
not a real booking system, does not use a real Redis server,
and does not take real payments.

## Architecture

```
lib/
  main.dart                       Thin entry point
  models/seat_lock.dart           Lock store (Redis NX/EX semantics)
  controllers/booking_controller.dart  All business logic
  screens/home_screen.dart        UI only: Seat Map, Race, Learn
test/
  seat_lock_test.dart             Unit tests for lock logic
```

## How to run it

1. Install the Flutter SDK, then check it with `flutter doctor`
2. Open this folder in VS Code (or a terminal inside it)
3. `flutter pub get`
4. `flutter run`

## How to check quality

```
flutter analyze
flutter test
```
