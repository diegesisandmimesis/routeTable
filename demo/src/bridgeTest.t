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

class FooRoom: Room routeTableZone = 'foo';
class BarRoom: Room routeTableZone = 'bar';

foo1: FooRoom 'Foo Room 1' south = foo2 east = bar1;
foo2: FooRoom 'Foo Room 2' north = foo1 south = foo3;
foo3: FooRoom 'Foo Room 3' north = foo2 south = foo4;
foo4: FooRoom 'Foo Room 4' north = foo3 east = bar4;

bar1: BarRoom 'Bar Room 1' south = bar2 east = bar5 west = foo1;
bar2: BarRoom 'Bar Room 2' north = bar1 south = bar3;
bar3: BarRoom 'Bar Room 3' north = bar2 south = bar4;
bar4: BarRoom 'Bar Room 4' north = bar3 east = bar6 west = foo4;
bar5: BarRoom 'Bar Room 5' west = bar1;
bar6: BarRoom 'Bar Room 6' west = bar4;

me: Person;

gameMain: GameMainDef
	initialPlayerChar = me

	newGame() {
		_logPath(foo1, bar5);
		_logPath(bar5, foo1);
		_logPath(foo1, bar6);
		_logPath(bar6, foo1);
		_logPath(foo4, bar5);
		_logPath(bar5, foo4);
		_logPath(foo4, bar6);
		_logPath(bar6, foo4);
	}

	_logPath(rm0, rm1) {
		"Path from <q><<rm0.name>></q> to <q><<rm1.name>></q>\n ";
		roomRouter.findPath(rm0, rm1).forEach(function(o) {
			"\t<<o.routeTableID>>:  <<o.name>>\n ";
		});
	}
;
