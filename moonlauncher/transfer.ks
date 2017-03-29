{
clearscreen.
set rmode to 1.
set curt to 0.
set curs to ship:facing:vector.
lock throttle to curt.
lock steering to curs.
global transfer is lex(
	"sequence", list (
	"AN or DN", AN_DN@,
	"match orbit", orbit_match_finder@,
	"encounter", encounter@,
	"adj Pe pwise", Adjusting_Pe_periodwise@,
	"adj Pe dvwise", adjusting_pe_dvwise@,
	"Warpnode", warp_to_node@,
	"Exec burn", exec_burn@,
	"mid corr", mid_course@,
	"warp soi", warp_to_transition@,
	"crt node", circ_node_create@,
	"ftune node", circ_node@,
	"Warpnode", warp_to_node@,
	"Exec burn", exec_burn@,
	"close", close@
	), 
	"events", Lex()
	).
	
Function AN_DN  {
Parameter mission.
	add NODE(AN_Node_finder(ship,Moon:orbit), 0, 0, 2600).
	mission["next"]().
}
function orbit_match_finder {
Parameter mission.
if rmode = 1 {
fast_finder(100,2).
}
if rmode = 2 {
fast_finder(10,3).
}
if rmode = 3 {
fast_finder(1,4).
}
if rmode = 4 {
	set rmode to 1.
	mission["next"]().
	}
}
function encounter {
Parameter mission.
	if nextnode:orbit:transition <> "Encounter" {
		set nextnode:eta to nextnode:eta + ship:orbit:period.
	}
	if nextnode:orbit:transition = "Encounter" {
		if nextnode:eta <= target:orbit:period / 2 {
			mission["next"]().
		}
		else {
			set mnv_time_acc to time:seconds + mod(nextnode:eta,ship:orbit:period) + ship:orbit:period/2.
			remove nextnode.
			add node(mnv_time_acc,0,0,2600).
			mission["switch_to"]("match orbit").	
		}
	}
}
function Adjusting_Pe_periodwise {
parameter mission.
	if nextnode:orbit:nextpatch:periapsis > 1.2e5 {
		set nextnode:eta to nextnode:eta + ship:orbit:period.
	}
	else {
		set nextnode:eta to nextnode:eta - ship:orbit:period.
		mission["next"]().
	}
}
function adjusting_pe_dvwise {
Parameter mission.
	if nextnode:orbit:nextpatch:periapsis > 1.2e5{
		set nextnode:prograde to nextnode:prograde + 0.05.
	}
	else {
	set nextnode:prograde to nextnode:prograde - 0.05.
		mission["next"]().
	}
}
function warp_to_node { 
Parameter mission.
	if kuniverse:timewarp:warp = 0 and nextnode:eta > 300 and kuniverse:timewarp:issettled {
		warpto(time:seconds +(nextnode:eta - (mnvr_t(nextnode:deltav:mag / 2) + 25 )) ).
	}
	if nextnode:eta < (mnvr_t(nextnode:deltav:mag / 2 ) + 22) and kuniverse:timewarp:issettled {
		set curs to nextnode.
		wait 20. // if vang(ship:facing:vector, nextnode:deltav:vector < 2) {}
		rcs on.
		mission["next"]().
	}
}
function exec_burn {
Parameter mission.
	if nextnode:eta <= (mnvr_t(nextnode:deltav:mag / 2) + 5) and nextnode:eta >= mnvr_t(nextnode:deltav:mag / 2 ) and nextnode:deltav:mag > 35 {
		if ulli() = false {
			set ship:control:fore to 1.
		}
	}
	if ulli() = true and nextnode:eta <= (mnvr_t(nextnode:deltav:mag / 2 + 1 )) and nextnode:deltav:mag > 35 {
		set ship:control:fore to 0.
		if curt <> 1 {
			set curt to 1.	
		}
	}
	if nextnode:deltav:mag > 5 and nextnode:deltav:mag < 35 { //mnvr_t(nextnode:deltav:mag) < 1.5 and 
		if curt <> 0.15 {
			set curt to 0.15.	
		}
	}
	if nextnode:deltaV:mag <= 5 and nextnode:deltav:mag > 1 {
		if curt <> 0 {
			set curt to 0.	
		}
		set curs to ship:facing:vector.
		set ship:control:fore to 1.
	}
	if nextnode:deltav:mag < 0.4 and vang(nextnode:deltav, ship:facing:vector) > 90 {
		remove nextnode.
		rcs off.
		set ship:control:fore to 0.
		wait 5.
		mission["next"]().
	}
}
function mid_course {
Parameter mission.
	if vang(ship:facing:vector, prograde:vector) > 0.1 {
		set curs to prograde.
	}
	if orbit:nextpatch:periapsis < 4e4 {
		rcs on.
		list engines in leng_mid.
		FOR eng IN leng_mid {
			if eng:thrustlimit > 0.1  {
				set eng:thrustlimit to 0.1.
			}
		}
		set ship:control:fore to -1.
	}
	if orbit:nextpatch:periapsis > 7e4 {
		RCS on.
		list engines in leng_mid2.
		FOR eng IN leng_mid2 {
			if eng:thrustlimit > 0.1  {
				set eng:thrustlimit to 0.1.
			}
		}
		set ship:control:fore to 1.
	}
	if orbit:nextpatch:periapsis < 7e4 and orbit:nextpatch:periapsis > 4e4{
		list engines in leng_mid3.
		FOR eng IN leng_mid3 {
			if eng:thrustlimit < 100  {
				set eng:thrustlimit to 100.
			}
		}
		RCS off.
		set ship:control:fore to 0.
		add node(time:seconds + eta:transition + 25,0,0,0).
		wait 0.
		mission["next"]().
	}
}
function warp_to_transition { 
Parameter mission.
	if kuniverse:timewarp:warp = 0 and nextnode:eta > 300 and kuniverse:timewarp:issettled {
		warpto(time:seconds +nextnode:eta ).
	}
	if nextnode:eta < 20 and kuniverse:timewarp:issettled {
		remove nextnode.
		wait 0.
		mission["next"]().
	}
}
function circ_node_create {
Parameter mission.
	add node(time:seconds + eta:periapsis, 0, 0, -200).
	wait 0.
	mission["next"]().
}
function circ_node {
Parameter mission.
	if nextnode:orbit:eccentricity > 0.01 {
		set nextnode:prograde to nextnode:prograde -1.
		set curs to retrograde.
	}
	else {
		wait 5.
		stage.
		mission["next"]().
	}
}
function close {
Parameter mission.
	mission["terminate"]().
}
}
