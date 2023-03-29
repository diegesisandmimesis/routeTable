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

// An anonymous preinit object to add a reminder not to release code compiled
// with the ROUTE_TABLE_LINT flag.
PreinitObject
	execute() {
		aioSay('\n####################\n');
		aioSay('\nWARNING:  COMPILED WITH THE ROUTE_TABLE_LINT FLAG\n');
		aioSay('\n####################\n');
	}
;

class RouteTableLintZoneInfo: object
	reachable = nil
	empty = nil
	orphanList = nil
;

// Validator/analyzer for route tables.
routeTableLint: RouteTableObject
	svc = 'routeTableLint'

	_showInfo = nil
	_showWarnings = true

	_ignoreList = nil
	_routeTableInfo = perInstance(new LookupTable())

	_clearInfo() {
		_routeTableInfo.keysToList().forEach(function(o) {
			_routeTableInfo.removeElement(o);
		});
	}

	_getZoneInfo(id) {
		if(_routeTableInfo[id] == nil)
			_routeTableInfo[id] = new RouteTableLintZoneInfo();
		
		return(_routeTableInfo[id]);
	}

	setIgnoreList(l) { _ignoreList = l; }

	// Returns boolean true if the value is in the ignore list, nil
	// otherwise.
	checkIgnored(v) {
		if(_ignoreList == nil) return(nil);
		return(_ignoreList.indexOf(v) != nil);
	}

	runTests() {
		scanZones();
		output();
	}

	output() {
		_outputGlobal();
		_outputZones();
	}

	_getActor() { return(routeTableRoomRouter.getRouteTableActor()); }

	_getStartingRoom() {
		local a;

		if((a = _getActor()) == nil)
			return(nil);

		return(a.location);
	}
	
	_getStartingZone() {
		local rm;

		if((rm = _getStartingRoom()) == nil)
			return(nil);

		return(rm.routeTableZone);
	}

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

	_outputZones() {
		_routeTableInfo.forEachAssoc(function(k, v) {
			_outputUnreachableZones(k, v);
			_outputEmptyZones(k, v);
			_outputOrphans(k, v);
		});
	}

	_outputUnreachableZones(k, v) {
		if(v.reachable == nil)
			_warning('zone <q><<k>></q>: not reachable');
	}

	_outputEmptyZones(k, v) {
		if(v.empty == true)
			_warning('zone <q><<k>></q>: no vertices');
	}

	_outputOrphans(k, v) {
		local l, rm;

		if((l = v.orphanList()) == nil) {
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

	scanZones() {
		local zoneList, r;

		zoneList = routeTableRoomRouter.getVertices();
		zoneList.forEachAssoc(function(k, v) {
			r = _getZoneInfo(k);

			r.reachable = _checkZoneReachable(k, v);
			r.empty = _checkForEmptyZone(k, v);
			r.orphanList = _findOrphansInZone(k, v);
		});
	}

	_checkZoneReachable(id, zone) {
		local l, z;

		if((z = _getStartingZone()) == nil)
			return(nil);

		if(z == id)
			return(true);

		l = routeTableRoomRouter.getRouteTableZonePath(z, id);

		return(l != nil);
	}

	_checkForEmptyZone(id, zone) {
		local l;

		if((zone == nil) || !zone.ofKind(RouteTableZone))
			return(nil);

		zone = zone.getData();

		if((l = zone.getVertices()) == nil)
			return(true);

		return(l.length == 0);
	}

	// Find all the vertices not connected to any other vertex.
	_findOrphansInZone(id, zone) {
		local l, r;

		if((zone == nil) || !zone.ofKind(RouteTableZone))
			return(nil);

		zone = zone.getData();

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

	_checkOrphanReachability(id, v) {
		local l;

		if((l = routeTableRoomRouter.findPath(_getStartingRoom(),
			v.getData())) == nil)
			return(nil);

		return(l[l.length] == v.getData());
	}

	_info(msg) { if(_showInfo) aioSay('\nINFO: <<msg>>\n '); }
	_warning(msg) { if(_showWarnings) aioSay('\nWARNING: <<msg>>\n '); }
	_error(msg) { aioSay('\nERROR: <<msg>>\n '); }
;

#endif // ROUTE_TABLE_LINT
