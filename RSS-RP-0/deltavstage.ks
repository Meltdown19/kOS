function Druck {
parameter h is altitude.
	if h < body:atm:height {
	return (101.325 * constant:e^ (-h/body:atm:height)).
	}
	else return 0.
}
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
			local F is eng:maxthrust.
			set Ftot to Ftot + F.
			set mflow to mflow + F / eng:ispat(Druck()).
		}
	}
	if mflow = 0 { 
		return 0.
	}
	else { 
		return Ftot/mflow*9.81*ln(ship:mass / (ship:mass-fuel)).
	}
}
