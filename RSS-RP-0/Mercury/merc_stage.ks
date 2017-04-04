set ship:control:pilotmainthrottle to 0.
function stagingfunc {
	When Periapsis < Body:Atm:Height then {
		list engines in listeng.
		local foo is listeng:length -1.
		local curr_active_engines is list().
		from {local x is (listeng:length -1).} until x = 0 step {set x to x-1.} do {
			if listeng[x]:stage = stage:number {
				curr_active_engines:add(listeng[x]).
			}
		}
		for eng in curr_active_engines {		
			if eng:flameout {
				notify ("Engine Flameout, activating next stage.",2).
				Lock steering to heading(90,Pitchangle).
				wait 1.			
				stage.
				Lock steering to curs.
				break.
			}
			local ign is eng:getmodule("ModuleEnginesRF"):Getfield("ignitions remaining").
			if not eng:ignition and not eng:flameout and ign = 0 {
				notify ("Engine malfunction, activating next stage.",2).
				Lock steering to heading(90,Pitchangle).
				wait 1.			
				stage.
				Lock steering to curs.
				break.
			}
		}
		if Periapsis < Body:Atm:Height {
			Preserve.
		}
		wait 0.01.
	}
}
