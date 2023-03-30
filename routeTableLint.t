#charset "us-ascii"
//
// routeTableLint.t
//
// A basic linter for route tables.
//
#include <adv3.h>
#include <en_us.h>
#include <date.h>
#include <bignum.h>

#include "routeTable.h"

#ifdef ROUTE_TABLE_LINT

// An anonymous preinit/init object to add a reminder not to release code
// compiled with the ROUTE_TABLE_LINT flag.
// We do a little preprocessor dance here so that we're only output once at
// startup for debugging builds, but we're output both at compile time and
// at startup for non-debugging builds.
#ifdef __DEBUG
PreinitObject
#else // __DEBUG
PreinitObject, InitObject
#endif //__DEBUG
	execute() {
		aioSay('\n####################\n');
		aioSay('\nWARNING:  COMPILED WITH THE ROUTE_TABLE_LINT FLAG\n');
		aioSay('\n          Should not be used for a release\n');
		aioSay('\n####################\n');
	}
;

// Little data structure for keeping track of the linter's notes.
class RouteTableLintZoneInfo: object
	reachable = nil
	empty = nil
	orphanList = nil
	subgraphs = nil
;

// Validator/analyzer for route tables.
routeTableLint: RouteTableObject
	svc = 'routeTableLint'

	// Output verbosity flags
	_showInfo = nil			// by default, no "info" messages
	_showWarnings = true		// by default, print warnings

	_ignoreList = nil		// list of rooms/vertices to not
					// report on

	// LookupTable that'll hold what we figure out as we go.  This
	// will be a hash of RouteTableLintZoneInfo instances keyed by
	// zone ID.
	_routeTableInfo = perInstance(new LookupTable())

	// Clear everything in our info table.
	_clearInfo() {
		_routeTableInfo.keysToList().forEach(function(o) {
			_routeTableInfo.removeElement(o);
		});
	}

	// Get everything we recorded about the given zone.
	_getZoneInfo(id) {
		if(_routeTableInfo[id] == nil)
			_routeTableInfo[id] = new RouteTableLintZoneInfo();
		
		return(_routeTableInfo[id]);
	}

	// Set the ignore list.
	setIgnoreList(l) { _ignoreList = l; }

	// Returns boolean true if the value is in the ignore list, nil
	// otherwise.
	checkIgnored(v) {
		if(_ignoreList == nil) return(nil);
		return(_ignoreList.indexOf(v) != nil);
	}

	// General entry point.  We run all of our tests.
	runTests() {
		// Collect information.
		scanZones();

		// Report on it.
		output();
	}

	// General output method.  Logs everything we know about.
	output() {
		// General stuff not specific to a single zone.
		_outputGlobal();

		// Stuff specific to individual zones.
		_outputZones();
	}

	// Figure out what actor to use for reachability testing.  We
	// just glom onto the roomRouter's logic for this.
	_getActor() { return(roomRouter.getRouteTableActor()); }

	// Figure out what the starting room, if any, is.  This is used
	// for reachability testing--we assume that wherever the player
	// starts out wants to be connected to everything else.
	// This isn't universally true (the game can have multiple settings
	// that the player gets teleported between during chapter breaks,
	// for example) but we've got to compute reachability FROM somewhere,
	// so this is what we do.
	_getStartingRoom() {
		local a;

		if((a = _getActor()) == nil)
			return(nil);

		return(a.location);
	}
	
	// Returns the zone ID of the the player's starting location.
	_getStartingZone() {
		local rm;

		if((rm = _getStartingRoom()) == nil)
			return(nil);

		return(rm.routeTableZone);
	}

	// General observations.  This is for stuff not specific to individual
	// zones.
	_outputGlobal() {
		if(_getActor() == nil) {
			_error('can\'t test reachability: no player defined');
		} else if(_getStartingRoom() == nil) {
			_error('can\'t test reachability: no player
				location defined');
		} else if(_getStartingZone() == nil) {
			_error('can\'t test reachability: no zone defined for
				player location');
		}
	}

	// Go through the zone list in the info table and output everything
	// we noticed about each zone.
	_outputZones() {
		_routeTableInfo.forEachAssoc(function(k, v) {
			_outputZone(k, v);
		});
	}

	// Output info on a single zone.  k is the zone ID, v is the
	// zone's entry in the info table.
	_outputZone(k, v) {
		_outputSubgraphs(k, v);
		_outputUnreachableZones(k, v);
		_outputEmptyZones(k, v);
		_outputOrphans(k, v);
	}

	// Output info about subgraphs.  In order for pathfinding to
	// work all the vertices in a zone need to be contiguous, so if
	// there are disconnected subgraphs there be troubles ahead.
	// Here we just complain, but the module can fix this via
	// roomRouter.fixSubgraphs() but that's not part of the linter's remit.
	_outputSubgraphs(k, v) {
		local i;

		// No subgraphs means an empty zone (which merits a warning,
		// but not here), and a length of 1 means all vertices are
		// contiguous (which is what we want).  If either of those
		// applies, we're done here.
		if((v.subgraphs == nil) || (v.subgraphs.length < 2))
			return;

		// Multiple disconnected subgraphs breaks pathfinding, so
		// this is an error, not a warning.
		_error('zone <q><<k>></q>: contains
			<<toString(v.subgraphs.length)>> disconnected
			subgraphs');

		// Output the vertices in each subgraph
		for(i = 1; i <= v.subgraphs.length; i++) {
			_error('zone <q><<k>></q>: subgraph <<toString(i)>> =
				<<toString(v.subgraphs[i])>>');
		}
	}

	// Complain if we can't reach this zone from the starting location
	_outputUnreachableZones(k, v) {
		if(v.reachable == nil)
			_warning('zone <q><<k>></q>: not reachable');
	}

	// Complain if the zone doesn't contain anything.
	_outputEmptyZones(k, v) {
		if(v.empty == true)
			_warning('zone <q><<k>></q>: no vertices');
	}

	// Report "orphans":  rooms that aren't connected to anything.
	// This is a warning and not an error because it might be intentional:
	// there might be a jail cell that the player enters and exits only
	// via teleportation.
	_outputOrphans(k, v) {
		local l, rm;

		if((l = v.orphanList) == nil) {
			_warning('zone <q><<k>></q>:
				orphan list is nil ');
			return;
		}
		l.forEach(function(o) {
			rm = o.getData();
			_warning('zone <q><<k>></q>:
				vertex <<o.id>> <<((rm != nil)
				? '<q>' + rm.roomName + '</q>'
				: '')>> orphaned');
		});
	}

	// Main info-gathering loop.
	scanZones() {
		local r, z;

		// Iterate through every vertex in the room router's
		// main route table.  This will be a list of zone IDs.
		roomRouter.vertexIDList().forEach(function(zID) {
			// Get the zone info entry for this zone.
			r = _getZoneInfo(zID);

			// Get the zone itself
			z = roomRouter.getZone(zID);

			// Update the various info properties.
			r.reachable = _checkZoneReachable(zID, z);
			r.empty = _checkForEmptyZone(zID, z);
			r.orphanList = _findOrphansInZone(zID, z);
			r.subgraphs = _findSubgraphsInZone(zID, z);
		});
	}

	// See if the given zone is reachable from the starting zone.
	_checkZoneReachable(id, zone) {
		local l, z;

		if((z = _getStartingZone()) == nil)
			return(nil);

		if(z == id)
			return(true);

		// The "zone path" is just the list of zones you have to
		// go through in order to get from a source zone to a
		// destination zone.  This ISN'T a list of the individual rooms
		// that such a trip would involve.
		l = roomRouter.getZonePath(z, id);

		return(l != nil);
	}

	// Check the total number of vertices in the zone.  We only care
	// if the count is zero.  This shouldn't happen in general (because
	// we generate the zone list by looking at the room declarations),
	// but it might if we got fancy tweaking things "by hand".
	_checkForEmptyZone(id, zone) {
		local l;

		if((zone == nil) || !zone.ofKind(RouteTableZone))
			return(nil);

		if((l = zone.getVertices()) == nil)
			return(true);

		return(l.length == 0);
	}

	// Find all the vertices not connected to any other vertex.
	_findOrphansInZone(id, zone) {
		local l, r;

		if((zone == nil) || !zone.ofKind(RouteTableZone))
			return(nil);

		if((l = zone.getVertices()) == nil)
			return(nil);

		r = new Vector();

		l.forEachAssoc(function(k, v) {
			if(checkIgnored(k) || checkIgnored(v)
				|| checkIgnored(v.getData()))
				return;
			if(v.getDegree() != 0)
				return;
			if(_checkOrphanReachability(k, v) == true)
				return;
			r.append(v);
		});

		return(r);
	}

	// Double-check an "orphan".  We do this because the basic check
	// above relies on edges in the graph of the zone.  This alone
	// would return a false positive for a zone containing a single
	// room that's connected to a room in another zone.
	// So here we check to see if the orphan can be reached from
	// the start room.
	_checkOrphanReachability(id, v) {
		local l;

		if((l = roomRouter.findPath(_getStartingRoom(),
			v.getData())) == nil)
			return(nil);

		return(l[l.length] == v.getData());
	}

	_findSubgraphsInZone(id, zone) {
		local l;

		// Sanity check the zone argument.
		if((zone == nil) || !zone.ofKind(RouteTableZone))
			return(nil);

		// Make sure there's at least one subgraphs.  If not,
		// the zone is empty, but that's not our problem.
		if((l = zone.generateSubgraphs()) == nil)
			return(nil);

		// If there's exactly one subgraphs, then we're cool.
		// That just means that all the vertices in the zone are
		// contiguous, which is what we need.
		if(l.length < 2)
			return(nil);

		// Here our troubles begin.  We have multiple subgraphs,
		// which means pathfinding in the zone will be broken.
		// All we do at the moment is return the subgraphs list,
		// and it'll be up to the reporting stuff to figure it out.

		return(l);
	}

	// Logging methods for various severity levels.  Errors are always
	// output, everything else can be toggled.
	_info(msg) { if(_showInfo) aioSay('\nINFO: <<msg>>\n '); }
	_warning(msg) { if(_showWarnings) aioSay('\nWARNING: <<msg>>\n '); }
	_error(msg) { aioSay('\nERROR: <<msg>>\n '); }
;

#endif // ROUTE_TABLE_LINT
