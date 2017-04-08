function act_eng {
Parameter s is stage:number.
	local res is list().
	list engines in all_eng.
	local length is all_eng:length-1.
	if length = 0 { return all_eng.}
	else {
		from {local x is length.} until x = 0 step {set x to x-1.} do {
			if all_eng[x]:stage = s{
				res:add(all_eng[x]).
			}
		}
		return res.
	}
}
function dvcalc {
	set dv_total to 0.
	set fuel to 0.
	set dv_in_stage_old to 0.
	set start_dv to 0.
	Until 1 < 0 {
		for x in stage:resourcesLex:values {
			if x:Amount <> 0 {
				set fuel to fuel + x:density * x:amount.
			}
		}
		local Ftot is 0.
		local mflow is 0.
		for eng in act_eng() {
			if eng:ignition {
				local isp is eng:getmodule("ModuleEnginesRF"):Getfield("specific Impulse").
				local F is eng:maxthrust.
				set Ftot to Ftot + F.
				if isp <> 0 set mflow to mflow + F / isp.
			}
		}
		if mflow = 0 { 
			set mflow to 1.
		}
		set dv_in_stage to Ftot/mflow*9.81*ln(ship:mass / (ship:mass-fuel)).
		set dv_burned to dv_in_stage_old - dv_in_stage.
		set dv_total to dv_total + max(0,dv_burned).
		if start_dv = 0 and dv_in_stage <> 0 set start_dv to dv_in_stage.
		print "dV (each second) : " + round(dv_burned,2) + " m/s"+"      "at(0,5).
		print "dV spent (total) : " + round(dv_total,2) + " m/s"+"      "at(0,6).
		print "dV in current Stage at start : " + round(start_dv,2) + " m/s"at(0,7).
		print "dV left in Stage : " + round(dv_in_stage,2) + " m/s" + "     "at(0,8).
		set dv_in_stage_old to dv_in_stage.
		set fuel to 0.
		wait 0.05.
	}
}
