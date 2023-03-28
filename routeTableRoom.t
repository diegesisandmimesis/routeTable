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

//class RouteTableZoneRoom: RouteTableZone;

// Room-specific RouteTable class.
// Each kind of router needs to know how to figure out how vertices are
// connected, with rooms it's exits, and here's where we do it.
class RouteTableRoom: RouteTable
	routeTableTestActor = nil

	addIntrazoneEdgesForVertex(k, v) {
		local a, c, dst, rm;

		// If we have a test actor defined use it.  Otherwise
		// use the initial player.
		if((a = routeTableTestActor) == nil)
			a = gameMain.initialPlayerChar;

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
	vertexClass = RouteTableZone

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

		buildNextHopRouteTables();
	}

	// Add the given Room instance to the zone.
	addRoomToZone(rm) {
		local g, id, v;

		// If there's no zone explicitly declared on the room,
		// stuff it in the catchall default zone.
		if(rm.routeTableZone == nil)
			rm.routeTableZone = '_defaultZone';
		
		// If the zone doesn't exist, create it.
		if((g = getRouteTableZone(rm.routeTableZone)) == nil) {
			if(addRouteTableZone(rm.routeTableZone,
				new RouteTableRoom()) == nil)
				return;
			g = getRouteTableZone(rm.routeTableZone);
		}

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
;

#endif // ROUTE_TABLE_NO_ROOMS
