set ship:control:pilotmainthrottle to 0.
Function NOTIFY {
Parameter Msg.
Parameter t.
HUDTEXT (msg, t, 2, 50, WHITE, FALSE).
}
function Pitchangle {
return Vang(Ship:up:vector,Ship:facing:vector).
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
function eta_to_ta {
	parameter orbit_in,ta_deg.
	local targettime is time_pe_to_ta(orbit_in,ta_deg).
	local curTime is time_pe_to_ta(orbit_in, orbit_in:trueanomaly).
	local ta is targettime - curtime.
	if ta < 0 { 
		set ta to ta + orbit_in:period.
	}
	return ta.
}
function time_pe_to_ta {
	Parameter orbit_in,
	ta_deg.
	local ecc is orbit_in:eccentricity.
	local sma is orbit_in:semimajoraxis.
	local e_anom_deg is arctan2(sqrt(1-ecc^2)*sin(ta_deg), ecc + cos(ta_deg)).
	local e_anom_rad is e_anom_deg *constant:pi/180.
	local m_anom_rad is e_anom_rad - ecc*sin(e_anom_deg).
	return m_anom_rad / sqrt(orbit_in:body:mu / sma^3). 
}
function orbit_normal {
	Parameter orbit_in.
	return VCRS (orbit_in:body:position - orbit_in:position , orbit_in:velocity:orbit) :Normalized.
}
function find_ascending_ta {
	parameter orbit_1, orbit_2.
	local normal_1 is orbit_normal(orbit_1).
	local normal_2 is orbit_normal(orbit_2).
	local vec_body_to_node is VCRS(normal_1,normal_2).
	local pos_1_body_rel is orbit_1:position - orbit_1:body:position.
	local ta_ahead is vang(vec_body_to_node, pos_1_body_rel).
	local sign_check_vec is VCRS(vec_body_to_node, pos_1_body_rel).
	if Vdot(normal_1,sign_check_vec) < 0 {
		set ta_ahead to 360 - ta_ahead.
	}
	return mod(orbit_1:trueanomaly + ta_ahead, 360).
}
function AN_Node_finder {
	Parameter vessel_1, orbit_2.
	local normal_1 is orbit_normal(vessel_1:orbit).
	local normal_2 is orbit_normal(orbit_2).
	local node_ta is find_ascending_ta(vessel_1:orbit, orbit_2).
	if node_ta < 90 or node_ta > 270 {
		set node_ta to mod(node_ta + 180,360).
	}
	local burn_eta is eta_to_ta(vessel_1:orbit, node_ta).
	return (time:Seconds + burn_eta).
}
function orbit_altitude_at_ta {
Parameter
	orbit_in,
	true_anom.  //in degrees.
local sma is orbit_in:semimajoraxis.
local ecc is orbit_in:eccentricity.
local r is sma*(1-ecc^2)/(1+ecc*cos(true_anom)).
				
return r - orbit_in:body:radius.
}
function orbit_cross_ta {
parameter
	orbit_1,
	orbit_2, 
	max_epsilon, 
	min_epsilon.
	
	local pe_ta_off is ta_offset(orbit_1,orbit_2).
	local incr is max_epsilon.
	local prev_diff is 0.
	local start_ta is orbit_1:trueanomaly.
	local ta is start_ta.
	
	until ta > start_ta + 360 or abs(incr) < min_epsilon {
		local diff is orbit_altitude_at_ta(orbit_1, ta) -
							orbit_altitude_at_ta(orbit_2, pe_ta_off + ta).
		if diff * prev_diff < 0 {
			set incr to -incr/10.
		}
		set prev_diff to diff.
		set ta to ta + incr.
	}
	if ta > start_ta+360 {
		return -1.
	}
	else { mod(ta,360).
	}
}
function ta_offset {
parameter orbit_1, orbit_2.
local pe_lng_1 is orbit_1:argumentofperiapsis + orbit_1:longitudeofascendingnode.
local pe_lng_2 is orbit_2:argumentofperiapsis + orbit_2:longitudeofascendingnode.
return pe_lng_1 - pe_lng_2.
}
function mnvr_t {
Parameter dV.
list engines in leng_mnvr.
local i is 0.
local foo is leng_mnvr:length -1. 
local f is leng_mnvr[foo]:Maxthrust *1000.
local m is Ship:mass * 1000.
local e is constant():e.
local p is leng_mnvr[foo]:visp.
local g is 9.80665.
local result is (g * m * p * (1- e ^(-dV / (g * p))) / f).
for eng in leng_mnvr {
	if eng:name = leng_mnvr[foo]:name {
		set i to i + 1.
	}
}
return result / i.
}
function ulli {
list engines in leng_ulli.
local foo is leng_ulli:length-1.
local prop is leng_ulli[foo]:GetModule("ModuleEnginesRF"):GetField("propellant").
if prop <> "Very Stable" { 
		return false.
	}
	else {
		return true.
	}
}
function fast_finder {
parameter 
m, param, n is 0.
set rmode to 42.
set nextnode:prograde to nextnode:prograde + m.
if orbit_cross_ta(nextnode:orbit, moon:obt,12,2) < 0 {
	fast_finder(m,param,n+m).
}
else{
set rmode to param.
set nextnode:prograde to nextnode:prograde - m.
}
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
function dFair {
	when ship:altitude > 0.55 * Body:Atm:Height then {
		for module in Ship:Modulesnamed("ModuleProceduralFairing") { // Stock and KW Fairings
			module:doevent("deploy").
		}
		for module in Ship:Modulesnamed("ProceduralFairingDecoupler") { // Procedural Fairings
			module:doevent("jettison").
		}
		if ship:altitude > 0.55 * body:atm:height {
			preserve.
		}	
	}
}
function pan_on {
	when ship:altitude > 0.9 * Body:Atm:Height then{
		Panels ON.
	if ship:altitude > 0.9 * body:atm:height {
		preserve.
	}
	}
}
function bottom_dist_from_CoM {
	local biggest is 0.
	local aft_unit is (-1)*ship:facing:forevector.
	for p in ship:parts {
		local aft_dist is vdot(p:position - ship:position,aft_unit).
		if aft_dist > biggest {
			set biggest to aft_dist.
		}
	}
	return biggest.
}
function noneg_vec {
	if ship:verticalspeed < -0.1 {
		return (-1)*ship:velocity:surface.
	}
	else {
		return up:vector.
	}
}
