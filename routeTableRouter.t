#charset "us-ascii"
//
// routeTableRouter.t
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

class RouteTableRouter: RouteTable, PreinitObject
	// The type of zones we're a router for.
	routeTableType = nil

	// LookupTable for all of the statically-declared zones.
	_staticRouteTableZones = perInstance(new LookupTable())

	execute() {
		initializeStaticRouteTableZones();
	}

	// Find and remember all of the statically-declared zones we're
	// configured to care about.
	initializeStaticRouteTableZones() {
		forEachInstance(RouteTableZone, function(o) {
			// If there's no zone ID defined on this zone, skip it.
			if(o.routeTableZoneID == nil)
				return;

			// If we have a defined type and it doesn't match
			// this zone's, skip it.
			if((routeTableType != nil)
				&& (o.routeTableType != routeTableType))
				return;

			// Remember this zone.
			_staticRouteTableZones[o.routeTableZoneID] = o;
		});
	}

	// Look up and return a statically-declared zone.  Only used by
	// addVertex() below.
	_getStaticRouteTableZone(id) { return(_staticRouteTableZones[id]); }

	// Replacement method for SimpleGraph.  We check to see if we
	// have a statically-declared zone object to use for the named zone
	// and if so we use it.  Otherwise we fall back the default, which
	// is to create a new vertex for it.
	addVertex(id) {
		local o;

		if(getVertex(id)) return(nil);
		if((o = _getStaticRouteTableZone(id)) != nil)
			return(_addVertex(id, o));

		return(inherited(id));
	}
;
