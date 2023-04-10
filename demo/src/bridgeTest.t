#charset "us-ascii"
//
// bridgeTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// Test handling of bridge selection.
//
// It can be compiled via the included makefile with
//
//	# t3make -f bridgeTest.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

// No version info; we're never interactive.
versionInfo: GameID;

// Define two zones for all our rooms.
class FooRoom: Room routeTableZone = 'foo';
class BarRoom: Room routeTableZone = 'bar';

// Layout of our test map
//
//      foo1 -- bar1 -- bar5
//        |       |
//      foo2    bar2
//        |       |
//      foo3    bar3
//        |       |
//      foo4 -- bar4 -- bar6
//
// A north-south line of four rooms, connected to the "bar" zone at the
// top and bottom.
foo1: FooRoom 'Room Foo1' south = foo2 east = bar1;
foo2: FooRoom 'Room Foo2' north = foo1 south = foo3;
foo3: FooRoom 'Room Foo3' north = foo2 south = foo4;
foo4: FooRoom 'Room Foo4' north = foo3 east = bar4;

// A north-south line of four rooms, connected to the "foo" zone at the
// top and bottom.
bar1: BarRoom 'Room Bar1' south = bar2 east = bar5 west = foo1;
bar2: BarRoom 'Room Bar2' north = bar1 south = bar3;
bar3: BarRoom 'Room Bar3' north = bar2 south = bar4;
bar4: BarRoom 'Room Bar4' north = bar3 east = bar6 west = foo4;

// Two additional rooms in the "bar" zone, in the northeast and southeast
// corners.
bar5: BarRoom 'Room Bar5' west = bar1;
bar6: BarRoom 'Room Bar6' west = bar4;

me: Person;

gameMain: GameMainDef
	initialPlayerChar = me

	// A list of test routes to compute.
	// First arg is the source room, second the destination room, third the
	// expected path.
	_tests = static [
		[ foo1, bar5, [ foo1, bar1, bar5 ] ],
		[ bar5, foo1, [ bar5, bar1, foo1 ] ],

		[ foo4, bar2, [ foo4, bar4, bar3, bar2 ] ],
		[ bar2, foo4, [ bar2, bar3, bar4, foo4 ] ],

		[ foo2, bar6, [ foo2, foo3, foo4, bar4, bar6 ] ],
		[ bar6, foo2, [ bar6, bar4, foo4, foo3, foo2 ] ],

		[ foo4, bar6, [ foo4, bar4, bar6 ] ],
		[ bar6, foo4, [ bar6, bar4, foo4 ] ]
	]

	runTests() {
		local err, i;

		// Test counter.
		i = 0;

		// Error counter.
		err = 0;

		// Go through whatever tests we've defined.
		_tests.forEach(function(ar) {
			// Call the room router's debugging method, which will
			// compute the path between rooms given in the first
			// two arguments and then compare it to the third
			// argument.
			if(roomRouter.debugVerifyPath(ar[1], ar[2], ar[3])
				!= true) {
				"ERROR:  failed test <<toString(i)>>:
					<<ar[1].roomName>>
					to <<ar[2].roomName>>\n ";
				err += 1;
			}
			i += 1;
		});

		if(err != 0)
			"\nERROR:  failed <<toString(err)>> of <<toString(i)>>
				tests\n ";
		else
			"passed <<toString(i)>> of <<toString(i)>> tests\n ";
	}

	newGame() { runTests(); }
;
