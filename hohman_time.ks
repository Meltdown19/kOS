//kOS
//@author Meltdown
//v 0.1

//a function that takes a longitude and returns an angle.
function fastdeg {
Parameter long.
return Mod(long + 360, 360).
}
// evaluates the radient for a given degree.
function fastrad {
parameter deg.
return ( ((2*constant:pi)/360) * deg).
}
//evaluates the angular difference between two objects
function targetangle {
Parameter Object.
Return mod((fastdeg(object:longitude) - fastdeg(ship:Longitude) +360)).
}
//Evaluates the waitingtime for the orbit of both ships 
function Hohtrans_time {
Parameter object.
local bodyMass is Ship:Obt:body:Mass

set Hohtransmajoraxis to ((orbit:semimajoraxis+object:orbit:semimajoraxis) / 2).
set TOF to constant:pi*sqrt(Hohtransmajoraxis^3/body:mu)  //Time of Flight of the transferorbit
//gets the mean anomaly speed in radients
function mean_anom {
	parameter object.
	return sqrt(body:mu / object:orbit:semimajoraxis^3).
}
set lead_ang to mean_anom(object) * TOF.
// Phase angle between burn start and leading object. 
set phi_final to constant:pi - lead_ang.
// initial phase angle between two objects.
set phi_start to fastrad(targetangle(object)).

set wait_until_burn to ( (phi_final-phi_start) / (lead_ang(object) - lead_angle(ship)) ).

return wait_until_burn.
}
