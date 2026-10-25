import 'package:flutter/material.dart';

import '../controllers/booking_controller.dart';
import '../models/seat_lock.dart';

// The screen only renders state and forwards taps to the
// controller. No business logic lives here.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final BookingController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ramayana Seat Booking Demo'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset demo',
                onPressed: controller.resetAll,
              ),
            ],
          ),
          body: _tab == 0
              ? _seatMapTab(controller)
              : _tab == 1
                  ? _raceTab(controller)
                  : _learnTab(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _tab,
            onTap: (index) => setState(() => _tab = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.event_seat),
                label: 'Seat Map',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bolt),
                label: 'Race Demo',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school),
                label: 'Learn',
              ),
            ],
          ),
        );
      },
    );
  }

  Color _seatColor(SeatState state) {
    switch (state) {
      case SeatState.free:
        return Colors.green.shade100;
      case SeatState.locked:
        return Colors.orange.shade300;
      case SeatState.booked:
        return Colors.red.shade300;
    }
  }

  Widget _seatMapTab(BookingController controller) {
    final selected = controller.selectedSeat;
    final selectedState =
        selected == null ? null : controller.stateOf(selected);
    final expiresAt =
        selected == null ? null : controller.lockExpiresAt(selected);
    final remaining = expiresAt == null
        ? null
        : expiresAt.difference(DateTime.now());

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Ramayana — Advance Booking (Demo)\n'
            '1,12,968+ tickets sold before release',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('■ Free', style: TextStyle(color: Colors.green)),
              Text('■ Locked', style: TextStyle(color: Colors.orange)),
              Text('■ Booked', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('SCREEN', style: TextStyle(letterSpacing: 4)),
        const Divider(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 12,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: BookingController.allSeats.length,
            itemBuilder: (context, index) {
              final seatId = BookingController.allSeats[index];
              final state = controller.stateOf(seatId);
              final isSelected = seatId == selected;
              return GestureDetector(
                onTap: () => controller.selectSeat(seatId),
                child: Container(
                  decoration: BoxDecoration(
                    color: _seatColor(state),
                    border: isSelected
                        ? Border.all(color: Colors.black, width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    seatId,
                    style: const TextStyle(fontSize: 9),
                  ),
                ),
              );
            },
          ),
        ),
        if (selected != null) ...[
          Text(
            'Seat $selected: ${selectedState?.name ?? ''}'
            '${controller.lockedBy(selected) != null ? ' by ${controller.lockedBy(selected)}' : ''}'
            '${controller.bookedBy(selected) != null ? ' by ${controller.bookedBy(selected)}' : ''}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (remaining != null && remaining.inSeconds > 0)
            Text(
              'Lock expires in ${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: controller.lockSelectedSeat,
                child: const Text('Lock Seat (10 min)'),
              ),
              FilledButton(
                onPressed: controller.payForSelectedSeat,
                child: const Text('Pay & Book'),
              ),
              OutlinedButton(
                onPressed: controller.expireSelectedLockNow,
                child: const Text('Simulate 10 min passing'),
              ),
            ],
          ),
        ],
        if (controller.message != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              controller.message!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _raceTab(BookingController controller) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Two users, one seat, one second',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'User A and User B both click seat H12 at the same instant. '
          'Try it both ways and watch what happens.',
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Naive mode (check, then book)'),
          subtitle: const Text(
            'Off = seat lock (the fix). On = the buggy check-then-book flow.',
          ),
          value: controller.raceNaiveMode,
          onChanged: controller.setRaceMode,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: controller.runRaceDemo,
          icon: const Icon(Icons.bolt),
          label: const Text('Both click H12 at the same time'),
        ),
        const SizedBox(height: 16),
        ...controller.raceLog.map((line) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('• $line'),
          );
        }),
        if (controller.raceLog.isEmpty)
          const Text('No race run yet. Press the button above.'),
      ],
    );
  }

  Widget _learnTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'Why a seat lock?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Text(
          'The naive answer in an interview is: check if the seat '
          'is free, then book it. That logic is correct for one '
          'user, but breaks when 1 lakh users act at once.',
        ),
        SizedBox(height: 8),
        Text(
          'Race condition: two requests check at the same time, '
          'both see the seat as free, both book it. One seat, '
          'two tickets, both users charged.',
        ),
        SizedBox(height: 8),
        Text(
          'The fix, as in the reel: a Redis seat lock. '
          'SET seat:H12 userA NX EX 600',
        ),
        SizedBox(height: 8),
        Text(
          'NX means: lock only if no lock already exists. '
          'Whoever arrives first gets the seat.',
        ),
        SizedBox(height: 8),
        Text(
          'EX 600 means: the lock lives for 600 seconds (10 '
          'minutes). No payment in that time, and the lock '
          'auto-releases - the seat becomes free again. '
          'Payment completed, and only then is the final '
          'booking written to the database.',
        ),
        SizedBox(height: 16),
        Text(
          'The teaser question',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Payment happens at 9:59, but before confirmation the '
          'lock expires. What happens to the seat? In this demo, '
          'the payment is refused and the seat goes free again - '
          'because the booking is only final while the lock is '
          'still held. In real systems, this is why payments use '
          'idempotency keys and lock extensions, so a slow '
          'confirmation does not double-book or lose a seat.',
        ),
        SizedBox(height: 16),
        Text(
          'Demo note: this app simulates the lock in memory. '
          'It is not a real booking system and does not use a '
          'real Redis server or take real payments.',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
