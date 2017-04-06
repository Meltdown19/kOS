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
function deltavstage{
	local fuel is 0.
	for y in stage:resourcesLex:values {
		if y:Amount <> 0 {
			set fuel to fuel + y:density * y:amount.
		}
	}
	local Ftot is 0.
	local mflow is 0.
	for eng in act_eng() {
		if eng:ignition {
			local isp is eng:getmodule("ModuleEnginesRF"):Getfield("specific Impulse").
			local F is eng:maxthrust.
			set Ftot to Ftot + F.
			if isp <> set mflow to mflow + F / isp.
		}
	}
	if mflow = 0 { 
		return 0.
	}
	else { 
		return Ftot/mflow*9.81*ln(ship:mass / (ship:mass-fuel)).
	}
}
