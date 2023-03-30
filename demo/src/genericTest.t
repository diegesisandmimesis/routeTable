#charset "us-ascii"
//
// genericTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// Non-interactive test of generic route table pathfinding.  We use
// entirely abstract objects--no rooms or anything like that.
//
// It can be compiled via the included makefile with
//
//	# t3make -f genericTest.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

// No version info; we're never interactive.
versionInfo: GameID;

// Generic class 
class TestNodeData: object
	routeTableID = nil
	routeTableZone = nil
;


gameMain: GameMainDef
	newGame() { _createRouteTable(); }

	// Build a route table, doing everything "by hand".
	_createRouteTable() {
		local l, rt, z0, z1;

		// Create the table.
		rt = new RouteTable();

		// Add a new zone.
		z0 = rt.addZone('foo');

		// Add nodes to the zone.
		z0.addNode('foo1');
		z0.addNode('foo2');
		z0.addNode('foo3');

		// Add connections between the nodes.  Note
		// that connections aren't bi-directional by
		// default, so if we want foo <-> bar we
		// need to define foo -> bar AND bar -> foo.
		z0.addConnection('foo1', 'foo2');
		z0.addConnection('foo2', 'foo1');
		z0.addConnection('foo2', 'foo3');
		z0.addConnection('foo3', 'foo2');

		// Same as above, only for zone "bar".
		z1 = rt.addZone('bar');
		z1.addNode('bar1');
		z1.addNode('bar2');
		z1.addNode('bar3');
		z1.addConnection('bar1', 'bar2');
		z1.addConnection('bar2', 'bar1');
		z1.addConnection('bar3', 'bar2');
		z1.addConnection('bar2', 'bar3');

		// Now connect the zones.  Like connections within
		// a zone, connections between zones aren't bi-directional
		// by default.
		rt.connectZones('foo', 'bar', z0.getNode('foo3'),
			z1.getNode('bar1'));
		rt.connectZones('bar', 'foo', z1.getNode('bar1'),
			z0.getNode('foo3'));

		// Now generate all the next hop caches for the layout
		// we just pieced together.
		rt.generateNextHopCaches();

		// Now try to find a path from one end of our "network"
		// to the other.
		l = rt.findPathWithBridges(z0.getNode('foo1'),
			z1.getNode('bar3'));

		if(l == nil) {
			"ERROR: pathfinding failed\n";
		} else {
			l.forEach(function(o) {
				"<<o.routeTableID>>\n ";
			});
		}
	}
;
