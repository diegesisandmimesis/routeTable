#charset "us-ascii"
//
// routeTableVertex.t
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

// Class for 
class RouteTableVertex: SimpleGraphVertex
	routeTableNextHop = perInstance(new LookupTable())

	getRouteTableNextHop(id) { return(routeTableNextHop[id]); }
	setRouteTableNextHop(id, v) { routeTableNextHop[id] = v; }

	construct(i?, d? ) { inherited(i, d); }
;
