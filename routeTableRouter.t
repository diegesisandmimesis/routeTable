#charset "us-ascii"
//
// routeTableRouter.t
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

/*

// Generic router class.
// A router is a graph of route tables/zones, where the zones are themselves
// graphs of whatever we're routing (rooms, for example).
// So if we have a bunch of rooms in a "cave" zone and a bunch of rooms
// in a "outside" zone, then our router would keep track of the connections
// between the "cave" rooms and the "outside" rooms.
class RouteTableRouter: RouteTableNextHopGraph, SimpleGraphDirected,
	PreinitObject

	// The type of zones we're a router for.
	routeTableType = nil

	// LookupTable for all of the statically-declared zones.
	_staticRouteTableZones = perInstance(new LookupTable())

	execute() {
		initializeStaticRouteTableZones();

		// We DON'T build our next hop tables here, because
		// individual instances are going to do additional
		// preinit stuff that will probably create new zones for
		// us to keep track of.
		// IMPORTANT:  ANY INSTANCE NEEDS TO CALL
		// buildNextHopRouteTables() ITSELF AFTER IT IS DONE ADDING
		// ZONES.
		// When in doubt, this should go at the bottom of the
		// instance's execute() method (which also MUST call
		// inherited() or call initializeStaticRouteTableZones()
		// as well).
		//buildNextHopRouteTables();
	}

	// Replacement method for
	// RouteTableNextHopGraph.addNextHopRouteTableVertex() from
	// routeTableNextHop.t
	// The default works for "generic" vertices; all of our
	// vertices are zones, and so we handle them slightly different.
	addNextHopRouteTableVertex(src, id, dst) {
		src.setRouteTableNextHop(id, dst);
	}

	// Find and remember all of the statically-declared zones we're
	// configured to care about.
	initializeStaticRouteTableZones() {
		forEachInstance(RouteTableZone, function(o) {
			// If there's no zone ID defined on this zone, skip it.
			if(o.routeTableZoneID == nil)
				return;

			// Handle zones declared with the +[object] syntax.
			if(o.initializeRouteTableZone() == true)
				return;

			// If we have a defined type and it doesn't match
			// this zone's, skip it.
			if((routeTableType != nil)
				&& (o.routeTableType != routeTableType))
				return;

			addStaticRouteTableZone(o);
		});
	}

	// Add a single statically-declared zone, maybe.
	addStaticRouteTableZone(z) {
		if((z == nil) || (!z.ofKind(RouteTableZone)))
			return(nil);

		// If the zone is already defined, skip it.
		if(_staticRouteTableZones[z.routeTableZoneID] != nil)
			return(nil);

		// Set the zone's type to be the same as the router's type.
		z.routeTableType = routeTableType;

		// Remember this zone.
		_staticRouteTableZones[z.routeTableZoneID] = z;

		return(true);
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

	// Rebuild the given zone.
	rebuildZone(id) {
		local g;

		// Get the zone object.
		g = getRouteTableZone(id);

		// Clear the zone's next hop tables.
		clearZoneNextHopTables(id, g);

		// Clear the edges in the zone's graph.
		clearIntrazoneEdges(id, g);

		// Rebuild all the stuff we just cleared.
		buildZoneRouteTable(id, g);

		// Clear the bridges--connections between this zone and
		// other zones.
		g.clearRouteTableBridges().forEach(function(o) {
			getRouteTableZone(o).clearRouteTableBridges();
		});

		// Rebuild bridges.
		forEachInstance(Room, function(o) { addBridgesToZone(o); });
	}

	// Create a new zone.  First arg is the zone ID, second arg is the data
	// to set on the vertex.
	addRouteTableZone(id, data) {
		local v;

		if((v = addVertex(id)) == nil)
			return(nil);

		v.setData(data);

		return(true);
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

	// The "zone path" is the list of zones that have to be
	// traversed to get from zone id0 to zone id1.
	getRouteTableZonePath(id0, id1) {
		local r, v;

		v = getVertex(id0);
		if((r = v.getRouteTableNextHop(id1)) == nil) {
			return(dijkstraPath(id0, id1));
		} else {
			return([id0, r.id]);
		}
	}

	// Get the next hop from the first vertex to the second.
	getRouteTableNextHop(v0, v1) {
		local b, p, l, o, v;

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
		l = getRouteTableZonePath(v0.routeTableZone, v1.routeTableZone);
		if((l == nil) || (l.length < 2)) {
			_debug('no path between zones
				<q><<v0.routeTableZone>></q>
				and <q><<v1.routeTableZone>></q>');
			return(nil);
		}

		_debug('next hop zone = <<l[2]>>');

		// Get the source zone.
		v = getRouteTableZone(v0.routeTableZone);

		// Look up the bridge between the zone we're in and the
		// next zone in the path.
		if((b = v.getRouteTableBridge(l[2])) == nil) {
			// No bridge, so now we see if there's a static
			// route defined.

			// First we get the vertex for the source zone.
			v = getVertex(v0.routeTableZone);

			// We check to see if the source zone has a
			// static route for the next zone in the path.
			// If not, we're done, fail.
			if((p = v.getRouteTableStatic(l[2])) == nil)
				return(nil);

			// We got a static route, so we try pathing
			// from the source vertex to the static
			// bridge vertex.
			return(getRouteTableNextHop(v0, p));
		}

		// If there's only one bridge, we use it.  Otherwise
		// we check the path length through each bridge and
		// select the shortest.
		// In both cases p will contain a single bridge, which
		// is a two-element array:  first element is the near-side
		// vertex in the bridge, second element is the far-side
		// vertex.
		if(b.length == 1)
			p = b[1];
		else
			p = selectRouteTableBridge(v0, v1, b);


		// We couldn't figure anything out, fail.
		if(p == nil)
			return(nil);

		// If the near-side bridge vertex is the source vertex,
		// then the next step is the far-side vertex.
		if(p[1] == v0)
			return(p[2]);

		// We DIDN'T match any bridge endpoints, so instead
		// we path to a near-side bridge endpoint.
		_debug('pathing to near side of zone bridge');
		return(getRouteTableNextHop(v0, p[1]));
	}

	// A bridge lookup always returns a vector of source and
	// destination nodes that connect the zones (if they're
	// connected).  So we go through all of the bridges to
	// see which one has the shortest path to our
	// destination.
	selectRouteTableBridge(v0, v1, b) {
		local len, path0, path1, r, t;

		// Best candidate path so far.
		r = nil;

		// Shortest path length so far.
		len = nil;

		// Go through all the bridges.
		b.forEach(function(o) {
			// Get the path from the source vertex and
			// the near-side bridge vertex.
			if((path0 = findPath(v0, o[1])) == nil)
				return;

			// Get the path from the far-side bridge vertex
			// and the destination vertex.
			if((path1 = findPath(o[2], v1)) == nil)
				return;
			
			// The total length of the path through this bridge.
			t = path0.length + path1.length;

			// If we don't have a candidate path yet, or the
			// path through this bridge is the shortest, remember
			// it.
			if((len == nil) || (t < len)) {
				len = t;
				r = o;
			}
		});

		return(r);
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
;
*/
