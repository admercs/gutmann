;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;from ~/idl/sand/weatherprocessing/osxccentfiles
;
;;returns [left, top, right, bottom] coordinates in the map
;; coordinate system of the imageFile.  imageFile must have
;; a valid ENVI header file and associated map information.  
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;enlarge the boundary of bounds by increase meters on all sides
function increaseBounds, bounds, increase
  newbounds = dblarr(4)
  newbounds(0)=bounds(0) - increase
  newbounds(1)=bounds(1) + increase
  newbounds(2)=bounds(2) + increase
  newbounds(3)=bounds(3) - increase
  return, newbounds
end

function getBounds, imageFile
  info=readENVIhdr(imageFile)

  ns=info.ns
  nl=info.nl
  map=info.map
  
  left = map.mc(2)
  top = map.mc(3)
  
  if map.mc(0) ne 1 or map.mc(1) ne 1 then begin
    left = left - (map.mc(0)-1)*map.ps(0)
    top = top + (map.mc(1)-1)*map.ps(1)
  endif
  
  bottom = top - (nl*map.ps(1))
  right = left + (ns*map.ps(0))
  
  return, [left, top, right, bottom]
  
end

;;returns true if this point is within the boundaries spec-ed by
;;bounds
function isInBounds, point, bounds
  return, point.xloc lt bounds(2) and $
          point.xloc gt bounds(0) and $
          point.yloc lt bounds(1) and $
          point.yloc gt bounds(3)
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;from ~/idl/3rdParty/mapping/ll_to_utm.pro
;; documention is in original file.
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION UTM_ZONE, Lon, CM = CM, SetZone=SetZone

COMPILE_OPT idl2, HIDDEN

On_Error, 2

   ;be sure that the lonitude is a bit smaller than extremes
CM = -179. > FLoat(Lon) < 179.
  ;make an array of bounding meridians for each zone
Bounds = Findgen(61)*6. - 180.
N = N_elements(CM)
Zone = LonArr(N)
For i = 0L, N-1L Do Zone[i]=   (Where ( Bounds GE CM[i]) )[0]
  ;if requested transform CM into its proper value
IF n_elements(SetZone) gt 0 Then Zone = SetZone
If Arg_Present(CM) Then CM = Bounds[Zone-1L]+3.

Return, Zone

END


FUNCTION LL_TO_UTM, LonV, LatV, DatumName,$
	Datum=Datum, Zone = Zone, CM = CM, K = K, P = P, $
	NoFalse = NoFalse, SetZone=SetZone

If N_Params() LT 2 Then Begin
   Message, 'Must supply at least two arguments'
   Return, -1
EndIf

Num = N_elements(LonV)
If N_elements(LatV) NE Num Then Begin
   Message, 'Input arguments must have same number of elements'
   Return, -1
EndIf

Utm = FltArr(2,N_Elements(LonV))
Lon=Float(LonV)			&	Lat=Float(LatV)

If N_Elements(DatumName) EQ 0 Then Begin
  If N_elements(Datum) NE 0 Then Begin
      DatumChoices = ['Blank','NAD27','WGS84', 'NAD83',$
      	      'GRS80', 'WGS82', 'AUS1965', 'KRAS1940','INT1924', 'HAY1909', 'CLARKE1880',$
      	      'CLARKE1866', 'AIRY1830', 'BESSEL1841', 'EVEREST1830']
      DatumName = DatumChoices[Datum[0]]
  EndIf Else DatumName = 'NAD27'

EndIf

	;get the map datum info
P = Map_Datum(DatumName)
If Size(P,/Type)  NE 8 Then Begin
   Message, 'Map Datum not found'
   Return, -1
EndIf

    ;make Ecc_sq_prime
E2p = P.E^2*(1.0 - P.E^2)

	;get the UTM zone ID and the central meridian
Zone = UTM_Zone(Lon, CM = CM, SetZone = SetZone)

	;determine lon origin (cm) in radians
Lon0 = CM*!DtoR

	;	convert to radians
Lon = Lon*!DtoR    &    Lat = Lat*!DtoR

N = P.A/SQRT(1. - P.E^2*(sin(lat))^2 )
T = ( Tan(Lat) )^2
C = E2p * ( cos(lat) )^2
A = Cos(Lat ) * (Lon - Lon0)

  ;for the UTM projections, the scaling factor K is taken to be a constant, K0,
  ; at the central meridian
K0 = 0.9996d
	; k is unused for UTM... default to k0
	; make it available any way
If Arg_Present(K) Then $
  k = k0*(1.+ (1.+C)*(A^2)/2. + $
	(5. - 4.*T + 42.*C + 13.*C^2 -28.*E2p)*(A^4)/24. + $
	(61. - 148.*T + 16.*T^2)*(A^6)/720.)

South =Where(LatV LT 0.0, CountSouth)
    ; M is M(Lat Origin, the equator)
M0 = FltArr(Num)
If CountSouth GT 0 Then M0[South] = 10000000.

   ;M is the true distance along the CM from the equator
M = P.A*((1.0 - P.E^2/4. - 3.*P.E^4/64. - 5.*P.E^6/256. )* Lat - $
	(3.*P.E^2/8. + 3.*P.E^4/32.+45.*P.E^6/1024.)*sin(2.*lat) + $
	(15.*P.E^4^2/256.+45.*P.E^6/1024.)* sin(4.*lat) - $
	(35.*P.E^6/3072.)*sin(6.*lat) )

	;  Easting or X in Snyder
Lon =  k0*N*(A + (1. - T + C)*(A^3)/6. $
	+ (5. - 18.*T + T^2 + 72.*C - 58.*E2p)*(A^5)/120.)

	;Northing or Y in Snyder
Lat =   K0*(M-M0 + N*tan(Temporary(lat))*((A^2) / 2. + ( 5. - T + 9.*C + 4.*C^2 ) * (A^4)/24. + $
	              (61. - 58.*T + T^2 + 600.*C - 330.*E2p)*(A^6) / 720.))

	; make False Easting if desired (default)
If Not (KeyWord_Set(NoFalse))  Then Lon = Lon + 500000.0d

Return,Transpose([[Lon],[Lat]])

END
