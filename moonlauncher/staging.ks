set sep_acc to 0.
function stagingfunc {
	When Altitude < Body:Atm:Height then {
		for sep in ship:partsnamed("SepMotor1") {
			local ign is sep:getmodule("ModuleEnginesRF"):Getfield("ignitions remaining").
			if ign = 0 and sep_acc = 0 {
				if ulli () {
					wait 2.
					stage.
					set sep_acc to 1.
					break.
				}
			}
		}
		list engines in listeng.
		for eng in Listeng {		
			if eng:flameout and eng:name <> "SepMotor1" {
				notify ("Engine Flameout, activating next stage.",2).
				Lock steering to heading(90,Pitchangle).
				wait 1.			
				stage.
				Lock steering to curs.
				set sep_acc to 0.
				break.
			}
		}
		if Altitude < Body:Atm:Height {
			Preserve.
		}
		wait 0.01.
	}
}
