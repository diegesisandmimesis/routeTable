#charset "us-ascii"
//
// routeTableZone.t
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

// Define some route table types.  The base module mostly just worries
// about rooms, though.
enum roomRouteTable, dialogRouteTable, goalRouteTable, procgenRouteTable;

class RouteTableZone: RouteTableObject, SimpleGraphVertex
	// Unique-ish ID for this zone
	routeTableZoneID = nil

	// Type of route table.  By default we assume we're handling rooms,
	// because that's the kind of pathfinding most people care about.
	routeTableType = roomRouteTable

	// Static routes.
	// By default if we have no path to a given destination, then NO
	// pathing takes place because Dijkstra doesn't have any way of
	// marking "potential" paths.
	// Here we record the near-side "bridge" locations for various other
	// zones, so we can path to THEM even if we can't path to the
	// requested destination.
	routeTableStaticRoutes = nil
;
