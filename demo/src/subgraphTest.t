#charset "us-ascii"
//
// subgraphTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// Test handling of disconnected subgraphs in the default zone.
//
// It can be compiled via the included makefile with
//
//	# t3make -f subgraphTest.t3m
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

// We define three classes for our rooms, entirely for convenience.
// FooRoom is for rooms in the "foo" zone.  The rooms in XRoom and YRoom
// will all end up in the default zone because they have no explicit
// zone declaration.
class FooRoom: Room routeTableZone = 'foo';
class XRoom: Room 'Room' "This is a generic room with no declared zone." ;
class YRoom: Room 'Room' "This is a generic room with no declared zone.";

// The XRoom rooms are all in a contiguous block:  they're connected to
// each other.
default1: XRoom 'Generic Room 1' north = default2;
default2: XRoom 'Generic Room 2' north = default3 south = default2 east = foo2;
default3: XRoom 'Generic Room 3' south = default2;

// The YRoom rooms are also in a contiguous block.
default4: YRoom 'Generic Room 4' north = default5;
default5: YRoom 'Generic Room 5' north = default6 south = default4 west = foo2;
default6: YRoom 'Generic Room 6' south = default5;

// And finally the FooRoom rooms are in a contiguous block as well.
foo1: FooRoom 'Foo Room 1' north = foo2;
foo2: FooRoom 'Foo Room 2' north = foo3 south = foo1
	east = default5 west = default2;
foo3: FooRoom 'Foo Room 3' south = foo2;
+me: Actor;

// So we have three contiguous blocks of rooms.  If each of the blocks
// was declared as its own zone it would be perfect.  But because
// XRoom and YRoom don't have zone declarations they'll all end up in
// the default zone.  But since they're not connected to each other,
// there will be pathing problems, even though the entire map is
// traversable (because XRoom and YRoom are connected through FooRoom).

gameMain: GameMainDef
	initialPlayerChar = me

	newGame() {
		_logPath(default1, default6);
	}

	_logPath(rm0, rm1) {
		"Path from <q><<rm0.name>></q> to <q><<rm1.name>></q>\n ";
		roomRouter.findPath(rm0, rm1).forEach(function(o) {
			"\t<<o.routeTableID>>:  <<o.name>>\n ";
		});
	}
;
