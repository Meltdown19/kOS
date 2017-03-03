// Rendezvous script
//@Author : Meltdown
// v 0.2
// Still troublesome routine to rendezvous with another craft. Currently working only for orbits with an e << 0.1

//a function that takes a longitude and returns an angle.
function fastdeg {
Parameter long.
return Mod(long + 360, 360).
}
// evaluates the radient for a given degree.
function fastrad {
parameter deg.
return ( ((2*constant:pi)/360) * deg).
}
//evaluates the angular difference between two objects in respect to the object they are orbiting
function targetangle {
Parameter Object.
Return mod((fastdeg(object:longitude) - fastdeg(ship:Longitude) +360)).
}
//returns the semimajor axis of a homanns transferorbit.
function Hohtransmajaxis {
Parameter object.
return ((orbit:semimajoraxis+object:orbit:semimajoraxis) / 2).
}
//Evaluates the waitingtime for the orbits of both ships
function Hohtrans_time {
Parameter object.
local bodyMass is Ship:Obt:body:Mass.
set TOF to constant:pi*sqrt(Hohtransmajoraxis(object)^3/body:mu).  //Time of Flight of the transferorbit
//gets the mean anomaly speed in radients
//is this correct??
function mean_anom {
	parameter object.
	return sqrt(body:mu / object:orbit:semimajoraxis^3).
}
set lead_ang to mean_anom(object) * TOF.
// Phase angle between burn start and leading object. 
set phi_final to constant:pi - lead_ang.
// initial phase angle between two objects.
set phi_start to fastrad(targetangle(object)).
local wait_until_burn is ( (phi_final-phi_start) / (lead_ang(object) - lead_angle(ship)) ).
return wait_until_burn.
}
function burn_seconds{
	parameter dv.
	local F is ship:availablethrust.
	local mass is Ship:mass.
	local g is 9.81.
	local a is F/mass.
	local Englist is list().
	list engines in englist.
	local isp is 0.
	for eng in englist {
		if eng:vips > 0 {
			set isp to eng:visp.
		}
	}
	return (g*isp*mass/F)*(1-constant:e^(-dv/(g*isp)) ).
}
function ullage {
	Parameter theEngine.
	local propStat is theEngine:GetModule("ModuleEnginesRF"):GetField("propellantStatus").
	if propStat <> "Very Stable" { 
			return false.
		}
		else {
			return true.
		}
}
function Hohmann_dV {
	Parameter desiredAltitude.
	set mu to ship:orbit:body:mu.
	set r1 to Ship:obt:semimajoraxis.
	set r2 to desiredAltitude + Ship:OBT:Body:Radius.
	set v1 to sqrt (mu / r1) * sqrt ( 2* r2) / ((r1 + r2 ) -1 ).
	set v2 to sqrt (mu / r2) * (1- sqrt((2*r1) / (r1 + r2))).
	return List(v1,v2).
}

{
global rendezvous is lex (
"sequence", list(
	"Hohmann Transfer Nodes", create_nodes@,
	"Rendezvous", rendezvous_hold@,
	"Ullage", ullaging@,
	"prograde burn", fire_ze_engines@,
	"appraching next node", coasting_to@,
	"Ullage", ullaging@,
	"Circularization", circularization@,
	"Final approach", approach@),
	"events", lex()	
	).
function create_nodes {
	set waitingtime to Hohtrans_time(target).
	local dv_needed is Hohmann_dv(target:orbit:periapsis).  //is a list
	set burntime to burn_seconds(dv_needed[0]).
	set nextburntime to burn_seconds(dv_needed[1]).
	set Hohnode1 to node(time:seconds+waitingtime, 0, 0, burntime).
	set Hohnode2 to node(time:seconds+waitingtime+TOF, 0, 0, nextburntime).
	add Hohnode1.
	mission["next"]().
}
function rendezvous_hold {
	lock steering to nextnode.
	Print "Waiting for " + waitingtime + " seconds until in Position." at(0,1).
	set naow is time:seconds.
	set wait_for_burn is naow - burntime /2 + waitingtime.
	Print round((wait_for_burn - time:seconds),1) + " seconds remaining." at (0,3).
	If wait_for_burn - 4 <= time:seconds {
		mission["next"]().
	}
}
function ullaging {
	Print "Ullaging the main engine." at (0,3).
	rcs on.
	list engines in englist.
	set engullage to englist[0].
	if ullage(engullage) = false {
		set ship:control:fore to 1.
		}
	if ullage(engullage) {
		RCS off.
		set ship:control:fore to 0.	
		mission["next"]().
	} 
}
//just a placeholder for a better burning method
function fire_zeh_engines {
		set throttle to 1.
		If 	hohnode1:deltav:mag <= 0 {
			set throttle to 0.
			remove Hohnode1.
			add Hohnode2.
			lock steering to nextnode.
			mission["next"]().
		}
}
function coasting_to{
	Print "transferring to new Apoapsis, firing Engines in : "+ (apoapsis:eta - nextburntime / 2) + " seconds ..." at(0,5).
	if apoapsis:eta - (nextburntime / 2) -4 <= 0 {
		mission["next"]().
	}
}
//just a placeholder for a better circularizationroutine
function circularization {
	set throttle to 1.
	If hohnode2:deltav:mag <= 0 {
		set throttle to 0.
		unlock steering.
		remove hohnode2.
		mission["next"]().
	}
}
function approach
mission["terminate"]().
}
