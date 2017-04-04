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
function do_staging {
	Lock steering to heading(compass_of_vel(ship:velocity:orbit),Pitchangle).
	wait 1.			
	stage.
	Lock steering to curs.
}
function get_active_eng {
	list engines in all_eng.
	local length is all_eng:length-1.
	if length = 0 { return all_eng.}
	else {
		from {local x is length.} until x = 0 step {set x to x-1.} do {
			if all_eng[x]:stage = stage:number {
				result:add(all_eng[x]).
			}
		}
		return result.
	}
}
function stagingfunc {
	When Periapsis < Body:Atm:Height then {
		set curr_active_engines to get_active_eng().
		for eng in curr_active_engines {		
			if eng:flameout {
				notify ("Engine Flameout, activating next stage.",2).
				do_staging().
				break.
			}
			local ign is eng:getmodule("ModuleEnginesRF"):Getfield("ignitions remaining").
			if not eng:ignition and not eng:flameout and ign = 0 {
				notify ("Engine malfunction, activating next stage.",2).
				do_staging().
				break.
			}
		}
		if Periapsis < Body:Atm:Height {
			Preserve.
		}
		wait 0.01.
	}
}
}
