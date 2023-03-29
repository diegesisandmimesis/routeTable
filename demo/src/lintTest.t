#charset "us-ascii"
//
// rebuildTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// Non-interactive test of zone rebuilding.
//
// It can be compiled via the included makefile with
//
//	# t3make -f rebuildTest.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

// No version info; we're never interactive.
versionInfo: GameID;

class FooRoom: Room desc = "This is a foo room. " routeTableZone = 'foo';
class BarRoom: Room desc = "This is a bar room. " routeTableZone = 'bar';
class BazRoom: Room desc = "This is a baz room. " routeTableZOne = 'baz';

startRoom: Room 'Start Room'
	"This is the starting room. "
	routeTableZone = 'start'
	north = foo1
;
+me: Actor;

// This room should be called out in the report as being orphaned.  This
// is the linter noticing that it's not connected to anything.
orphanedRoom: Room 'Orphaned Room'
	"This room isn't connected to any other rooms. "
;

// This room is also not connected to anything, but it's added to the
// ignore list, so the linter shouldn't complain about it.
ignoredRoom: Room 'Ignored Room'
	"This room is orphaned, but shouldn't show up in reports. "
;

// This is a clique of connected rooms.
foo1: FooRoom 'Foo 1' north = foo2 south = startRoom;
foo2: FooRoom 'Foo 2' north = foo3 south = foo1;
foo3: FooRoom 'Foo 3' north = bar1 south = foo2;

bar1: BarRoom 'Bar 1' north = bar2 south = foo3;
bar2: BarRoom 'Bar 2' north = bar3 south = bar1;
bar3: BarRoom 'Bar 3' south = bar2;
	
gameMain: GameMainDef
	initialPlayerChar = me

	newGame() {
		routeTableLint.setIgnoreList([ ignoredRoom ]);
		routeTableLint.runTests();
		//runGame(true);
	}
;
