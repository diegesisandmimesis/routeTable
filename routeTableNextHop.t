#charset "us-ascii"
//
// routeTableNextHop.t
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

// Mixin class containing next hop methods for vertices.
class RouteTableNextHopVertex: RouteTableObject
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

// Mixin class containing next hop methods for graphs.
class RouteTableNextHopGraph: RouteTableObject
	// Create the next hop route tables on each of our vertices.
	buildNextHopRouteTables() {
		local l, p;

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

				// First element of the path will be the
				// current vertex, second is the next hop.
				addNextHopRouteTableVertex(v0, k1,
					getVertex(p[2]));
			});
		});
	}

	// Define the next hop for a given vertex.
	// src is the vertex we're setting the information for.
	// id is the path endpoint this is the next hop for, and
	// dst is the next hop vertex for it.
	addNextHopRouteTableVertex(src, id, dst) {
		src.setRouteTableNextHop(id, dst.getData());
	}
;
