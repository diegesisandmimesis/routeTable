#charset "us-ascii"
//
// routeTableZone.t
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

// Simple minimal class for nodes in a route table zone.  At minimum
// we need a routeTableID to identify the object, and a routeTableZone to
// figure out what zone it belongs to.
class RouteTableNode: object
	routeTableID = nil
	routeTableZone = nil
;

// Class for the generic route table zone.
class RouteTableZone: RouteTableObject, SimpleGraphDirected
	routeTableZoneID = nil

	routeTableType = nil

	nodeClass = RouteTableNode

	// LookupTable for the bridge(s) between this zone and other zones.
	_routeTableBridge = perInstance(new LookupTable())

	// Returns the bridge information for the given destination zone ID.
	getBridge(id0) { return(_routeTableBridge[id0]); }

	getBridgeList() { return(_routeTableBridge.keysToList()); }

	// Add a bridge.  The first arg is the destination zone ID, src is
	// the vertex in this zone that connects to the destination zone, and
	// dst is the vertex in the destination zone that src connects to.
	// The bridge data is always a vector, because two zones might be
	// connected by more than one bridge.
	addBridge(id0, src, dst) {
		local l;

		l = _routeTableBridge[id0];

		// If the bridge entry doesn't exist, create an empty vector
		// for it.
		if(l == nil) {
			l = new Vector();
			_routeTableBridge[id0] = l;
		}

		// Append the bridge data.
		l.append([src, dst]);

		return(true);
	}

	// Clear our bridge data.
	clearBridges() {
		_routeTableBridge.keysToList().forEach(function(o) {
			removeBridgesToZone(o);
		});
	}

	removeBridgesToZone(id0) {
		return(_routeTableBridge.removeElement(id0));
	}

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
	routeTableStaticRoute = perInstance(new LookupTable())

	getStaticRoute(id0) { return(routeTableStaticRoute[id0]); }
	addStaticRoute(id0, v) { routeTableStaticRoute[id0] = v; }

	construct(i) {
		routeTableZoneID = i;
		id = i;
	}

	initializeRouteTableZone() {
		if(location == nil)
			return(nil);

		location.addStaticZone(self);

		return(true);
	}

	// Add a node.  A "node" is just the data content of a vertex.
	// So if we're a zone in a route table for rooms, the node
	// will be a Room instance.
	addNode(id0, data?) {
		local v;

		if((v = addVertex(id0)) == nil) {
			_debug('failed to add vertex for node <<id0>>');
			return(nil);
		}

		if(data == nil)
			data = nodeClass.createInstance();

		data.routeTableID = id0;
		data.routeTableZone = routeTableZoneID;
		v.setData(data);

		return(v);
	}

	// Get a node.  Here a "node" is just the data set on the
	// named vertex.  So if we're a zone in a route table for rooms,
	// then the node will be a Room instance.
	getNode(id0) {
		local v;

		if((v = getVertex(id0)) == nil)
			return(nil);
		return(v.getData());
	}

	// Semantic sugar.  Add an edge.
	addConnection(id0, id1) { return(addEdge(id0, id1, true)); }

	// Remove all the vertices in this zone.
	clear() { vertexIDList().forEach(function(k) { removeVertex(k); }); }

	// Rebuild the zone's next hop caches.
	rebuild() {
		clearNextHopCache();
		generateNextHopCache();
	}
;
