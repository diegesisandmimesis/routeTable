#charset "us-ascii"
//
// routeTableStatic.t
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

modify RouteTable
	// Static routes.
	// By default if we have no path to a given destination, then NO
	// pathing takes place because Dijkstra doesn't have any way of
	// marking "potential" paths.
	// Here we record the near-side "bridge" locations for various other
	// zones, so we can path to THEM even if we can't path to the
	// requested destination.
	routeTableStaticRoutes = nil

	getRouteTableStatic(id) {
	}
;
