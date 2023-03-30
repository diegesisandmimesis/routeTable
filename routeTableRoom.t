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

roomRouter: RouteTable
	svc = 'roomRouter'

	routeTableType = roomRouteTable

	routeTableDefaultZoneID = '_defaultZone'
	nodeClass = Room

	routeTableActor = nil

	execute() {
		inherited();

		forEachInstance(Room, function(o) { addRoomToZone(o); });
		forEachInstance(Room, function(o) { addBridgeToZone(o); });
		forEachInstance(Room, function(o) { addRoomConnections(o); });

		generateNextHopCaches();

		fixSubgraphs();
	}

	getRouteTableActor() {
		if(routeTableActor != nil)
			return(routeTableActor);

		return(gameMain.initialPlayerChar);
	}

	addRoomToZone(rm) {
		local rmID, z;

		if(rm.routeTableZone == nil)
			rm.routeTableZone = routeTableDefaultZoneID;

		if((z = getZone(rm.routeTableZone)) == nil) {
			if((z = addZone(rm.routeTableZone)) == nil)
				return;
		}

		if(rm.routeTableID != nil)
			rmID = rm.routeTableID;
		else
			rmID = rm.routeTableZone + '-' + toString(z.order());

		if(z.addNode(rmID, rm) == nil) {
			_debug('failed to add room <<rmID>> to zone
				<<rm.routeTableZone>>');
			return;
		}

		_debug('added room <<rmID>> to zone <<rm.routeTableZone>>');

		rm.routeTableID = rmID;
	}

	addBridgeToZone(rm) {
		local a, c, dst;

		a = getRouteTableActor();

		Direction.allDirections.forEach(function(d) {
			if((c = rm.getTravelConnector(d, a)) == nil)
				return;

			if((dst = c.getDestination(rm, a)) == nil)
				return;

			if(rm.routeTableZone != dst.routeTableZone) {
				connectZones(rm.routeTableZone,
					dst.routeTableZone, rm, dst);
			}
		});
	}

	addRoomConnections(rm) {
		local a, c, dst, z;

		a = getRouteTableActor();

		if((z = getZone(rm.routeTableZone)) == nil)
			return;

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
			z.addConnection(rm.routeTableID, dst.routeTableID);
		});
	}

	rebuildZone(id0) {
		local rm, z;

		if(inherited(id0) == nil)
			return(nil);

		if((z = getZone(id0)) == nil)
			return(nil);

		z.vertexList().forEach(function(o) {
			rm = o.getData();
			addBridgeToZone(rm);
			addRoomConnections(rm);
			
		});

		return(true);
	}

	// Stub.  Method lives in routeTableSubgraph.t
	fixSubgraphs() {}

	// Pure semantic sugar.
	findPath(v0, v1) { return(findPathWithBridges(v0, v1)); }
;

#endif // ROUTE_TABLE_NO_ROOMS
