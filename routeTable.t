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

class RouteTableObject: object
	svc = nil

	_debug(msg?) {}
	_error(msg?) { aioSay('\n<<(svc ? '<<svc>>: ' : '')>><<msg>>\n '); }
;

class RouteTableVertex: SimpleGraphVertex
	routeTableNextHop = perInstance(new LookupTable())

	getRouteTableNextHop(id) { return(routeTableNextHop[id]); }
	setRouteTableNextHop(id, v) { routeTableNextHop[id] = v; }

	construct(i?, d? ) { inherited(i, d); }
;

class RouteTable: RouteTableObject, SimpleGraphDirected
	vertexClass = RouteTableVertex
	_routeTableBridge = perInstance(new LookupTable())

	getRouteTableBridge(id) { return(_routeTableBridge[id]); }

	addRouteTableBridge(id, src, dst) {
		local l;

		l = _routeTableBridge[id];
		if(l == nil) {
			l = new Vector();
			_routeTableBridge[id] = l;
		}
		l.append([src, dst]);

		return(true);
	}
;

routeTableRoot: RouteTable, PreinitObject
	vertexClass = SimpleGraphVertex

	execute() {
		forEachInstance(Room, function(o) { addRoomToRouteTable(o); });
		forEachInstance(Room, function(o) { addEdgesToRouteTable(o); });
		computeRouteTables();
		//logGraphs();
	}

	logGraphs() {
		local d;

		_debug('==========');
		_debug('main graph:');
		log();
		_debug('=====');
		getVertices().forEachAssoc(function(k, v) {
			_debug('graph for <<k>>:');
			d = v.getData();
			d.log();
		});
		_debug('==========');
	}

	addRoomToRouteTable(rm) {
		local g, id, v;

		// If there's no zone explicitly declared on the room,
		// stuff it in the catchall default zone.
		if(rm.routeTableZone == nil)
			rm.routeTableZone = '_defaultZone';
		
		// If the zone doesn't exist, create it.
		// Each zone is a vertex in our graph, but it is also
		// a graph itself.
		if((v = getVertex(rm.routeTableZone)) == nil) {
			v = addVertex(rm.routeTableZone);
			v.setData(new RouteTable());
		}

		g = v.getData();
		id = rm.routeTableZone + '-' + toString(g.order);
		// Add a vertex for the room to the zone graph.
		v = g.addVertex(id);

		//_debug('adding room <q><<id>></q> (<<rm.name>>) to zone
			//<q><<rm.routeTableZone>></q>');

		// Associate the room with the vertex in the zone graph.
		if(v != nil) {
			v.setData(rm);
			rm.id = id;
		}
	}

	addEdgesToRouteTable(rm) {
		local a, c, dst;

		a = gameMain.initialPlayerChar;

		Direction.allDirections.forEach(function(d) {
			c = rm.getTravelConnector(d, a);
			if(c == nil)
				return;
			dst = c.getDestination(rm, a);
			if(dst == nil)
				return;
			if(rm.routeTableZone != dst.routeTableZone)
				addBridge(rm, dst);
		});
	}

	// Add a bridge between zones.
	// This involves adding an edge in our graph and separately
	// making a note of which object is the bridge.  This involves some
	// duplication of data (we could just iterate through the vertices
	// looking for the one that connects any two zones) but creating a
	// separate table of bridges makes lookups way less expensive.
	addBridge(src, dst) {
		local v;

		if(src.routeTableZone == dst.routeTableZone)
			return(nil);

		_debug('adding bridge from <<src.routeTableZone>> to
			<<dst.routeTableZone>>');

		addEdge(src.routeTableZone, dst.routeTableZone, true);

		v = getZone(src.routeTableZone);
		v.addRouteTableBridge(dst.routeTableZone, src, dst);

		return(true);
	}

	computeZoneEdges(id, z) {
		local a, c, dst, g, rm;

		//_debug('computing edges for zone <q><<id>></q>');

		a = gameMain.initialPlayerChar;
		g = z.getData();
		g.getVertices().forEachAssoc(function(k, v) {
			rm = v.getData();
			if(rm == nil) {
				_debug('no room data for <<k>> in zone <<id>>');
				return;
			}
			//_debug('adding edges for vertex <q><<k>></q>
				//(<<rm.name>>)');
			Direction.allDirections.forEach(function(d) {
				if((c = rm.getTravelConnector(d, a)) == nil)
					return;
				if((dst = c.getDestination(rm, a)) == nil)
					return;
				if(rm == dst)
					return;
				if(rm.routeTableZone != dst.routeTableZone)
					return;
				g.addEdge(rm.id, dst.id, true);
			});
		});
	}

	computeRouteTables() {
		// Each of our vertices is a zone, and each zone is
		// a graph.  So we go through our vertices and tell each
		// one to go through each of ITS vertices and make a next
		// hop table for every possible path through itself.
		getVertices().forEachAssoc(function(k, v) {
			computeZoneEdges(k, v);
			// k is the zone ID, v is the zone (a vertex which
			// is also a graph)
			computeRouteTable(k, v);
		});
	}

	// Create the route table for the given zone.  id is the
	// zone ID and g is the zone graph.
	computeRouteTable(id, z) {
		local g, l, p, v;

		g = z.getData();
		// LookupTable of all the vertices in this zone.
		l = g.getVertices();

		l.forEachAssoc(function(k0, v0) {
			l.forEachAssoc(function(k1, v1) {
				if(k0 == k1) return;
				if((p = g.dijkstraPath(k0, k1)) == nil)
					return;
				v = g.getVertex(p[2]);
				v0.setRouteTableNextHop(k1, v.getData());
			});
		});
	}

	getZone(id) {
		local v;

		if((v = getVertex(id)) == nil)
			return(nil);
		return(v.getData());
	}

	nextHop(rm0, rm1) {
		local b, i, l, o, v;

		_debug('computing next hop from <<rm0.id>> to <<rm1.id>>');
		// If both rooms are the in same zone, just ask the
		// room what the next hop is (it should be precomputed).
		if(rm0.routeTableZone == rm1.routeTableZone) {
			_debug('returning precomputed next hop');
			o = getZone(rm0.routeTableZone);
			v = o.getVertex(rm0.id);
			return(v.getRouteTableNextHop(rm1.id));
			//return(rm0.nextHop(rm1));
		}

		// Get the path from the zone the source room is in to
		// the zone the destination room is in.
		l = dijkstraPath(rm0.routeTableZone, rm1.routeTableZone);
		if((l == nil) || (l.length < 2)) {
			_debug('no path between zones
				<q><<rm0.routeTableZone>></q>
				and <q><<rm1.routeTableZone>></q>');
			return(nil);
		}

		_debug('next hop path = <<toString(l)>>');

		// Get the source zone.
		v = getZone(rm0.routeTableZone);

if(l == nil) "NIL!!!\n ";

		// Look up the bridge between the zone we're in and the
		// next zone in the path.
		b = v.getRouteTableBridge(l[2]);

		// A bridge lookup returns a vector of the source and
		// destination nodes that connect the zones.  So if
		// any of the first nodes matches our current room, then
		// we're already at the threshold of the next zone, and
		// our next hop is the second node in the bridge.
		for(i = 1; i <= b.length; i++) {
			o = b[i];
			if(o[1] == rm0) {
				_debug('at zone boundary, returning
					bridge next hop');
				return(o[2]);
			}
		}

		// We DIDN'T match any bridge endpoints, so instead
		// we path to a near-side bridge endpoint.
		_debug('pathing to near side of zone bridge');
		return(nextHop(rm0, o[1]));
	}

	getPath(rm0, rm1) {
		local r, v;

		r = new Vector();
		v = rm0;
		r.append(v);
		while(v != rm1) {
			if(v == nil) {
				_debug('got bogus path');
				return(r);
			}
			"===<<v.name>>\n ";
			v = nextHop(v, rm1);
			r.append(v);
		}

		return(r);
	}
;
