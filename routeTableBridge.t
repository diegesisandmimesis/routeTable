#charset "us-ascii"
//
// routeTableBridge.t
//
// We call connections (edges) between vertices in two different route
// tables (subgraphs) "bridges".  The logic for handling bridges lives here.
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

/*

modify RouteTable
	// LookupTable for the bridge(s) between this zone and other zones.
	_routeTableBridge = perInstance(new LookupTable())

	// Returns the bridge information for the given destination zone ID.
	getRouteTableBridge(id) { return(_routeTableBridge[id]); }

	// Add a bridge.  The first arg is the destination zone ID, src is
	// the vertex in this zone that connects to the destination zone, and
	// dst is the vertex in the destination zone that src connects to.
	// The bridge data is always a vector, because two zones might be
	// connected by more than one bridge.
	addRouteTableBridge(id, src, dst) {
		local l;

		l = _routeTableBridge[id];

		// If the bridge entry doesn't exist, create an empty vector
		// for it.
		if(l == nil) {
			l = new Vector();
			_routeTableBridge[id] = l;
		}

		// Append the bridge data.
		l.append([src, dst]);

		return(true);
	}

	// Clear our bridge data.
	clearRouteTableBridges() {
		local r;

		r = new Vector();

		_routeTableBridge.keysToList().forEach(function(o) {
			_routeTableBridge.removeElement(o);
			r += o;
		});

		return(r);
	}
;
*/
