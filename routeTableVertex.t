#charset "us-ascii"
//
// routeTableVertex.t
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

// Class for vertices in route table graphs.
class RouteTableVertex: SimpleGraphVertex, RouteTableNextHopVertex;
/*
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
*/
