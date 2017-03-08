//kOS Until vs recursive functions
//Author : Meltdown
Clearscreen.
set infinity to 1e69.
function hyp2f1b {
Parameter x.
    if x >= 1.0 {
        return infinity.
	}
    else {
		local res_old to 0.
        local res to 1.
        local term to 1.
        local ii to 0.
        Until res_old = res {
            set term to term * (3 + ii) * (1 + ii) / (5 / 2 + ii) * x / (ii + 1).
            set res_old to res.
            set res to res + term.
            if res_old = res {
                return res.
			}
            set ii to ii + 1.
			wait 0.000000000001.
		}
	}
}
function Hyp2f1b_rekursiv {
Parameter x.
	function fast_hyp {
		Parameter 
		x,
		res,
		term,
		n,
		res_old.
		local term to term * (3 + n) * (1 + n) / (5 / 2 + n) * x / (n + 1).
		local res_old to res.
		local res to res + term.
		if res_old = res {
			return res.
		}
		return fast_hyp(x, res, term, n+1, res_old).
	}
	if x >= 1 {
		return infinity.
	}
	return fast_hyp(x,1,1,0,0).
}
set time1 to time:seconds.
print hyp2f1b(0.9)at(0,15).
print "The Until Loop took : " + round(time:seconds-time1,4) + " s"at(0,16).
set time2 to time:seconds.
print hyp2f1b_rekursiv(0.9)at(0,17).
print "rekursive took : " + round(time:seconds-time2,4) + " s"at(0,18).
