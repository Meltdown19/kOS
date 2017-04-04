set ship:control:pilotmainthrottle to 0.
Function NOTIFY {
Parameter Msg.
Parameter t.
HUDTEXT (msg, t, 2, 50, WHITE, FALSE).
}
function Pitchangle {
return Vang(Ship:up:vector,Ship:facing:vector).
}

function east_for {
Parameter ves.
return vcrs(ves:up:vector, ves:north:vector).
}
function compass_of_vel{
Parameter pointing. //ship:velocity:orbit or ship:velocity:surface
	local east is east_for(ship).
	local trig_x is vdot(ship:north:vector, pointing).
	local trig_y is vdot(east,pointing).

	local result is arctan2(trig_y,trig_x).
	if result < 0 {
		return 360 + result.
	} 
	else {
		return result.
	}
}
function orbit_normal {
    parameter orbit_in.
    return VCRS(orbit_in:body:position - orbit_in:position,
                orbit_in:velocity:orbit):normalized.
}
function swapYZ {
    parameter vec_in.
    return V(vec_in:X, vec_in:Z, vec_in:Y).
}
function swapped_orbit_normal {
    parameter orbit_in.
    return -swapYZ(orbit_normal(orbit_in)).
}
function relativeInc {
    parameter orbiter_a, orbiter_b.
    return abs(vang(swapped_orbit_normal(orbiter_a), swapped_orbit_normal(orbiter_b))).
}
function dFair {
	when ship:altitude > 0.55 * Body:Atm:Height then {
		for module in Ship:Modulesnamed("ModuleProceduralFairing") {
			module:doevent("deploy").
		}
		for module in Ship:Modulesnamed("ProceduralFairingDecoupler") {
			module:doevent("jettison").
		}
	}
}
