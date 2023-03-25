#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the routeTable library.
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

versionInfo:    GameID
        name = 'routeTable Library Demo Game'
        byline = 'Diegesis & Mimesis'
        desc = 'Demo game for the routeTable library. '
        version = '1.0'
        IFID = '12345'
	showAbout() {
		"This is a simple test game that demonstrates the features
		of the routeTable library.
		<.p>
		Consult the README.txt document distributed with the library
		source for a quick summary of how to use the library in your
		own games.
		<.p>
		The library source is also extensively commented in a way
		intended to make it as readable as possible. ";
	}
;

class HouseZone: Room
	routeTableZone = 'house'
;
class HouseRoom: HouseZone;
class HouseOutdoor: HouseZone, OutdoorRoom;

class TownZone: Room
	routeTableZone = 'town'
;
class TownOutdoor: TownZone, OutdoorRoom;

class CarnivalZone: Room
	routeTableZone = 'carnival'
;
class CarnivalRoom: CarnivalZone;
class CarnivalOutdoor: CarnivalZone, OutdoorRoom;

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

downtownWest: TownOutdoor 'Downtown West'
	"This is the west end of downtown, which much resembles the east
		end of downtown.  Your house is conveniently exactly one
		step due south of here. "
	south = frontYard
	east = downtownEast
;

downtownEast: TownOutdoor 'Downtown East'
	"This is the east end of downtown, which much resembles the west
		end of downtown.  The outskirts of town are north of here. "
	north = outskirts
	west = downtownWest
;

outskirts: TownOutdoor 'The Outskirts of Town'
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
	initialPlayerChar = me
	newGame() {
		local l;

		l = routeTableRoom.getPath(bedroom, secretRoom);
		"Path from <q><<bedroom.name>></q>
			<q><<secretRoom.name>></q>\n ";
		l.forEach(function(o) {
			"\t<<o.routeTableID>>:  <<o.name>>\n ";
		});
	}
;
