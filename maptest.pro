pro maptest

;Projection: UTM Zone #14 North
;Map: 74768.69E,4460495.30N Meters
;LL : 40B011'20.24"N, 103B059'39.26"W
  lat= 40 + double(11)/60. + (double(20.24)/60.)/60
  lon=103 + double(59)/60. + (double(39.26)/60.)/60
  print, ll_to_utm(lon, lat, SetZone=14)
  print, ll_to_utm(lon, lat)
  lon=lon*(-1)
  utm= ll_to_utm(lon, lat, SetZone=14)
  print, ll_to_utm(lon, lat)
  help, utm
  print, utm
end
