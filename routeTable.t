#charset "us-ascii"
//
// routeTable.t
//
// Pre-computed route tables for pathfinding.
//
// A game compiled with this module (and the simpleGraph module as a
// dependency) can, in the simplest case, get the path between two Room
// instances (if one exists) via:
//
//	path = routeTableRoom.findPath(rm0, rm1);
//
// ...where rm0 and rm1 are both Room instances and path will be a vector
// containing the path, with path[1] == rm0 and path[path.length] == rm1.
//
// This will work with no other setup, but for more efficient pathfinding,
// particularly in cases where the traversibility of the map isn't static,
// you can partition the map into zones.
//
// All that's required is to add...
//
//	routeTableZone = 'some_unique_identifier'
//
// ...to room declarations, either via something like:
//
//	bedroom: Room 'Your Bedroom'
//		"It's your bedroom. "
//		routeTableZone = 'house'
//	;
//
// ...or via classes, a la...
//
//	class HouseRoom: Room
//		routeTableZone = 'house'
//	;
//	bedroom: HouseRoom 'Your Bedroom' "It's your bedroom. ";
//	bathroom: HouseRoom 'Your Bathroom' "It's your bathroom. ";
//
// ...and so on.
//
// Zones should consist of contiguous blocks of rooms whose
// reachability is toggled by something in the game state:  a drawbridge
// that goes up and down, a door that needs a key, a shop that is only open
// on certain days, and that kind of thing.
//
// The "trick" or whatever is that we want to define zones so that we only
// ever have to recompute path information for small portions of the map
// when something changes.  Normally pathfinding information is generated
// on the fly, but that can be computationally expensive if it has to
// happen every turn.  So instead we can precompute paths when the game is
// compiled and then just update individual zones when the reachability of
// individual bits changes.
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

// Module ID for the library
routeTableModuleID: ModuleID {
        name = 'Route Table Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

// Define some route table types.  The base module mostly just worries
// about rooms, though.
enum roomRouteTable, dialogRouteTable, goalRouteTable, procgenRouteTable;

// Class for our routing tables.  The base class is a directed graph.
// This is just the stub class.  Almost all of the functionality lives
// in routeTableBridge.t, routeTableIntrazone.t, routeTableNextHop.t,
// and RouteTableStatic.t.
class RouteTable: RouteTableNextHopGraph, RouteTableNextHopVertex,
	SimpleGraphDirected

	// The class to use for our graph vertices.
	vertexClass = RouteTableZone

	// The table type.  In most cases this will probably be
	// roomRouteTable, which is to say we handle pathing between rooms.
	routeTableType = nil

/*
	// Called by the router.  This is only used if this zone has been
	// declared via the +[object] syntax under the router.  We
	// add ourselves to the list of zones the router manages.
	initializeRouteTable() {
		if(location == nil)
			return(nil);

		location.addStaticRouteTableZone(self);

		return(true);
	}
*/
;
