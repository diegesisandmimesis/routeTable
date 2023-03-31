#charset "us-ascii"
//
// lintTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// Test of the basic functionality of the route table linter.  It just
// goes through the route tables and tries to identify errors (like zones
// containing disconnected subgraphs), possible problems (rooms that aren't
// connected to anything else), and so on.
//
// It can be compiled via the included makefile with
//
//	# t3make -f lintTest.t3m
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

// A bunch of Room subclasses.  We just do this so we don't have to
// define all the properties on the individual instances, we're not
// doing anything relevant to the linter here.
class FooRoom: Room desc = "This is a foo room. " routeTableZone = 'foo';
class BarRoom: Room desc = "This is a bar room. " routeTableZone = 'bar';
class BazRoom: Room desc = "This is a baz room. " routeTableZone = 'baz';
class QuuxRoom: Room desc = "This is a quux room. " routeTableZone = 'quux';
class ConnRoom: Room desc = "This is a conn room. " routeTableZone = 'conn';
class DisjRoom: Room desc = "This is a disjoint room. " routeTableZone = 'disj';

// A starting room, in its own zone.  Note that we declare the zone on the
// room instance instead of in a class definition.
// We put the actor here, and so this is the location that will be used
// to determine reachability across the game map.
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
// ignore list (some ways below), so the linter shouldn't complain about it.
ignoredRoom: Room 'Ignored Room'
	"This room is orphaned, but shouldn't show up in reports. "
;

// This is a clique of connected rooms.  They're in a contiguous zone and
// they're connected to the start room, so there should be no complaints here.
foo1: FooRoom 'Foo 1' north = foo2 south = startRoom;
foo2: FooRoom 'Foo 2' north = foo3 south = foo1;
foo3: FooRoom 'Foo 3' north = bar1 south = foo2;

// Another clique of connected rooms.  Like the above, the linter shouldn't
// care about any of these rooms.
bar1: BarRoom 'Bar 1' north = bar2 south = foo3;
bar2: BarRoom 'Bar 2' north = bar3 south = bar1;
bar3: BarRoom 'Bar 3' south = bar2;

// This is a busted zone:  quux contains two disconnected subgroups,
// bisected by the conn zone.  If the rooms in the conn zone were instead
// in the quux zone then it would be fine, because then the rooms in
// quux would all be contiguous.  As it is, it should generate an error.
quux1: QuuxRoom 'Quux 1' north = quux2 south = bar3;
quux2: QuuxRoom 'Quux 2' north = quux3 south = quux1 east = conn2;
quux3: QuuxRoom 'Quux 3' south = quux2;

// More of the same zone, not contiguous with the quux rooms above.
quux4: QuuxRoom 'Quux 4' north = quux5;
quux5: QuuxRoom 'Quux 5' north = quux6 south = quux4 west = conn2;
quux6: QuuxRoom 'Quux 6' south = quux5;

// The conn zone.  The map is traversable because quux1 to 3 are connected
// to quux4 to 6 via conn2, but the next hop logic requires all vertices in
// a zone to be contiguous, so this would be valid if quux1 to 3 and
// quux 4 to 6 were two different zones, but it'll cause problems as it is.
conn1: ConnRoom 'Conn 1' north = conn2;
conn2: ConnRoom 'Conn 2' north = conn3 south = conn1
	east = quux5 west = quux2;
conn3: ConnRoom 'Conn 3' south = conn2;

// A disjoint blob of rooms.  They're valid as a zone in and of themselves,
// but they're not connected to anything else.
disj1: DisjRoom 'DisJ 1' north = disj2;
disj2: DisjRoom 'DisJ 2' north = disj3 south = disj2;
disj3: DisjRoom 'DisJ 3' south = disj2;

	
gameMain: GameMainDef
	initialPlayerChar = me

	newGame() {
		"<.p>
		This is a non-interactive test of the route table linter.
		It should output a BUNCH of stuff below.
		<.p>
		In no particular order, it should complain about:<.p>
		\n\tthe zone <q>disj</q> not being connected to anything
		\n\tthe zone <q>quux</q> containing disconnected subgraphs
		\n\tone or more rooms being orphaned
		<.p>
		Report begins below:
		<.p> ";
		routeTableLint.setIgnoreList([ ignoredRoom ]);
		routeTableLint.runTests();
		//runGame(true);
	}
;
