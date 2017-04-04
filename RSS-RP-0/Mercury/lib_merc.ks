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
function dvcalc {
	set prev_dv_sec to 0.
	set prev_dv_result to ship:mass.
	set dv_total to 0.
	when 1 > 0 then {
		set sec to time:seconds.
		set dv_burnt to (sec-prev_dv_sec)*(ship:availablethrust / ship:mass).
		if dv_burnt <= prev_dv_result*1.03 { 
			set dv_total to dv_total + dv_burnt.
			set sec_fraction to 1 / (sec - prev_dv_sec).
			set prev_dv_result to dv_burnt.
			set prev_dv_sec to sec.
			print "dV expended : " + round(sec_fraction*dv_burnt,2) + " m/s"+"         "at(0,5).
			print "dV total : " + round(dv_total,2) + " m/s"+"         "at(0,6).
			preserve.
		}
		else {
			set prev_dv_sec to sec.
			set prev_dv_result to dv_burnt.
			preserve.
		}
	}
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
