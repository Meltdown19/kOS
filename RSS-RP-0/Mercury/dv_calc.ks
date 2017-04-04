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
