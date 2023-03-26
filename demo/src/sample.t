#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// Simple non-interactive pathfinding demonstration.  Designed to test
// a couple special cases.
//
// It can be compiled via the included makefile with
//
//	# t3make -f makefile.t3m
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

// ROOM CLASS DEFINITIONS
//
// For convenience we create classes for our different zones.  We don't
// have to; we can just declare routeTableZone = 'whatever' on individual
// rooms, but this is a little cleaner.
// We also declare a "generic" zone and then a separate class for indoor
// and outdoor rooms, but that has nothing to do with the pathfinding logic.
class HouseZone: Room
	routeTableZone = 'house'
;
class HouseRoom: HouseZone;
class HouseOutdoor: HouseZone, OutdoorRoom;
//
// All the "town" locations are outdoor, so we only define one class.
class TownZone: OutdoorRoom
	routeTableZone = 'town'
;
//
// The "carnival" rooms are a mix of indoor and outdoor locations, so we
// have multiple classes again.  And once again they all share a single zone.
// That's because they're all in a big blob.  In a real game, the ticket booth
// might be a chokepoint--maybe you need a ticket to get in.  So it makes
// sense to put all the rooms behind the chokepoint into a single zone (because
// pathing to all those locations would change whenever the state of the
// ticket booth changes).  You could also have more granularity--the hall of
// mirrors might be its own zone if the map layout of the interior changes, for
// example.
class CarnivalZone: Room
	routeTableZone = 'carnival'
;
class CarnivalRoom: CarnivalZone;
class CarnivalOutdoor: CarnivalZone, OutdoorRoom;

// ROOM DEFINITIONS
//
// HOUSE ROOMS
//
bedroom: HouseRoom 'Your Bedroom'
        "This is your minimally-implemented bedroom.  The hallway lies to the
		west. "
	west = hallway
;
+me: Person;

hallway: HouseRoom 'The Hallway'
	"This is the featureless hallway of your house.  Your bedroom is to
		the east and the kitchen lies to the west.  The back yard
		is south from here, and you can leave your house by going
		north. "
	north = frontYard
	south = backYard
	east = bedroom
	west = kitchen
;

kitchen: HouseRoom 'The Kitchen'
	"This is theoretically a kitchen. "
	east = hallway
;

backYard: HouseOutdoor 'Your Back Yard'
	"This is the back yard.  The only interesting thing about it is
		that you can leave it by going north. "
	north = hallway
;

frontYard: HouseOutdoor 'Your Front Yard'
	"This is the generic front yard of your generic house.  The rest of
		the generic town is to the north of here.  You can enter
		your house to the south. "
	north = downtownWest
	south = hallway
;

//
// TOWN ROOMS
//
downtownWest: TownZone 'Downtown West'
	"This is the west end of downtown, which much resembles the east
		end of downtown.  Your house is conveniently exactly one
		step due south of here. "
	south = frontYard
	east = downtownEast
;

downtownEast: TownZone 'Downtown East'
	"This is the east end of downtown, which much resembles the west
		end of downtown.  The outskirts of town are north of here. "
	north = outskirts
	west = downtownWest
;

outskirts: TownZone 'The Outskirts of Town'
	"This is the outskirts of town, where sparsely implemented meets
		completely unimplemented.  The town itself lies to the south.
		A placeholder carnival is apparently in town;  you can enter
		it to the east. "
	east = ticketBooth
	south = downtownEast
;

//
// CARNIVAL ROOMS
//
ticketBooth: CarnivalOutdoor 'The Carnival Ticket Booth'
	"This is what we'll call the ticket booth to what we'll call the
		carnival.  There is no booth and there are no tickets.  But
		you can enter the rest of the <q>carnival</q> to the east. 
		Or head back toward the featureless town to the west. "
	east = midway
	west = outskirts
;

midway: CarnivalOutdoor 'The Carnival Midway'
	"This is the carnival midway, which as far as you know is bright,
		colorful, and full of sounds and activities it is not
		currently convenient to describe.  The hall of mirrors is
		just east of here and the ticket booth is to the west. "
	east = hallOfMirrors
	west = ticketBooth
;

hallOfMirrors: CarnivalRoom 'The Hall of Mirrors'
	"This is the hall of mirrors.  Srorrim fo llah eht si siht.
		<.p>
		The inappropriately-named secret room is just north of here.
		You can leave the hall of mirrors by going west. "
	north = secretRoom
	west = midway
;

secretRoom: CarnivalRoom 'The Secret Room'
	"This is the secret room in the hall of mirrors, for whatever
		that's worth. "
	south = hallOfMirrors
;

gameMain: GameMainDef
	// We're not interactive but we still define a player character
	// because pathfinding uses gameMain.initialPlayerChar to test
	// travel connectors and their destinations.
	initialPlayerChar = me

	newGame() {
		// Path from one end of the map to another, crossing multiple
		// zones.
		_logPath(bedroom, secretRoom);

		// Same path in reverse.
		_logPath(secretRoom, bedroom);

		// Path entirely inside one zone, single step.
		_logPath(bedroom, hallway);

		// Path from edge of one zone to edge of the adjacent zone.
		_logPath(frontYard, downtownWest);
	}

	// Utility method to compute/look up a path and output it.
	_logPath(rm0, rm1) {
		local l;

		"Path from <q><<rm0.name>></q> to
			<q><<rm1.name>></q>\n ";
		l = routeTableRoomRouter.findPath(rm0, rm1);
		l.forEach(function(o) {
			"\t<<o.routeTableID>>:  <<o.name>>\n ";
		});
		"<.p> ";
	}
;
