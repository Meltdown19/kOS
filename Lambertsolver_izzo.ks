//for kOS
//Izzo's algorithm for Lambert's problem
//author Meltdown
// v. 0.2
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
//TODO: tof, M-errors
clearscreen.
//Constant Pi
set Pi to constant:pi.

function asinh {
Parameter n.

return ln(n + sqrt(n^2 +1)).
}
//]0, Inf] a true +inf would be nice but hey...hacks are real.
set infinity to 1e69.
// composes the magnitude of a vector
function magnitude {
Parameter vec.
	return sqrt(vdot(vec,vec)).
}
//Hypergeometric function 2F1(3, 1, 5/2, x), see [Battin].
function Hyp2f1b {
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
	// Magnitude Vectors
    set c_mag to magnitude(ch). 
	set r1_mag to magnitude(r1). 
	set r2_mag to magnitude(r2).

    // Semiperimeter
    set s to (r1_mag + r2_mag + c_mag) * .5.

    // Versors
    set i_r1 to r1 / r1_mag. 
	set i_r2 to r2 / r2_mag. 
    set i_h to vcrs(i_r1, i_r2).
	set i_h to i_h / magnitude(i_h).

    // Geometry of the problem
    set ll to sqrt(1 - c_mag / s).

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
    set rho to (r1_mag - r2_mag) / c_mag.
    set sigma to sqrt(1 - rho^2).
	set re_res to _reconstruct(xy[0], xy[1], r1_mag, r2_mag, ll, gamma, rho, sigma).
	set V_r1 to re_res[0].
	set V_r2 to re_res[1].
	set V_t1 to re_res[2].
	set V_t2 to re_res[3].
	return list( (V_r1 * i_r1 + V_t1 * i_t1),(V_r2 * i_r2 + V_t2 * i_t2) ) .
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
	return list(V_r1, V_r2, V_t1, V_t2).
}

//Computes all x, y for given number of revolutions.
function _find_xy {
Parameter 
	ll, 
	T, 
	M, 
	numiter, 
	rtol.
   set M_max to floor(T / Pi).
    set T_00 to arccos(ll) + ll * sqrt(1 - ll^2).
    //Refine maximum number of revolutions if necessary
    if T < T_00 + M_max * Pi and M_max > 0 {
        set T_min to _compute_T_min(ll, M_max, numiter, rtol).
        if T < T_min {
            set M_max to M_max - 1.
		}
	}
    // Check if a feasible solution exist for the given number of revolutions
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
	//hyperbolic motions are dropping exception errors so I decided to comment it out here
//   if x > 1 {
       //Hyperbolic motion
       //The hyperbolic sine is bijective
//	return asinh((y - x * ll) * sqrt(x^2 - 1)).
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
		set _eta to y - ll * x.
		set S_1 to (1 - ll - x * _eta) * .5.
		set Q to 4 / 3 * hyp2f1b(S_1). 
		set T_ to (_eta^3 * Q + 4 * ll * _eta) * .5.
	}
    else {
		set psi to _compute_psi(x, y, ll).
		set T_ to ( ((psi + M * Pi / sqrt(abs(1 - x^2))) - x + ll * y) / (1 - x^2) ). //TODO: check this again
	}
    return T_ - T0.
}


function _tof_equation_p {
Parameter 
	x, 
	y, 
	T, 
	ll.
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
	_,
	dT, 
	ddT, 
	ll.
    return (7 * x * ddT + 8 * dT - 6 * (1 - ll^2) * ll^5 * x / y^5) / (1 - x^2).
}
//compute minimum T.
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
		set T_0 to arccos(ll) + ll * sqrt(1 - ll^2) + M * Pi. // Equation 19
		set T_1 to 2 * (1 - ll^3) / 3.  // Equation 21
		if T >= T_0 {
			set x_0 to (T_0 / T)^(2 / 3) - 1.
		}
		if T < T_1 {
		set x_0 to 5 / 2 * T_1 / T * (T_1 - T) / (1 - ll^5) + 1.
		}
		else {
			//This is the real condition, which is not exactly equivalent
			//else if T_1 < T < T_0
			set x_0 to (T_0 / T)^(ln(T_1 / T_0)) - 1.

			return x_0.
		}
	}
	else {
        //Multiple revolution
		set x_0l to (((M * Pi + Pi) / (8 * T))^(2 / 3) - 1) / (((M * Pi + Pi) / (8 * T))^(2 / 3) + 1).
		set x_0r to (((8 * T) / (M * Pi))^(2 / 3) - 1) / (((8 * T) / (M * Pi))^(2 / 3) + 1).

		return list(x_0l, x_0r).
	}
}
//Find a minimum of time of flight equation using the Halley method.
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
set r0 to v(5000.0, 10000.0, 2100.0).
set r1 to v(-14600.0, 2500.0, 7000.0).
Print _lambert(398600, r0, r1, 3600, 0, 35, 1e-8).

//    expected va = [-5.9925, 1.9254, 3.2456] 
//    expected vb = [-3.3125, -4.1966, -0.38529] 
