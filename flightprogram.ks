// Simples kOS Ascent script
// Don't try to run it with launchers TWR lower than 1.7! In Stock KSP 1.2 you should always go full throttle on a TWR at slightly above 2
{
set pit_PID to PID_Init(0.03, 0.0, 0.0003, -75, 75).
set pit_noneg_PID to PID_Init(0.81, 0.0, 0.03, -15, 15).
set pit_PID_p1 to PID_Init(0.0018, 0.0, 0.003, -10, 3).
Clearscreen.
Lock throttle to curT.
set curT to 0.
LOCK Steering to curS.
set curS TO Heading(90,90).
set n to 2.
global Flightprogram is lex(
	"sequence", list (
	"Presys_checks", presys_checks@,
	"Countdown", Countdown@,
	"Stage_me", Stage_me@,
	"Pitchcontrol", Pitchcontrol@,
	"Phasei",Phasei@,
	"phaseii", Phaseii@,
	"Finalizing", Finalizing@
	), 
	"events", Lex()
	).
Function Presys_checks{
	Parameter mission.
	monitor(). //a ssimple loop that plots some important values on the kOS Monitor.
	Notify ("Flightcomputer is running",2).
	wait 2.
	mission["next"]().
}
Function  Countdown {
	Parameter mission.
	If n = 2 {
		set curT to 1.
		wait 0.0001.
		stage.
		NOTIFY("T - " + n + " Sekunden", 1).
		wait 1.
		set n to n-1.
	}
	If n = 1 {
		NOTIFY("T - " + n + " Sekunden", 1).
		wait 1.
		set n to n-1.
	}
	if n = 0 {
		NOTIFY("LIFTOFF", 1).
		stage.
		wait 1.
		mission["next"]().
	}
}
Function Stage_me {
	Parameter mission.
	staging_logic(). //A loop thats checking the ships thrust for when to stage. Its not fully coded so I left it on my local for now.
	mission["next"]().
}
Function Pitchcontrol {
	Parameter mission.
		If myspeed < 100 { //myspeed is obviously the ships vertical speed.
			set curS to Heading(90,90).
		}
		set curS to heading(90, MAX(90 * (CONSTANT:E ^ (-1.789e-5 * apoapsis )),12)).  
		If apoapsis > (TrgH + (tollerance * .5)) { //TrgH is the desired Altitude, tollerance is set to a 10th of that for low circular orbits
			mission["next"]().
		}
}
Function Phasei {
	Parameter mission.
	set curS to heading(90,PID_Seek(Pit_PID_p1, (TrgH + tollerance), Apoapsis)).
	If Periapsis < -1e6 and Periapsis > -4e6{
		mission["next"]().
	}
}
Function Phaseii {
	Parameter mission.
	if eta:Apoapsis < eta:Periapsis {
		set curS to heading(90,PID_Seek(Pit_PID_p1, (TrgH + tollerance), Apoapsis)).
	}
	if eta:Apoapsis > eta:Periapsis {
		set curS to heading(90,PID_Seek(Pit_noneg_PID, (TrgH + tollerance), Apoapsis)).
	}
	If Periapsis > -1e6 {
		mission["next"]().
	}
}
Function Finalizing {
	Parameter mission.
	set curT to 0.15.
	if eta:Apoapsis < eta:Periapsis and Periapsis < TrgH {
		set curS to heading(90,PID_Seek(Pit_PID, (TrgH + tollerance), Apoapsis)).
	}
	if myspeed < 20 and Periapsis < TrgH {
			set curS to heading(90,PID_Seek(Pit_noneg_PID, 5, myspeed)).
	}
	If Periapsis > TrgH or (Periapsis > body:atm:height and apoapsis > TrgH + constant:pi*tollerance) {	
		mission["terminate"]().
	}
}
}
