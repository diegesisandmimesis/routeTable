#charset "us-ascii"
//
// routeTable.t
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

// Module ID for the library
routeTableModuleID: ModuleID {
        name = 'Route Table Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

// Class for vertices in the route table.  Each will contain a
// RouteTableZone as data
class RouteTableVertex: RouteTableObject, SimpleGraphVertex
	routeTableID = nil
	routeTableZone = nil

	construct(v, d?) {
		id = v;
		routeTableID = v;
		_data = (((d != nil) && d.ofKind(RouteTableZone))
			? d
			: new RouteTableZone(v));
	}
;

// Define some route table types.  The base module mostly just worries
// about rooms, though.
enum roomRouteTable, dialogRouteTable, goalRouteTable, procgenRouteTable;

// Class for our routing tables.  The base class is a directed graph.
// This is just the stub class.  Almost all of the functionality lives
// in routeTableBridge.t, routeTableIntrazone.t, routeTableNextHop.t,
// and RouteTableStatic.t.
class RouteTable: RouteTableObject, SimpleGraphDirected, PreinitObject
	// The class to use for our graph vertices.
	vertexClass = RouteTableVertex

	// The table type.  In most cases this will probably be
	// roomRouteTable, which is to say we handle pathing between rooms.
	routeTableType = nil

	// LookupTable for the bridge(s) between this zone and other zones.
	_routeTableBridge = perInstance(new LookupTable())

	// LookupTable for zones that are declared via the +[object]
	// syntax.  We look for these at preinit so we can use them
	// instead of creating a new RouteTableZone instance.
	_staticRouteTableZones = perInstance(new LookupTable())

	execute() {
		// This is where we look for RouteTableZone instances
		// that were declared in the game source.
		initializeRouteTableZones();

		// Most derived classes probably want to call 
		// generateNextHopCaches() after execute();
	}

	// Find and remember all of the statically-declared zones we're
	// configured to care about.
	initializeRouteTableZones() {
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

			addStaticZone(o);
		});
	}

	// Add a single statically-declared zone, maybe.
	addStaticZone(z) {
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
	// is to create a new "empty" vertex for it.
	addVertex(id) {
		local o, v;

		if(getVertex(id)) return(nil);
		if((o = _getStaticRouteTableZone(id)) != nil) {
			v = vertexClass.createInstance(id, o);
			return(_addVertex(id, v));
		}

		return(inherited(id));
	}

	// Go through all of our zones and have them create their
	// next hop caches (of e.g. room connections), and then we create our
	// own next hop cache (of zone connections).
	generateNextHopCaches() {
		local z;

		// Generate the next hop data for each individual zone.
		vertexIDList().forEach(function(o) {
			if((z = getZone(o)) == nil)
				return;

			z.generateNextHopCache();
		});

		// Generate the next hop data for the zone graph.
		generateNextHopCache();
	}

	// Clear all the zones.
	clearZones() {
		local z;

		// Go through all our vertices...
		vertexIDList().forEach(function(k) {
			// ...telling each zone to clear itself...
			if((z = getZone(k)) != nil)
				z.clear();

			// ...and then removing the vertex.
			removeVertex(k);
		});
	}

	// Rebuild the indicated zone.  Used when connectivity within
	// the zone changes.
	rebuildZone(id0) {
		local z;

		if((z = getZone(id0)) == nil) {
			_debug('request to rebuild nonexistent zone <<id0>>');
			return(nil);
		}

		disconnectZone(id0);
		z.rebuild();

		return(true);
	}

	// Connnect two zones.  The first two args are zone IDs:  the
	// "source" zone and the "destination" zone.  The next two args
	// are the vertices that bridge the two zones.  v0 needs to be
	// in the id0 zone and v1 needs to be in the id1 zone.
	connectZones(id0, id1, v0, v1) {
		local z0, z1;

		if((z0 = getZone(id0)) == nil) {
			_debug('connectZones() got bogus zone id <<id0>>');
			return(nil);
		}
		if((z1 = getZone(id1)) == nil) {
			_debug('connectZones() got bogus zone id <<id1>>');
			return(nil);
		}
		if((z0.getNode(v0.routeTableID)) == nil) {
			_debug('connectZones() first vertex not in
				zone <<id0>>');
			return(nil);
		}
		if((z1.getNode(v1.routeTableID)) == nil) {
			_debug('connectZones() second vertex not in
				zone <<id1>>');
			return(nil);
		}

		// Add a bridge to the "source" zone.
		z0.addBridge(id1, v0, v1);

		// Add the edge.
		addEdge(id0, id1);

		return(true);
	}

	disconnectZone(id0) {
		local z0;

		if((z0 = getZone(id0)) == nil) {
			_debug('disconnectZone() got bogus zone id <<id0>>');
			return(nil);
		}
		
		z0.getBridgeList().forEach(function(id1) {
			z0.removeBridgesToZone(id1);
			removeEdge(id0, id1);
		});

		return(true);
	}

	// Create a new zone.  First arg is the zone ID, second arg is the data
	// to set on the vertex.
	addZone(id, data?) {
		local v;

		// Sanity check args.
		if(getVertex(id))
			return(nil);

		// Data is actually a zone object, so we use the "private"
		// method to stuff it into the graph as a vertex.
		if((data != nil) && data.ofKind(RouteTableVertex)) {
			return(_addVertex(id, data).getData());
		}

		// Data isn't a zone, it's just data.  So we add the vertex
		// normally and then set the data on it.
		if((v = addVertex(id)) == nil)
			return(nil);

		if(data != nil)
			v.setData(data);

		return(v.getData());
	}

	// Returns the vertex data for the given zone.  That's the
	// RouteTable for the zone, which itself is a graph of the vertices
	// in that zone.
	getZone(id) {
		local v;

		if((v = getVertex(id)) == nil)
			return(nil);
		return(v.getData());
	}

	// The "zone path" is the list of zones that have to be
	// traversed to get from zone id0 to zone id1.
	getZonePath(id0, id1) { return(findNextHopPath(id0, id1)); }

	// A bridge lookup always returns a vector of source and
	// destination nodes that connect the zones (if they're
	// connected).  So we go through all of the bridges to
	// see which one has the shortest path to our
	// destination.
	selectBridge(v0, v1, b) {
		local len, path0, path1, r, t;

		// Best candidate path so far.
		r = nil;

		// Shortest path length so far.
		len = nil;

		// Go through all the bridges.
		b.forEach(function(o) {
			// Get the path from the source vertex and
			// the near-side bridge vertex.
			if((path0 = fetchNextHopWithBridges(v0, o[1])) == nil)
				return;

			// Get the path from the far-side bridge vertex
			// and the destination vertex.
			if((path1 = fetchNextHopWithBridges(o[2], v1)) == nil)
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

	// Get the next hop from the first vertex to the second.
	fetchNextHopWithBridges(v0, v1) {
		local b, p, l, v, z;

		_debug('computing next hop from <<v0.routeTableID>>
			to <<v1.routeTableID>>');

		// If both rooms are the in same zone, just ask the
		// room what the next hop is (it should be precomputed).
		if(v0.routeTableZone == v1.routeTableZone) {
			if((z = getZone(v0.routeTableZone)) == nil) {
				_debug('failed to lookup zone
					<<v0.routeTableZone>>');
				return(nil);
			}

			if((v = z.getVertex(v0.routeTableID)) == nil) {
				_debug('failed to get vertex for
					<<v0.routeTableID>>');
				return(nil);
			}

			// Make sure we can get a next hop.
			if((v = v.getNextHop(v1.routeTableID)) == nil) {
				_debug('failed to get next hop from
					<<v0.routeTableID>> to
					<<v1.routeTableID>>');
				return(nil);
			}

			return(z.getNode(v.id));
		}

		// Get the path from the zone the source room is in to
		// the zone the destination room is in.
		l = getZonePath(v0.routeTableZone, v1.routeTableZone);
		if((l == nil) || (l.length < 2)) {
			_debug('no path between zones
				<q><<v0.routeTableZone>></q>
				and <q><<v1.routeTableZone>></q>');
			return(nil);
		}

		_debug('next hop zone = <<l[2].id>>');

		// Get the source zone.
		v = getZone(v0.routeTableZone);

		// Look up the bridge between the zone we're in and the
		// next zone in the path.
		if((b = v.getBridge(l[2].id)) == nil) {
			// No bridge, so now we see if there's a static
			// route defined.

			// First we get the source zone.
			z = getZone(v0.routeTableZone);

			// We check to see if the source zone has a
			// static route for the next zone in the path.
			// If not, we're done, fail.
			if((p = v.getStaticRoute(l[2].id)) == nil)
				return(nil);

			// We got a static route, so we try pathing
			// from the source vertex to the static
			// bridge vertex.
			return(fetchNextHopWithBridges(v0, p));
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
			p = selectBridge(v0, v1, b);


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
		return(fetchNextHopWithBridges(v0, p[1]));
	}

	validateVertex(v) {
		if((v == nil) || (v.routeTableZone == nil)
			|| (v.routeTableID == nil))
			return(nil);
		return(true);
	}

	// Returns the path, if any, between the given two vertices.
	findPathWithBridges(v0, v1) {
		local r, v;

		if(!validateVertex(v0))
			return(nil);
		if(!validateVertex(v1))
			return(nil);

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
			v = fetchNextHopWithBridges(v, v1);
		}

		// Return the path.  We only reach here if pathing failed.
		return(r);
	}
;
