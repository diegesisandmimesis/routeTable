#charset "us-ascii"
//
// routeTableIntrazone.t
//
// Logic for handling "intrazone" connections.  That is, pathing between
// vertices inside the same route table/subgraph.
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

modify RouteTable
	// Actor instance to use when testing connectivity.
	routeTableTestActor = nil

	// Add all the edges between vertices in this zone.
	addIntrazoneEdges() {
		// Go through all of the tables's vertices.
		getVertices().forEachAssoc(function(k, v) {
			// Route table type-specific method for adding
			// edges.  For an example see routeTableRoomRouter.
			addIntrazoneEdgesForVertex(k, v);
		});
	}

	// Stub method, doesn't do anything.
	addIntrazoneEdgesForVertex(k, v) {}
;
