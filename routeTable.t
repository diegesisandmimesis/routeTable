#charset "us-ascii"
//
// routeTable.t
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
;

class RouteTableRoot: RouteTable, PreinitObject
;
