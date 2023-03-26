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
// Zones should generally consist of contiguous blocks of rooms whose
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

// Base class for all of our objects.  Just adds some debugging methods.
class RouteTableObject: object
	svc = nil

	_debug(msg?) {}
	_error(msg?) { aioSay('\n<<(svc ? '<<svc>>: ' : '')>><<msg>>\n '); }
;

// Class for vertices in route table graphs.
class RouteTableVertex: SimpleGraphVertex
	// LookupTable for the next hop(s) for this vertex, for
	// every other vertex in the graph.
	routeTableNextHop = perInstance(new LookupTable())

	// Return the next hop for the given destination vertex.
	getRouteTableNextHop(id) { return(routeTableNextHop[id]); }

	// Record the next hop.  First arg is the vertex ID, second
	// is the object that's the next hop to take to reach it from
	// this vertex.
	setRouteTableNextHop(id, v) { routeTableNextHop[id] = v; }

	clearRouteTableNextHop() {
		routeTableNextHop.keysToList().forEach(function(o) {
			routeTableNextHop.removeElement(o);
		});
	}
;

// Class for our routing tables.  The base class is a directed graph.
class RouteTable: RouteTableObject, SimpleGraphDirected
	// The class to use for our graph vertices.
	vertexClass = RouteTableVertex

	// LookupTable for the bridge(s) between this zone and other zones.
	_routeTableBridge = perInstance(new LookupTable())

	// Returns the bridge information for the given destination zone ID.
	getRouteTableBridge(id) { return(_routeTableBridge[id]); }

	// Add a bridge.  The first arg is the destination zone ID, src is
	// the vertex in this zone that connects to the destination zone, and
	// dst is the vertex in the destination zone that src connects to.
	// The bridge data is always a vector, because two zones might be
	// connected by more than one bridge.
	addRouteTableBridge(id, src, dst) {
		local l;

		l = _routeTableBridge[id];

		// If the bridge entry doesn't exist, create an empty vector
		// for it.
		if(l == nil) {
			l = new Vector();
			_routeTableBridge[id] = l;
		}

		// Append the bridge data.
		l.append([src, dst]);

		return(true);
	}

	clearRouteTableBridges() {
		local r;

		r = new Vector();

		_routeTableBridge.keysToList().forEach(function(o) {
			_routeTableBridge.removeElement(o);
			r += o;
		});

		return(r);
	}

	// Add all the edges between vertices in this zone.
	addIntrazoneEdges() {
		local a;

		// Use the initial player to figure out connectivity.
		a = gameMain.initialPlayerChar;

		// Go through all of the zone's vertices.  There will be one
		// per room in the zone.
		getVertices().forEachAssoc(function(k, v) {
			// Route table type-specific method for adding
			// edges.  For an example see routeTableRoomRouter.
			addIntrazoneEdgesForVertex(k, v, a);
		});
	}

	// Stub method, doesn't do anything.
	addIntrazoneEdgesForVertex(k, v, a) {}

	// Create the next hop route tables on each vertex in our zone.
	buildNextHopRouteTables() {
		local l, p, v;

		// LookupTable of all the vertices in this zone.
		l = getVertices();

		// Go through each vertex in the zone...
		l.forEachAssoc(function(k0, v0) {
			// ...and check it against every other vertex in the
			// zone.
			l.forEachAssoc(function(k1, v1) {
				// Make sure we're not trying to compute a
				// path to ourselves.
				if(k0 == k1)
					return;

				// Get the Dijkstra path between the vertices.
				if((p = dijkstraPath(k0, k1)) == nil)
					return;
				v = getVertex(p[2]);
				v0.setRouteTableNextHop(k1, v.getData());
			});
		});
	}
;

//class RouteTableRoot: RouteTable, PreinitObject
//;
