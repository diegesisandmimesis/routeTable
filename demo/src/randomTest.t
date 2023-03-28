#charset "us-ascii"
//
// randomTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// Non-interactive performance test comparing routeTable pathfinding and
// roomPathFinder.findPath() pathfinding performance.  This test generates
// a random 10x10 maze as the pathfinding test.
//
// It can be compiled via the included makefile with
//
//	# t3make -f randomTest.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>
#include <date.h>
#include <bignum.h>

// No version info; we're never interactive.
versionInfo: GameID;

modify routeTableRoomRouter
	execBeforeMe = [ randomTest ]
;

randomTest: PreinitObject
	test = nil

	execute() {
		test = new RouteTableRandomTest();
		test.preinit();
	}
;

me: Actor;

gameMain: GameMainDef
	initialPlayerChar = me

	newGame() {
		randomTest.test.runTest();
	}
;
