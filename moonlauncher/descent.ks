{
set ship:control:pilotmainthrottle to 0.
clearscreen.
set highest_point to 1.35e4. //the highest point on the target body.
set aim_up_pid to PID_init(1,0.25,0.1,-90,90).
set curt to 0.
set curs to ship:facing:vector.
lock throttle to curt.
lock steering to curs.
global descent is lex(
	"sequence", list (
	"lower pe", lower_pe@,
	"warp to", let_warp@,
	"burn for low pe", lo_pe_burn@,
	"deorbit node", pdinode@,
	"wait cmd", pdiwait@,
	"powered descent injection", pdi@,
	"ullage", sb_ullage@,
	"suicide-burn", suicide_burn@,
	"landing itself", landing@
	), 
	"events", Lex()
	).
function lower_pe{
parameter mission.
	warpto(eta:apoapsis + time:seconds - 30).
	mission["next"]().
}
function let_warp{
Parameter mission.
	set curs to retrograde.
	if vang(ship:facing:vector,retrograde:vector) < 2	{
		wait 5.
		mission["next"]().
	}
}
function lo_pe_burn {
Parameter mission.
	set curs to retrograde.
	if ulli() = false and vang(ship:facing:vector,retrograde:vector) < 2{
		rcs on.
		set ship:control:fore to 1.
	}
	if curt <> 0.15 and ulli() and vang(ship:facing:vector,retrograde:vector) < 2{
		rcs off.
		set ship:control:fore to 0.
		set curt to 0.15.
	}
	if periapsis < highest_point {
		set curt to 0.
		wait 2.
		mission["next"]().
	}
}
function pdinode {
parameter mission.
	if not hasnode{
		add node(time:seconds + eta:periapsis -20,0,0,0).
		warpto(nextnode:eta + time:seconds).
	} else {
		mission["next"]().
	}
}
function pdiwait {
parameter mission.
set curs to retrograde.
when eta:apoapsis > eta:periapsis then{
	set orig_vel to ship:velocity:surface.
	set aim_vec to (-1)*orig_vel.
}
if eta:apoapsis < eta:periapsis {
	if not ulli() {
		rcs on.
		set ship:control:fore to 1.
	}
	if ulli() {
		rcs off.
		lock curs to aim_vec.
		set ship:control:fore to 0.
		set curt to 1.
		set pdi_stop to 2.
		set landing_vel to 2.
		lock aim_up_accel to PID_Seek(aim_up_pid, 0, ship:verticalspeed).
		mission["next"]().
	}
}
}
function pdi {
Parameter mission.
	set aim_up_angle to arcsin(aim_up_accel / (ship:availablethrust / ship:mass) ).
	set side_vec to VCRS(ship:up:vector, ship:velocity:surface).
	set aim_vec to angleaxis(aim_up_angle,side_vec) * ((-1)*ship:velocity:surface).
	if ship:availablethrust = 0 { stage. }
	if ship:velocity:surface:mag < pdi_stop or vdot(ship:velocity:surface, orig_vel) < 0 {
		set curt to 0.
		legs on.
		set safety_dist to bottom_dist_from_CoM() +1. //some space is needed for the landing legs.
		lock curs to noneg_vec().
		set rad to ship:body:radius.
		set mu to ship:body:mu.
		set startmass to ship:mass.
		lock grav to (mu/(rad+ship:altitude)^2).
		lock surv_grav to (mu/(rad+(ship:altitude-alt:radar))^2).
		lock leftoverthrust to ship:availablethrust*0.97 - ((surv_grav+grav)/2)*ship:mass.
		lock stop_dist to ship:velocity:surface:mag^2 / (2*(max(0.001,leftoverthrust)/ship:mass)).
		mission["next"]().
	}
}
function sb_ullage {
Parameter mission.
	if ulli() = false and alt:radar - 125 < (stop_dist + safety_dist) {
		rcs on.
		set ship:control:fore to 1.
	}
	if ulli() and alt:radar > (stop_dist+ safety_dist) {
		rcs off.
		set ship:control:fore to 0.
	}
	if alt:radar < (stop_dist+ safety_dist) {
		lock fudgeratio to (stop_dist+safety_dist) / alt:radar.
		lock curt to ship:mass / startmass *fudgeratio .
		mission["next"]().
	}
} 
function suicide_burn {
parameter mission.
	set landing_vel to 2.
	if ship:verticalspeed > -landing_vel {
		set descent_pid to PID_init(0.1, 0.01, 0.05, 0, 1).
		PID_seek(descent_pid, -landing_Vel, ship:verticalspeed).
		lock throttle to PID_seek(descent_pid, -landing_Vel, ship:verticalspeed).
		mission["next"]().
	}
}
function landing {
Parameter mission.
	if ship:status = "LANDED" or ship:status = "Splashed"{
		print ship:status.	
		unlock steering.
		unlock throttle.
		brakes on.
		mission["terminate"]().
	}
}
}
