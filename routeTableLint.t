#charset "us-ascii"
//
// routeTableLint.t
//
// A basic linter for route tables.
//
#include <adv3.h>
#include <en_us.h>

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

// Validator/analyzer for route tables.
routeTableLint: RouteTableObject
	svc = 'routeTableLint'
;

#endif // ROUTE_TABLE_LINT
