#charset "us-ascii"
//
// routeTableRoom.t
//
// Route table logic for rooms.
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

#ifndef ROUTE_TABLE_NO_ROOMS

// Just add an empty ID and zone property to the base Room class.
modify Room
	routeTableID = nil
	routeTableZone = nil
;

class RouteTableRoom: RouteTable
	addIntrazoneEdgesForVertex(k, v, a) {
		local c, dst, rm;

		// The data on each vertex in the zone's routing table
		// is the Room instance for that vertex.
		rm = v.getData();

		// We should never have no data for a vertex, but we
		// check anyway.
		if(rm == nil) {
			_debug('no room data for <<k>> in zone <<id>>');
			return;
		}

		// Now we go through all the directions.
		Direction.allDirections.forEach(function(d) {
			// Check to see if there's a connector from
			// this room in the given direction, for the
			// given actor.
			if((c = rm.getTravelConnector(d, a)) == nil)
				return;

			// Now see if there's a destination for the
			// connector when it's this actor coming from
			// this room.
			if((dst = c.getDestination(rm, a)) == nil)
				return;

			// If the room loops back on itself we don't
			// need to do anything.
			if(rm == dst)
				return;

			// If the destination isn't in the same zone
			// as this room, skip it.
			if(rm.routeTableZone != dst.routeTableZone)
				return;

			// Add the edge.
			addEdge(rm.routeTableID, dst.routeTableID, true);
		});
	}
;

// Our top-level router for Room instances.
routeTableRoomRouter: RouteTableRouter
	// We use the vanilla vertex class for our vertices, even though
	// every vertex in the zone graph is in fact a graph itself.
	// SimpleGraphVertex lets us add arbitrary data to each object, so
	// what we do is create a SimpleGraph instance and add it to each
	// vertex as data.  We DON'T multi-class/mixin both the graph and
	// vertex stuff onto a single object because that would cause
	// method/property name collisions.
	vertexClass = SimpleGraphVertex

	routeTableType = roomRouteTable

	execute() {
		inherited();

		// Go through every room and try to figure out what zones to
		// add.
		forEachInstance(Room, function(o) { addRoomToZone(o); });

		// Then go through every room and figure which ones connect
		// different zones.
		forEachInstance(Room, function(o) { addBridgesToZone(o); });

		// Finally compute intrazone next-hop routing tables.
		buildZoneRouteTables();
	}

	// Add the given Room instance to the zone.
	addRoomToZone(rm) {
		local g, id, v;

		// If there's no zone explicitly declared on the room,
		// stuff it in the catchall default zone.
		if(rm.routeTableZone == nil)
			rm.routeTableZone = '_defaultZone';
		
		// If the zone doesn't exist, create it.
		if((v = getVertex(rm.routeTableZone)) == nil) {
			// Each zone is a vertex with a vertex ID equal
			// to the zone ID.
			v = addVertex(rm.routeTableZone);

			// Each zone is ALSO a graph of all the rooms in
			// that zone.  To handle this we just add an empty
			// route table to every vertex we add.  We DON'T
			// try to multiclass the vertex and graph together
			// because that would cause property and method name
			// collisions.
			v.setData(new RouteTableRoom());
		}

		// Get the route table for the zone.
		g = v.getData();

		// Generate a unique-ish ID for the vertex for the room
		// in the zone route table.
		id = rm.routeTableZone + '-' + toString(g.order);

		// Add a vertex for the room to the zone route table and
		// associate the Room instance with the it.
		if((v = g.addVertex(id)) != nil) {
			// Add the Room instance to the vertex as data.
			v.setData(rm);

			// Add the vertex ID to the Room instance.
			rm.routeTableID = id;
		}
	}

	// See if this room connects to a room in a different zone and,
	// if so, add it as a bridge.
	addBridgesToZone(rm) {
		local a, c, dst;

		// Use the initial player to test connectors.
		a = gameMain.initialPlayerChar;

		// Go through all directions.
		Direction.allDirections.forEach(function(d) {
			// See if the room has a travel connector for this
			// direction and actor.
			if((c = rm.getTravelConnector(d, a)) == nil)
				return;

			// See if the connector has a destination for an actor
			// coming from this room.
			if((dst = c.getDestination(rm, a)) == nil)
				return;

			// If the destination isn't in the same zone as this
			// room, we have a bridge.  Add it.
			if(rm.routeTableZone != dst.routeTableZone)
				addBridge(rm, dst);
		});
	}

	// Add a bridge between zones.
	// This involves adding an edge in our graph and separately
	// making a note of which object is the bridge.  This involves some
	// duplication of data (we could just iterate through the vertices
	// looking for the one that connects any two zones) but creating a
	// table makes lookups way less expensive.
	addBridge(src, dst) {
		local v;

		// We only care if the source and destination are in different
		// zones.
		if(src.routeTableZone == dst.routeTableZone)
			return(nil);

		_debug('adding bridge from <<src.routeTableZone>> to
			<<dst.routeTableZone>>');

		// Add an edge to our graph (the zone routing table)
		// indicating a connection from the source vertex to the
		// destination verted.  The third argument tells the graph
		// logic not to create any new vertices if they don't already
		// exist.
		addEdge(src.routeTableZone, dst.routeTableZone, true);

		// Get the routing table for the source vertex's zone.
		v = getRouteTableZone(src.routeTableZone);

		// Add the bridge.
		v.addRouteTableBridge(dst.routeTableZone, src, dst);

		return(true);
	}

	// Compute all the intrazone next-hop route tables.
	// These allow us to check any given vertex/room in a zone and ask
	// it what the next room is in the path to any other room in the
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
	// ID, and z is the zone graph.
	buildZoneRouteTable(id, g) {
		// First we add all the edges (connections between
		// rooms) to the zone's graph.
		//addIntrazoneEdges(id, g);
		g.addIntrazoneEdges();

		// Now we compute all the next-hop route information
		// for each vertex (room) in the zone's graph.
		//buildZoneNextHopTables(id, g);
		g.buildNextHopRouteTables();
	}

	// Clear this zone's graph.
	clearIntrazoneEdges(id, g) {
		g.edgeIDList().forEach(function(o) {
			g.removeEdge(o[1], o[2]);
		});
	}

	// Clear this zones next hop tables.
	clearZoneNextHopTables(id, g) {
		g.getVertices().forEachAssoc(function(k, v) {
			v.clearRouteTableNextHop();
		});
	}

	getRouteTableZone(id) {
		local v;

		if((v = getVertex(id)) == nil)
			return(nil);
		return(v.getData());
	}

	getRouteTableNextHop(rm0, rm1) {
		local b, i, l, o, v;

		_debug('computing next hop from <<rm0.routeTableID>>
			to <<rm1.routeTableID>>');
		// If both rooms are the in same zone, just ask the
		// room what the next hop is (it should be precomputed).
		if(rm0.routeTableZone == rm1.routeTableZone) {
			_debug('returning precomputed next hop');
			o = getRouteTableZone(rm0.routeTableZone);
			v = o.getVertex(rm0.routeTableID);
			return(v.getRouteTableNextHop(rm1.routeTableID));
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

		_debug('next hop zone path = <<toString(l)>>');

		// Get the source zone.
		v = getRouteTableZone(rm0.routeTableZone);

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
			if(o[1] == rm0) {
				_debug('at zone boundary, returning
					bridge next hop');
				return(o[2]);
			}
		}

		// We DIDN'T match any bridge endpoints, so instead
		// we path to a near-side bridge endpoint.
		_debug('pathing to near side of zone bridge');
		return(getRouteTableNextHop(rm0, o[1]));
	}

	findPath(rm0, rm1) {
		local r, v;

		r = new Vector();
		v = rm0;
		while((v != rm1) && (v != nil)) {
			r.append(v);
			v = getRouteTableNextHop(v, rm1);
		}

		return(r);
	}

	rebuildZone(id) {
		local g;

		g = getRouteTableZone(id);
		clearZoneNextHopTables(id, g);
		clearIntrazoneEdges(id, g);
		buildZoneRouteTable(id, g);

		g.clearRouteTableBridges().forEach(function(o) {
			getRouteTableZone(o).clearRouteTableBridges();
		});
		// Rebuild bridges
		forEachInstance(Room, function(o) { addBridgesToZone(o); });
	}
;

#endif // ROUTE_TABLE_NO_ROOMS
