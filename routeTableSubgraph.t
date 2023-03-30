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
	fixSubgraphs(zID?) {
		local i, id0, l, o0, z;

		if(zID == nil)
			zID = routeTableDefaultZoneID;

		// Make sure the zone exists.
		if((z = getZone(zID)) == nil)
			return;

		// If there are *no* subgraphs, then the zone is empty.
		// Nothing to do, done.
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
			//id0 = '_defaultSubgraph' + toString(i);
			id0 = _getSubgraphID(zID, i);

			// Add the new zone declaration to each vertex
			// in the subgraph.
			o0.forEach(function(o1) {
				z.getNode(o1).routeTableZone = id0;
			});
		}

		clearZones();

		execute();
	}

	// Returns a valid new zone ID for a subgraph-turned-zone.  The
	// main thing we do is make sure there are no ID collisions.
	_getSubgraphID(baseID, idx) {
		local id0, n, z;

		// Our first guess is just the base zone name plus the
		// index.
		id0 = baseID + toString(idx);

		// Counter for handling collisions.
		n = 0;

		// We can't do a while((z = getZone(id0)) != nil) {}
		// because the compiler will complain that z is assigned
		// but never used.
		z = getZone(id0);
		while(z != nil) {
			// Bump the counter.
			n += 1;

			// Try a slight variation of the ID.
			id0 = baseID + toString(idx) + '-' + toString(n);

			// See if this zone exists too.
			z = getZone(id0);
		}

		// Return whatever ID we discovered that isn't already in
		// use.
		return(id0);
	}
;

#endif // ROUTE_TABLE_NO_SUBGRAPH_FIX
