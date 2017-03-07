// Lambert solver for kOS
//@Author Meltdown
//This uses the universal variable approach found in Battin, Mueller & White
//with the bisection iteration suggested by Vallado. Multiple revolutions
//not supported.
// v. 0.1

function Lambertsolver {
Parameter 
	k,  //body:mu
	r,  //vector
	r_0, //vector
	tof, // in seconds
	shortway, //boolean
	num_iter, //35 is a good number
	r_tollerance. // 1e-8 for now
	local tm is 0.
	if shortway = true {
		set tm to 1.
		}
	 else {
		set tm to -1.}
	local norm_r is vdot(r,r)^0.5. 
	local norm_r0 is vdot(r_0,r_0)^0.5.
	local cosDv is ( vdot(r ,r_0) / (norm_r0 * norm_r) ).
	local A is tm * sqrt(norm_R * norm_r0 * (1 + cosDv)).

	If A = 0 {
		Print "Cannot compute orbit, phase angle is 180 degrees".
	}
	local done is false.
	local psi is 0.001.
	local psilow is -12.5.
	local psiup is 12.5.
	local count is 0.
	Until count >= num_iter { 
		 set y to norm_r0 + norm_r + (A * (psi * c3(psi) - 1) ) / sqrt(c2(psi)).
				if A > 0 and y < 0 {
           // Readjust xi_low until y > 0.0
           //  Translated directly from Vallado				
					Until y > 0 { 
						set psiLow to psi.
						set psi to (0.8 * (1.0 / c3(psi)) * (1.0 - (norm_r0 + norm_r) * sqrt(c2(psi)) / A)).
						set y to norm_R + norm_r0 + A * (psi * c3(psi) - 1) / sqrt(c2(psi)).
						wait 0.0001.
					}
				}
		local xi is y / c2(psi).
		local tofnew is ( xi^3 * c3(psi) + A * sqrt(y) ) / sqrt(k).
		//convergence check
		if abs((tofNew - tof) / tof) < r_tollerance {
			print "Time of Flight is under the floor of the tollerance".
			set done to true.
			break.
		} 
		else {
			set count to count + 1.
			//Bisection check
			if (tofNew <= tof) {
				set psiLow to psi.
			} else {
				set psiUp to psi.
			}
			set psi to (psiUp + psiLow) / 2.
		}
		if count >= num_iter {
		Print "Maximum number of iterations reached.".
		set done to true.
		}
		wait 0.0001.
	}
	wait until done = true.
	local f is 1 - (y / norm_r0).
	local gee is (A * sqrt(y / k) ).
	local gdot is 1 - y / norm_r.
    local vec0 is ( (r - (r_0*f) ) *(1/gee) ).
    local vec1 is ( ((r*gdot) -r_0) * (1/gee) ).
	
	local result is list().
	result:add(vec0).
	result:add(vec1).
	return result.
}
set c2_count to 0.
set c3_count to 0.

// Stumpff functions c2, c3
function c2 {
Parameter psi.
	local epsilon is 1.
	if psi > epsilon {
		set resc2 to (1 - cos(sqrt(psi))) / psi.
	} else if psi < - epsilon {
		set resc2 to (cosh(sqrt(-psi)) - 1) / -psi.
	} else {
		set resc2 to 1.0 / 2.0.
		local delta is (-psi) / gamma(5).
		local k is 1.
		local mpsik is -psi.
		Until (resc2 + delta) = resc2 {
			set resc2 to resc2 + delta.
			local k to k + 1.
			set mpsik to mpsik * -psi.
			set delta to mpsik / gamma(2 * k + 3).
			wait 0.0001.
		}
	}
	return resc2.
}
function cosh {
Parameter numb.
return 0.5 * (constant:e ^numb + constant:e ^ (-1 * numb)).
}
function sinh {
Parameter numb.
return 0.5 * (constant:e ^numb - constant:e ^ (-1 * numb)).
}
function c3 {
Parameter psi.
	local eps is 1.0.
	if psi > eps {
		set resc3 to (sqrt(psi) - sin(sqrt(psi))) / (psi * sqrt(psi)).
	} else if psi < -eps {
		set resc3 to (sinh(sqrt(-psi)) - sqrt(-psi)) / (-psi * sqrt(-psi)).
	} else {
		set resc3 to 1.0/6.0.
		set delta to (-psi) / gamma(6).
		set k to 1.
		local mpsik is -psi.
		Until resc3 + delta = resc3 { 
			set resc3 to resc3 + delta.
			set k to k+1.
			set mpsik to mpsik * -psi.
			set delta to mpsik / gamma(2 * k + 4).
			wait 0.0001.
		}
	}
	return resc3.
}
// http://introcs.cs.princeton.edu/java/91float/Gamma.java.html
function gamma {
parameter numb.
function logGamma {
parameter num_x.
      set tmp to (num_x - 0.5) * log10(num_x + 4.5) - (num_x + 4.5).
      set ser to 1.0 + 76.18009173    / (num_x + 0)   - 86.50532033    / (num_x + 1)
                       + 24.01409822    / (num_x + 2)   -  1.231739516   / (num_x + 3)
                       +  0.00120858003 / (num_x + 4)   -  0.00000536382 / (num_x + 5).
      return tmp + log10(ser * sqrt(2 * constant:PI)).
   }
  return constant:e^(logGamma(numb)).
}

print Lambertsolver(3.986004418e14, v(1,2,4), v(2,4,3), 36, true, 35, 1e-8).
