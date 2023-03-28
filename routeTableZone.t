#charset "us-ascii"
//
// routeTableZone.t
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

// Class for the generic route table zone.
class RouteTableZone: RouteTableObject, SimpleGraphVertex,
	RouteTableNextHopVertex

	routeTableZoneID = nil

	routeTableType = nil

	// Static routes.
	// By default if we have no path to a given destination, then NO
	// pathing takes place because Dijkstra doesn't have any way of
	// marking "potential" paths.
	// Here we record the near-side "bridge" locations for various other
	// zones, so we can path to THEM even if we can't path to the
	// requested destination.
	// Static route declarations should be something like:
	//
	//	+RouteTableZone 'source_zone_id'
	//		routeTableStaticRoutes = static [
	//			'destination_zone_id' -> someInstanceReference
	//		]
	//	;
	//
	// ...where 'source_zone_id' is the source zone ID,
	// 'destination_zone_id' is the destination zone ID, and
	// someInstanceReference is the vertex IN THE SOURCE ZONE that
	// connects the two.
	//
	// All this is used for is when we have a path that we know takes us
	// from one zone into another zone BUT THAT PATH IS NOT CURRENTLY
	// VALID, then we try to path to the given vertex instead.
	routeTableStaticRoutes = perInstance(new LookupTable())

	getRouteTableStatic(id0) { return(routeTableStaticRoutes[id0]); }

	initializeRouteTableZone() {
		if(location == nil)
			return(nil);

		location.addStaticRouteTableZone(self);

		return(true);
	}
;
