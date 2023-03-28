#charset "us-ascii"
//
// routeTableObject.t
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

// Base class for all of our objects.  Just adds some debugging methods.
class RouteTableObject: object
	svc = nil

	_debug(msg?) {}
	_error(msg?) { aioSay('\n<<(svc ? '<<svc>>: ' : '')>><<msg>>\n '); }
;
