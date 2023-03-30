#charset "us-ascii"
//
// routeTableDebug.t
//
// Debug methods.  Well, method.  We do things this way so that we can
// pepper the code with debugging output, and then when it's compiled for
// release without -D __DEBUG_ROUTE_TABLE all of the _debug statements
// become NOPs.
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

#ifdef __DEBUG_ROUTE_TABLE

// We put the debugging statement on a generic "object" class, so we
// can use it as a base/mixin for more or less everything.  It uses a
// svc property, which if defined is just a tag that gets prepended to the
// debugging output, for ease of identifying what generated the output.
modify RouteTableObject
	_debug(msg?) { aioSay('\n<<(svc ? '<<svc>>: ' : '')>><<msg>>\n '); }
;

#endif // __DEBUG_ROUTE_TABLE
