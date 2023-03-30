//
// routeTable.h
//

// Uncomment to enable debugging options.
//#define __DEBUG_ROUTE_TABLE

// Uncomment to enable test definitions.
//#define ROUTE_TABLE_TESTS

// Uncomment to enable the route table linter, which is a utility to
// analyze the route tables in your game.  This should not be enabled
// in released code
//#define ROUTE_TABLE_LINT

// Uncomment to prevent the module from automagically fixing
// subgraph problems in the default zone
//#define ROUTE_TABLE_NO_SUBGRAPH_FIX

// Dependency checking.
#include "simpleGraph.h"
#ifndef SIMPLE_GRAPH_H
#error "This module requires the simpleGraph module."
#error "https://github.com/diegesisandmimesis/simpleGraph"
#error "It should be in the same parent directory as this module.  So if"
#error "routeTable is in /home/user/tads/routeTable, then simpleGraph"
#error "should be in /home/user/tads/simpleGraph ."
#endif // SIMPLE_GRAPH_H

RouteTableZone template 'routeTableZoneID';

// Do not comment this out.  It's used for dependency checking.
#define ROUTE_TABLE_H
