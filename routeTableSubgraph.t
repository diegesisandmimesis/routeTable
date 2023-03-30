#charset "us-ascii"
//
// routeTableSubgraph.t
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

// We're wrapped in a giant preprocessor conditional so we can be
// toggled on and off at compile time.
#ifndef ROUTE_TABLE_NO_SUBGRAPH_FIX

modify roomRouter
	fixSubgraphs() {
		local i, id0, l, o0, z;

		if((z = getZone(routeTableDefaultZoneID)) == nil)
			return;

		if((l = z.generateSubgraphs()) == nil)
			return;

		// If there aren't at least two subgraphs then we don't
		// have anything to do.
		if(l.length < 2)
			return;

		_debug('fixing <<toString(l.length)>> subgraphs');

		// The subgraph list is a vector, each value of which is
		// itself a vector containing all of the vertices in each
		// identified subgraph.
		for(i = 1; i <= l.length; i++) {
			// o0 is an individual subgraph.
			o0 = l[i];

			// A new zone identifier for this subgraph
			id0 = '_defaultSubgraph' + toString(i);

			// Add the new zone declaration to each vertex
			// in the subgraph.
			o0.forEach(function(o1) {
				z.getNode(o1).routeTableZone = id0;
			});
		}

		clearZones();

		execute();
	}
;

#endif // ROUTE_TABLE_NO_SUBGRAPH_FIX
