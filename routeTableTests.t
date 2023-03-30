#charset "us-ascii"
//
// routeTableTests.t
//
#include <adv3.h>
#include <en_us.h>
#include <date.h>
#include <bignum.h>

#include "routeTable.h"

#ifdef ROUTE_TABLE_TESTS

// Generic test class.
class RouteTableTest: RouteTableObject
	// Time when test was started.
	_start = nil

	// Minimum interval;  used to avoid divide-by-zero problems.
	_minInterval = perInstance(new BigNumber(0.000001))

	// Save the time when a test started.
	startTimer() { _start = new Date(); }

	_max(v0, v1) { return((v0 > v1) ? v0 : v1); }

	// Get the number of seconds since the start of the test.
	getInterval() {
		return(_max(
			((_start != nil)
				? ((new Date() - _start) * 86400)
				: nil),
			_minInterval
		));
	}

	runTest() {}
;

// Performance test.  Compares the performance of the routeTable pathfinding
// versus the pathfinding provided by roomPathFinder.findPath().
class RouteTablePerfTest: RouteTableTest
	_room0 = nil			// source room
	_room1 = nil			// destination room
	_iterations = nil		// number of iterations to run
	_actor = nil			// actor to use for roomPathFinder

	routeTableTime = nil		// how much time routeTable took
	nativeTime = nil		// how much time roomPathFinder took

	// Args are the two rooms to pathfind between, the number of iterations,
	// and the actor.
	construct(rm0, rm1, i?, a?) {
		_room0 = rm0;
		_room1 = rm1;

		// Do 10k iterations by default.
		_iterations = ((i != nil) ? i : 10000);

		// Use gameMain.initialPlayerChar by default.
		_actor = ((a != nil) ? a : gameMain.initialPlayerChar);
	}

	runTest() {
		local i;

		// Clear the counter.
		i = 0;

		// Start the timer.
		startTimer();

		// Do the tests.
		while(i < _iterations) {
			roomRouter.findPath(_room0, _room1);
			i += 1;
		}

		// Get the elapsed time.
		routeTableTime = new BigNumber(getInterval());

		// Now do the same thing for the other method.
		i = 0;
		startTimer();
		while(i < _iterations) {
			roomPathFinder.findPath(_actor, _room0, _room1);
			i += 1;
		}
		nativeTime = new BigNumber(getInterval());

		// Log the output.
		output();
	}

	output() {
		local ratio;

		"\nrouteTableRoomRouter.findPath() took
			<<toString(routeTableTime.roundToDecimal(3))>>
			seconds\n ";
		"\nroomPathFinder.findPath() took
			<<toString(nativeTime.roundToDecimal(3))>>
			seconds\n ";

		if(routeTableTime > nativeTime) {
			ratio = routeTableTime / nativeTime;
			"\nslowdown factor of
				<<toString(ratio.roundToDecimal(3))>>\n ";
		} else {
			ratio = nativeTime / routeTableTime;
			"\nspeedup factor of
				<<toString(ratio.roundToDecimal(3))>>\n ";
		}
	}
;

// Class for the rooms in our random maze.
class RouteTableRandomTestRoom: Room desc = "This is a generic room. ";

// Generates a random square maze and tests pathfinding through it.
class RouteTableRandomTest: RouteTableTest
	_mapWidth = nil		// length of a side of the map
	_mapSize = nil		// total number of rooms in the map

	_iterations = nil	// number of pathfinding passes to run

	_graph = nil		// graph of the rooms.

	construct(n?, i?) {
		// By default, we build a 10x10 maze.
		_mapWidth = ((n != nil) ? n : 10);

		// Map size is the square of the width.
		_mapSize = _mapWidth * _mapWidth;

		_iterations = ((i != nil) ? i : nil);
	}

	// Preinit method.  Here's where we build the map.
	preinit() {
		_createGraph();
		_buildMap();
		gameMain.initialPlayerChar.location = _getRoom(1);
	}

	// Runtime method.  Run the tests.
	runTest() {
		new RouteTablePerfTest(_getRoom(1), _getRoom(2),
			_iterations).runTest();
	}

	// Create a graph for our map.
	// For our simple square maze this is overkill, but we might
	// want to generate different map types using e.g. Prim's
	// algorithm later.
	_createGraph() {
		local i, id, rm, v;

		// Create the empty graph;
		_graph = new SimpleGraph();

		i = 1;
		while(i <= _mapSize) {
			// Rooms are identified by their number
			id = 'room' + toString(i);

			// Add a vertex for the room.
			v = _graph.addVertex(id);

			// Create the Room instance.
			rm = new RouteTableRandomTestRoom();
			rm.roomName = id;

			// Add the Room instance to the graph vertex.
			v.setData(rm);

			i += 1;
		}
	}

	// Convenience method to retrieve the Room instance by the room
	// number.
	_getRoom(i) {
		return(_graph.getVertex('room' + toString(i)).getData());
	}

	// Convert the graph into a T3 map.  The rooms already exist,
	// here we just have to connect them.
	// We just use a simple binary tree maze generation algorithm:
	// in every cell, we connect either up or to the right, but
	// never both.
	_buildMap() {
		local i, top;

		top = _mapSize - _mapWidth;
		// Not a typo, we don't twiddle the last cell.
		for(i = 1; i < _mapSize; i++) {
			if((i % _mapWidth) == 0) {
				// If i % _mapWidth is zero, then we're at the
				// the east edge, so we have to go north.
				_connectRooms(i, i + _mapWidth, 'n');
			} else if(i > top) {
				// If the room number is > top, we're at the
				// north edge, so we have to go east.
				_connectRooms(i, i + 1, 'e');
			} else {
				// We're not on either the north or east
				// edge, so we roll the dice and randomly
				// go north or east.
				if(rand(2) == 1) {
					_connectRooms(i, i + _mapWidth, 'n');
				} else {
					_connectRooms(i, i + 1, 'e');
				}
			}
		}
	}

	// Create the reciprocal connections between the two rooms identified
	// by their numbers (first two args) in the direction given by the
	// third arg.  Direction is from the first room to the second.
	_connectRooms(n0, n1, dir) {
		local rm0, rm1;

		// Sanity check our arguments.
		if((rm0 = _getRoom(n0)) == nil) {
			_error('Failed to get room number <<toString(n0)>>');
			return;
		}
		if((rm1 = _getRoom(n1)) == nil) {
			_error('Failed to get room number <<toString(n1)>>');
			return;
		}

		switch(dir) {
			case 'n':
				rm0.north = rm1;
				rm1.south = rm0;
				break;
			case 's':
				rm0.south = rm1;
				rm1.north = rm0;
				break;
			case 'e':
				rm0.east = rm1;
				rm1.west = rm0;
				break;
			case 'w':
				rm0.west = rm1;
				rm1.east = rm0;
				break;
			default:
				_error('Got bogus direction <<dir>>');
				break;
		}
	}
;

#endif // ROUTE_TABLE_TESTS
