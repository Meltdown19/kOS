set ship:control:pilotmainthrottle to 0.
set config:ipu to 1000.
clearscreen.
function xcopy {
Parameter file.
	switch to 1.
	if not exists(file) {
		switch to 0.
		copypath(file ,"1:/").
		switch to 1.
		runpath (file).
	}
	runpath(file).
}
xcopy ("lib_merc.ks").
xcopy ("lib_pid.ks").
xcopy ("mc.ks").
xcopy("merc_stage.ks").
xcopy("merc_launch.ks").
run_mission(mercury["sequence"], mercury["events"]).
set ship:control:pilotmainthrottle to 0.
