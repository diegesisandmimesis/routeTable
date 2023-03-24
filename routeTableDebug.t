#charset "us-ascii"
//
// routeTableDebug.t
//
#include <adv3.h>
#include <en_us.h>

#include "routeTable.h"

#ifdef __DEBUG_ROUTE_TABLE

modify RouteTableObject
	_debug(msg?) { aioSay('\n\t<<(svc ? '<<svc>>: ' : '')>><<msg>>\n '); }
;

#endif // __DEBUG_ROUTE_TABLE
