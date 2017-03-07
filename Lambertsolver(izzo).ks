//Izzo's algorithm for Lambert's problem for kOS
//@author Meltdown
// v. 0.1
// The algorithm is still dropping alot of errors so don't try to send your manned mission to Jool with it.
// M >= 1 is also not working.
// original from https://github.com/poliastro/poliastro
//The MIT License (MIT)
//Copyright (c) 2012-2017 Juan Luis Cano Rodríguez
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
function asinh {
Parameter n.

return log10(n + sqrt(n^2 +1)).
}
//[0, +Inf)
set infinity to 1e69.

//log to the base 2
function log2 {
Parameter n.
return log10(n) / log10(2). 
}
// 
function norm {
Parameter vec.
    return vec:mag.
}
//Hypergeometric function 2F1(3, 1, 5/2, x), see [Battin].
function hyp2f1b {
Parameter x.
    if x >= 1.0 {
        return infinity.
	}
    else {
        set res to 1.
        set term to 1.
        set ii to 0.
        Until res_old = res {
            set term to term * (3 + ii) * (1 + ii) / (5 / 2 + ii) * x / (ii + 1).
            set res_old to res.
            set res to res + term.
            if res_old = res {
                return res.
			}
            set ii to ii + 1.
			wait 0.0001.
		}
	}
}
//Mainfunction
//returns a list .
function _lambert{
Parameter 
	k,  //Gravitational constant of main attractor (km^3 / s^2)
	r1, //Initial position (km).
	r2, //Final position (km).
	tof, //Time of flight (s).
	M, //Number of full revolutions.
	numiter, //Maximum number of iterations.
	rtol. //Relative tolerance of the algorithm

    // Chord
    set ch to r2 - r1.
    set c_norm to norm(ch).
	set r1_norm to norm(r1).
	set r2_norm to norm(r2).

    // Semiperimeter
    set s to (r1_norm + r2_norm + c_norm) * .5.

    // Versors
    set i_r1 to r1 / r1_norm. 
	set i_r2 to r2 / r2_norm.
    set i_h to vcrs(i_r1, i_r2).
	set i_h to i_h / norm(i_h). 

    // Geometry of the problem
    set ll to sqrt(1 - c_norm / s).

    if i_h:z < 0 {
       set ll to -ll.
       set i_h to -i_h.
	}
    set i_t1 to vcrs(i_h, i_r1).
	set i_t2 to vcrs(i_h, i_r2).

    // Non dimensional time of flight
    set T to sqrt(2 * k / s^3) * tof.

    // Find solutions
    set xy to _find_xy(ll, T, M, numiter, rtol).

    // Reconstruct
    set gamma to sqrt(k * s / 2).
    set rho to (r1_norm - r2_norm) / c_norm.
    set sigma to sqrt(1 - rho^2).
	set halfres to _reconstruct(xy[0], xy[1], r1_norm, r2_norm, ll, gamma, rho, sigma).
	set V_r1 to halfres[0].
	set V_r2 to halfres[1].
	set V_t1 to halfres[2].
	set V_t2 to halfres[3].
	set reslambert to list().
	reslambert:add(V_r1 * i_r1 + V_t1 * i_t1).
	reslambert:add(V_r2 * i_r2 + V_t2 * i_t2).
	return reslambert.

}

function _reconstruct {
Parameter 
	x, 
	y, 
	r1, 
	r2, 
	ll, 
	gamma, 
	rho, 
	sigma.
	//Reconstruct solution velocity vectors.
    set V_r1 to gamma * ((ll * y - x) - rho * (ll * y + x)) / r1.
    set V_r2 to -gamma * ((ll * y - x) + rho * (ll * y + x)) / r2.
    set V_t1 to gamma * sigma * (y + ll * x) / r1.
    set V_t2 to gamma * sigma * (y + ll * x) / r2.
    local res is list().
	res:add(V_r1).
	res:add(V_r2).
	res:add(V_t1).
	res:add(V_t2).
	return res.
}

//Computes all x, y for given number of revolutions.
function _find_xy {
Parameter 
	ll, 
	T, 
	M, 
	numiter, 
	rtol.
  //  # For abs(ll) == 1 the derivative is not continuous
  //  assert abs(ll) < 1
  //  assert T > 0  # Mistake on original paper

   set M_max to floor(T / constant:pi).
    set T_00 to arccos(ll) + ll * sqrt(1 - ll^2).
    //Refine maximum number of revolutions if necessary
    if T < T_00 + M_max * constant:pi and M_max > 0 {
        set T_min to _compute_T_min(ll, M_max, numiter, rtol).
        if T < T_min {
            set M_max to M_max - 1.
		}
	}
    // Check if a feasible solution exist for the given number of revolutions
    // This departs from the original paper in that we do not compute all solutions
    if M > M_max {
        Print "No feasible solution, try with a smaller M".
	}
    // Initial guess
	set x_0 to _initial_guess(T, ll, M).
    // Start Householder iterations from x_0 and find x, y
	set x to _householder(x_0, T, ll, M, rtol, numiter).
	set y to _compute_y(x, ll).
	return list(x,y).
}

//computes y
function _compute_y{
Parameter 
	x, 
	ll.
return sqrt(1 - ll^2 * (1 - x^2)).
}
//computes psi
function _compute_psi {
Parameter 
x, 
y, 
ll.
//The auxiliary angle psi is computed using Eq.(17) by the appropriate inverse function
    if -1 <= x and x < 1 {
        // Elliptic motion
        // Use arc cosine to avoid numerical errors
        return arccos(x * y + ll * (1 - x^2)).
	}
	//hyperbolic motions are dropping exception errors so I decided to comment it out for now
//    if x > 1 {
 //       //Hyperbolic motion
//        //The hyperbolic sine is bijective
//        return asinh((y - x * ll) * sqrt(x^2 - 1)).
//	}
    else {
        // Parabolic motion
        return 0.0.
	}
}
//Time of Flight equation
function _tof_equation {
Parameter 
	x, 
	y, 
	T0, 
	ll, 
	M.
	if M = 0 and sqrt(0.6) < x  and x < sqrt(1.4) {
		set eta to y - ll * x.
		set S_1 to (1 - ll - x * eta) * .5.
		set Q to 4 / 3 * hyp2f1b(S_1). 
		set T_ to (eta^3 * Q + 4 * ll * eta) * .5.
	}
    else {
		set psi to _compute_psi(x, y, ll).
		set T_ to ( ((psi + M * constant:pi / sqrt(abs(1 - x^2))) - x + ll * y) / (1 - x^2) ). //Might be unprecise due to divisionerrors with integers.
	}
    return T_ - T0.
}


function _tof_equation_p {
Parameter 
	x, 
	y, 
	T, 
	ll.
    // TODO: What about derivatives when x approaches 1?
    return (3 * T * x - 2 + 2 * ll^3 * x / y) / (1 - x^2).
}

function _tof_equation_p2 {
Parameter 
	x, 
	y, 
	T, 
	dT, 
	ll.
    return (3 * T + 5 * x * dT + 2 * (1 - ll^2) * ll^3 / y^3) / (1 - x^2).
}
function _tof_equation_p3 {
Parameter 
	x, 
	y, 
	_, //Wildcard ? Here??! I'm confused.
	dT, 
	ddT, 
	ll.
    return (7 * x * ddT + 8 * dT - 6 * (1 - ll^2) * ll^5 * x / y^5) / (1 - x^2).
}
//compute minimum T. Somewhat different from the original function because there is no need for x_T_min to be returned.
function _compute_T_min {
Parameter 
	ll, 
	M, 
	numiter, 
	rtol.

    if ll = 1 {
		set x_T_min to 0.0.
		set T_min to _tof_equation(x_T_min, _compute_y(x_T_min, ll), 0.0, ll, M).
	}
	else {
		if M = 0 {
			set x_T_min to infinity.
			set T_min to 0.0.
		}
        else {
            // Set x_i > 0 to avoid problems at ll = -1
			set x_i to 0.1.
			set y to _compute_y(x_i, ll).
			set T_i to _tof_equation(x_i, y, 0.0, ll, M).
			set x_T_min to _halley(0.1, T_i, ll, rtol, numiter).
			set T_min to _tof_equation(x_T_min, y, 0.0, ll, M).
		}
	}
    return T_min.
}

function _initial_guess {
Parameter 
	T, 
	ll, 
	M.
	if M = 0 {
       // Single revolution
		set T_0 to arccos(ll) + ll * sqrt(1 - ll^2) + M * constant:pi. // Equation 19
		set T_1 to 2 * (1 - ll^3) / 3.  // Equation 21
		if T >= T_0 {
			set x_0 to (T_0 / T)^(2 / 3) - 1.
		}
		if T < T_1 {
		set x_0 to 5 / 2 * T_1 / T * (T_1 - T) / (1 - ll^5) + 1.
		}
		else {
			//This is the real condition, which is not exactly equivalent
			//elif T_1 < T < T_0
			set x_0 to (T_0 / T)^(log2(T_1 / T_0)) - 1.

			return x_0.
		}
	}
	else {
        //Multiple revolution
		set x_0l to (((M * constant:pi + constant:pi) / (8 * T))^(2 / 3) - 1) / (((M * constant:pi + constant:pi) / (8 * T))^(2 / 3) + 1).
		set x_0r to (((8 * T) / (M * constant:pi))^(2 / 3) - 1) / (((8 * T) / (M * constant:pi))^(2 / 3) + 1).

		return list(x_0l, x_0r).
	}
}
//Find a minimum of time of flight equation using the Halley method.
//Note
//----
//This function is private because it assumes a calling convention specific to
//this module and is not really reusable.
function _halley {
Parameter 
	p0, 
	T0, 
	ll, 
	tol, 
	maxiter.
	for ii in range(maxiter+1) {
		set y to _compute_y(p0, ll).
		set fder to _tof_equation_p(p0, y, T0, ll).
		set fder2 to _tof_equation_p2(p0, y, T0, fder, ll).
		if fder2 = 0 {
			Print"Derivative was zero".
		}
		set fder3 to _tof_equation_p3(p0, y, T0, fder, fder2, ll).

		//Halley step (cubic)
		set p to p0 - 2 * fder * fder2 / (2 * fder2^2 - fder * fder3).

		if abs(p - p0) < tol {
			return p.
		}
		set p0 to p.
	}
    print"Failed to converge".
}
//Find a zero of time of flight equation using the Householder method.
//Note
// ----
//This function is private because it assumes a calling convention specific to
//this module and is not really reusable.
Function _householder {
Parameter 
	p0, 
	T0, 
	ll, 
	M, 
	tol, 
	maxiter.
	for ii in range(maxiter+1) {
		set y to _compute_y(p0, ll).
		set fval to _tof_equation(p0, y, T0, ll, M).
		set T to fval + T0.
		set fder to _tof_equation_p(p0, y, T, ll).
		set fder2 to _tof_equation_p2(p0, y, T, fder, ll).
		set fder3 to _tof_equation_p3(p0, y, T, fder, fder2, ll).

		// Householder step (quartic)
		set p to p0 - fval * ((fder^2 - fval * fder2 / 2) / (fder * (fder^2 - fval * fder2) + fder3 * fval^2 / 6)).

		if abs(p - p0) < tol {
			return p.
		}
		set p0 to p.
	}
    print"Failed to converge".
}

Print _lambert(3.986004418e+14, v(2,-2,3), v(1,2,3), 1, 0, 35, 1e-4).
