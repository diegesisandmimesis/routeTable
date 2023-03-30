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
class BazRoom: Room desc = "This is a baz room. " routeTableZone = 'baz';
class QuuxRoom: Room desc = "This is a quux room. " routeTableZone = 'quux';
class ConnRoom: Room desc = "This is a conn room. " routeTableZone = 'conn';

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

// Another clique of connected rooms.
bar1: BarRoom 'Bar 1' north = bar2 south = foo3;
bar2: BarRoom 'Bar 2' north = bar3 south = bar1;
bar3: BarRoom 'Bar 3' south = bar2;

// This is a busted zone:  quux contains two disconnected subgroups,
// bisected by the conn zone.
quux1: QuuxRoom 'Quux 1' north = quux2 south = bar3;
quux2: QuuxRoom 'Quux 2' north = quux3 south = quux1 east = conn2;
quux3: QuuxRoom 'Quux 3' south = quux2;

quux4: QuuxRoom 'Quux 4' north = quux5;
quux5: QuuxRoom 'Quux 5' north = quux6 south = quux4 west = conn2;
quux6: QuuxRoom 'Quux 6' south = quux5;

conn1: ConnRoom 'Conn 1' north = conn2;
conn2: ConnRoom 'Conn 2' north = conn3 south = conn1
	east = quux5 west = quux2;
conn3: ConnRoom 'Conn 3' south = conn2;
	
gameMain: GameMainDef
	initialPlayerChar = me

	newGame() {
		routeTableLint.setIgnoreList([ ignoredRoom ]);
		routeTableLint.runTests();
		//runGame(true);
	}
;
