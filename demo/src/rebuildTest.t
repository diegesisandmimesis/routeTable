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

modify routeTableRoomRouter;

// Same configuration as sample.t
class HouseRoom: Room routeTableZone = 'house';
class HouseIndoor: HouseRoom;
class HouseOutdoor: HouseRoom, OutdoorRoom;
class TownRoom: OutdoorRoom routeTableZone = 'town';
class CarnivalRoom: Room routeTableZone = 'carnival';
class CarnivalIndoor: CarnivalRoom;
class CarnivalOutdoor: CarnivalRoom, OutdoorRoom;

bedroom: HouseIndoor 'Your Bedroom'
        "This is your minimally-implemented bedroom.  The hallway lies to the
		west. "
	west = hallway
;
+me: Person;

hallway: HouseIndoor 'The Hallway'
	"This is the featureless hallway of your house.  Your bedroom is to
		the east and the kitchen lies to the west.  The back yard
		is south from here, and you can leave your house by going
		north. "
	north = frontDoorHouse
	south = backYard
	east = bedroom
	west = kitchen
;
+frontDoorHouse: ThroughPassage '(front) door' 'front door'
	destination() { return(stuck ? nil : frontYard); }
	stuck = nil

	canTravellerPass(a) { return(!stuck); }
	explainTravelBarrier(a) { "The front door is currently stuck. "; }
	noteTraversal(a) { "{You/he} head{s} through the front door. "; }
;

kitchen: HouseIndoor 'The Kitchen'
	"This is theoretically a kitchen. "
	east = hallway
;

backYard: HouseOutdoor 'Your Back Yard'
	"This is the back yard.  The only interesting thing about it is
		that you can leave it by going north. "
	north = hallway
;

frontYard: TownRoom 'Your Front Yard'
	"This is the generic front yard of your generic house.  The rest of
		the generic town is to the north of here.  You can enter
		your house to the south. "
	north = downtownWest
	south = hallway
;
+frontDoorYard: Door '(front) door' 'front door'
	masterObject = frontDoorHouse
	noteTraversal(a) { "{You/he} head{s} through the front door. "; }
;

downtownWest: TownRoom 'Downtown West'
	"This is the west end of downtown, which much resembles the east
		end of downtown.  Your house is conveniently exactly one
		step due south of here. "
	south = frontYard
	east = downtownEast
;

downtownEast: TownRoom 'Downtown East'
	"This is the east end of downtown, which much resembles the west
		end of downtown.  The outskirts of town are north of here. "
	north = outskirts
	west = downtownWest
;

outskirts: TownRoom 'The Outskirts of Town'
	"This is the outskirts of town, where sparsely implemented meets
		completely unimplemented.  The town itself lies to the south.
		A placeholder carnival is apparently in town;  you can enter
		it to the east. "
	east = ticketBooth
	south = downtownEast
;

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

hallOfMirrors: CarnivalIndoor 'The Hall of Mirrors'
	"This is the hall of mirrors.  Srorrim fo llah eht si siht.
		<.p>
		The inappropriately-named secret room is just north of here.
		You can leave the hall of mirrors by going west. "
	north = secretRoom
	west = midway
;

secretRoom: CarnivalIndoor 'The Secret Room'
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

		frontDoorHouse.stuck = true;
		routeTableRoomRouter.rebuildZone('house');

		_logPath(bedroom, secretRoom);
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
