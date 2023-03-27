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

	// Compute all the intrazone next-hop route tables.
	// These allow us to check any given vertex in a zone and ask
	// it what the next vertex is in the path to any other vertex in the
	// same zone.
	buildZoneRouteTables() {
		// Each of our vertices is a zone, and each zone is
		// a graph.  So we go through our vertices and tell each
		// one to go through each of ITS vertices and make a next
		// hop table for every possible path through itself.
		getVertices().forEachAssoc(function(k, v) {
			buildZoneRouteTable(k, v.getData());
		});
	}

	// Build an individual zone's route table.  The ID is the zone
	// ID, and g is the zone graph.
	buildZoneRouteTable(id, g) {
		// First we add all the edges (connections between
		// rooms) to the zone's graph.
		g.addIntrazoneEdges();

		// Now we compute all the next-hop route information
		// for each vertex (room) in the zone's graph.
		g.buildNextHopRouteTables();
	}

	// Clear this zone graph's edges.
	clearIntrazoneEdges(id, g) {
		g.edgeIDList().forEach(function(o) {
			g.removeEdge(o[1], o[2]);
		});
	}

	// Clear this zone's next hop tables.
	clearZoneNextHopTables(id, g) {
		g.getVertices().forEachAssoc(function(k, v) {
			v.clearRouteTableNextHop();
		});
	}

	// Returns the vertex data for the given zone.  That's the
	// RouteTable for the zone, which itself is a graph of the vertices
	// in that zone.
	getRouteTableZone(id) {
		local v;

		if((v = getVertex(id)) == nil)
			return(nil);
		return(v.getData());
	}

	// Get the next hop from the first vertex to the second.
	getRouteTableNextHop(v0, v1) {
		local b, i, l, o, v;

		_debug('computing next hop from <<v0.routeTableID>>
			to <<v1.routeTableID>>');
		// If both rooms are the in same zone, just ask the
		// room what the next hop is (it should be precomputed).
		if(v0.routeTableZone == v1.routeTableZone) {
			_debug('returning precomputed next hop');
			o = getRouteTableZone(v0.routeTableZone);
			v = o.getVertex(v0.routeTableID);
			return(v.getRouteTableNextHop(v1.routeTableID));
		}

		// Get the path from the zone the source room is in to
		// the zone the destination room is in.
		l = dijkstraPath(v0.routeTableZone, v1.routeTableZone);
		if((l == nil) || (l.length < 2)) {
			_debug('no path between zones
				<q><<v0.routeTableZone>></q>
				and <q><<v1.routeTableZone>></q>');
			return(nil);
		}

		_debug('next hop zone path = <<toString(l)>>');

		// Get the source zone.
		v = getRouteTableZone(v0.routeTableZone);

		// Look up the bridge between the zone we're in and the
		// next zone in the path.  If there's no bridge, there's
		// no path.  Fail.
		if((b = v.getRouteTableBridge(l[2])) == nil)
			return(nil);

		// A bridge lookup returns a vector of the source and
		// destination nodes that connect the zones.  So if
		// any of the first nodes matches our current room, then
		// we're already at the threshold of the next zone, and
		// our next hop is the second node in the bridge.
		for(i = 1; i <= b.length; i++) {
			o = b[i];
			if(o[1] == v0) {
				_debug('at zone boundary, returning
					bridge next hop');
				return(o[2]);
			}
		}

		// We DIDN'T match any bridge endpoints, so instead
		// we path to a near-side bridge endpoint.
		_debug('pathing to near side of zone bridge');
		return(getRouteTableNextHop(v0, o[1]));
	}

	// Returns the path, if any, between the given two vertices.
	findPath(v0, v1) {
		local r, v;

		// A vector to hold the path.
		r = new Vector();

		// The first step on the path is always the starting vertex.
		v = v0;

		// We keep iterating until we get a nil vertex.
		while(v != nil) {
			// First, add the vertex to our path.
			r.append(v);

			// If the current vertex is the destination vertex,
			// the we're done.  Immediately return the path.
			if(v == v1)
				return(r);

			// Get the next step in the path.
			v = getRouteTableNextHop(v, v1);
		}

		// Return the path.  We only reach here if pathing failed.
		return(r);
	}

	// Rebuild the given zone.
	rebuildZone(id) {
		local g;

		g = getRouteTableZone(id);
		clearZoneNextHopTables(id, g);
		clearIntrazoneEdges(id, g);
		buildZoneRouteTable(id, g);

		// Clear bridges.
		g.clearRouteTableBridges().forEach(function(o) {
			getRouteTableZone(o).clearRouteTableBridges();
		});

		// Rebuild bridges
		forEachInstance(Room, function(o) { addBridgesToZone(o); });
	}
;
