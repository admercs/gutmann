;ndvi='../climates/ndviimages/newout';;Hack to get around the non-existant HANDLE_VALUE routine! (which seems to exist again now...)function getmapinfo, file	openr, un, /get, file+'.hdr'	s=''	readf, un, s	tmp=str_sep(s, ' ')	while tmp(0) ne 'map' and not eof(un) do begin		readf, un, s		tmp=str_sep(s,' ')	endwhile	free_lun, un	if tmp(0) ne 'map' then return, -1	xoff=0D	yoff=0D	xloc=0D	yloc=0D	px=0D	py=0D		reads, tmp(4),xoff	reads, tmp(5),yoff	reads, tmp(6),xloc	reads, tmp(7),yloc	reads, tmp(8),px	reads, tmp(9),py	;;for compatibility with ENVI map struct put it in	;; these variable names	return, {mc:[xoff,yoff,xloc,yloc],ps:[px,py]}end;;returns topleft(x,y),topright(x,y) in UTM14 coordinatesfunction getBounds, ndvi	envi_open_file, ndvi, r_fid=fid	if (fid eq -1) then return, -1	envi_file_query, fid, ns=ns, nl=nl, nb=nb, h_map=maph	envi_file_mng, id=fid, /remove;;written when I thought there was an issue with handle_value on maph	map=getmapinfo(ndvi)	left = map.mc(2)	top = map.mc(3)	if map.mc(0) ne 1 or map.mc(1) ne 1 then begin		left = left - (map.mc(0)-1)*map.ps(0)		top = top + (map.mc(1)-1)*map.ps(1)	endif	bottom = top - (nl*map.ps(1))	right = left + (ns*map.ps(0))	return, [left, top, right, bottom]end;;enlarge the boundary of bounds by increase meters on all sidesfunction increaseBounds, bounds, increase	newbounds = dblarr(4)	newbounds(0)=bounds(0) - increase	newbounds(1)=bounds(1) + increase	newbounds(2)=bounds(2) + increase	newbounds(3)=bounds(3) - increase	return, newboundsend;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	Takes a series of lat long coordinates and converts them;;	to UTM Zone 14 coordinates with the builtin envi routine;;	ENVI_CONVERT_PROJECTION_COORDINATES assumes we are in the;;	western hemisphere.  ;;;;	locations are a float array in decimal degrees [n_pointsx2];;		loc(*,0) = latitude, loc(*,1) = longitude;;;;	return value is float array in UTM14 [2,n_points] x_loc,y_loc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;function convertLLtoUTM, locations, zone  FORWARD_FUNCTION ENVI_PROJ_CREATE, ENVI_TRANSLATE_PROJECTION_UNITS    if n_elements(zone) eq 0 then zone=14  s=SIZE(locations);; assuming we are in the western hemisphere and we didn't specify;; that	  if locations[*,1] gt 0 then $    locations[*,1]=locations[*,1]*(-1)  units=ENVI_TRANSLATE_PROJECTION_UNITS('Degrees')  iproj=ENVI_PROJ_CREATE(/geographic, units=units, datum='WGS-84')  units=ENVI_TRANSLATE_PROJECTION_UNITS('Meters')  oproj=ENVI_PROJ_CREATE(/utm, units=units, datum='WGS-84', zone=zone)    ENVI_CONVERT_PROJECTION_COORDINATES, locations[*,1], locations[*,0], iproj, $    newXmap, newYmap, oproj  map=FLTARR(2, N_ELEMENTS(newXmap))  map[0,*]=newXmap  map[1,*]=newYmap    return, mapend;; reads the keyfile and returns a list of points with stationname,;; utm and Lat Lon coords, and the starting year for that stationfunction readpoints, keyfile, zone  openr, un, /get, keyfile    s=''  ;;read string  readf, un, s  tmp=str_sep(s, ' ')  tmp=tmp(where(tmp ne tmp(2)))    ;;convert lat lon strings to decimal degrees  lat=0  reads, tmp(1), lat  min = lat mod 100  lat = lat/100  lat = lat+ float(min)/60.  lon=0  reads, tmp(2), lon  min = lon mod 100  lon = lon/100  lon = lon+ float(min)/60.	  utmloc = convertLLtoUTM([[lat],[lon]], zone)  points = {wthpoint, name:tmp(0), xloc:utmloc(0), yloc:utmloc(1),$            lat:lat, lon:lon,start:tmp(3)}    while not eof(un) do begin     readf, un, s     tmp=str_sep(s, ' ')     tmp=tmp(where(tmp ne tmp(2)))          ;;convert lat lon strings to decimal degrees     lat=0     reads, tmp(1), lat     min = lat mod 100     lat = lat/100     lat = lat+ float(min)/60.     lon=0     reads, tmp(2), lon     min = lon mod 100     lon = lon/100     lon = lon+ float(min)/60.          utmloc = convertLLtoUTM([[lat],[lon]], zone)          points = [points, {wthpoint, name:tmp(0), xloc:utmloc(0), $                        yloc:utmloc(1), lat:lat, lon:lon,start:tmp(3)}]  endwhile    free_lun, un  return, pointsend;;returns true if this point is within the boundaries spec-ed by boundsfunction isInBounds, point, bounds  return, point.xloc lt bounds[2] and $    point.xloc gt bounds[0] and $    point.yloc lt bounds[1] and $    point.yloc gt bounds[3]end;;returns a list of points that fall within boundsfunction inbounds, points, bounds		done=0	i=0	;;find the first valid point	while not done and i lt N_ELEMENTS(points) do begin		done= isInBounds(points[i], bounds)		i=i+1	endwhile        if i eq N_ELEMENTS(points) and (not done) then begin           print, points           print, bounds           return, -1        endif else if i eq N_ELEMENTS(points) then return, points[i-1]	res = i-1	;;find all the rest of the valid points	for j=i, n_elements(points)-1 do begin		if isInBounds(points[j], bounds) then begin 			res=[res,j]		endif	endfor	return, points[res]end;; picks the wth files that can be used with the input image boundaryfunction pickwthfiles, bounds, weather, zone	key=findfile(weather+path_sep()+'*.key')	;print, weather	if n_elements(key) gt 1 then key = weather+path_sep()+'full.key'	if (not (file_test(key))(0)) or (strlen(key))(0) lt 1 then begin 		key=findfile(path_sep()+'*.key')		if n_elements(key) gt 1 then key = 'full.key' $		else key = key(0)		if not (file_test(key))(0) then begin			print, 'Could not file weather .key file : ', key			retall		endif	endif		print, weather	points = readpoints(key, zone)	return, inbounds(points,bounds)end;; writes a text file that is used as input to list100pro setuplist100, centbase, outdir	openw, listun, /get, centbase	printf, listun, centbase	printf, listun, centbase	printf, listun, ' '	printf, listun, ' '	printf, listun, 'aglivc'	printf, listun, 'stdedc'	printf, listun, ' '	close, listun	free_lun, listunend		;; returns the number of bands in filefunction nbands, file	envi_open_file, file, r_fid=fid	if fid eq -1 then return, -1	envi_file_query, fid, nb=nb	envi_file_mng, id=fid, /remove	return, nbend	;; writes the meta file for spatCent.propro writespatcent, index, points, img, metaname, centdir, dates	openw, oun, /get, metaname	printf, oun, n_elements(index)		for i=0, n_elements(index)-1 do begin		cur=index(i)		lat = fix(points(cur).lat)*100		min = fix(points(cur).lat*100) mod 100		lat = lat + round(min/100. * 60)		lon = fix(points(cur).lon)*100		min = fix(points(cur).lon*100) mod 100		lon = lon + round(min/100. * 60)		                printf, oun, (centdir+path_sep()+ $                     (str_sep(points(cur).name,'.'))(0)), $                     lat,' ',lon	endfor	printf, oun, img	imgdata=nbands(img)	printf, oun, imgdata	printf, oun, dates		free_lun, ounend;; determines which century crop type to use given a c3 grass percentagefunction pickcrop, c3	if c3 gt 100 then begin		print, 'ERROR, c3=',c3,'... defaulting to CPR...'		crop='CPR'	endif else if c3 lt 0 then begin		print, 'ERROR, c3=',c3,'... defaulting to G5...'		crop='G5'	endif else if c3 lt 37 then begin	crop='G5'	endif else if c3 lt 63 then begin	crop='G3'	endif else if c3 lt 85 then begin	crop='G4'	endif else if c3 le 100 then begin	crop='CPR'		endif else begin		print, 'UNCLASSIFIED C3 =',c3		retall	endelse	return, cropend	;;Converts map positions into image spacefunction coordToimagespace, mapcoords, mapinfo	  mapcoords[0]=round((mapcoords[0] - mapinfo.mc[2])/mapinfo.ps[0]) $    - mapinfo.mc[0]  mapcoords[1]=round((mapinfo.mc[3] - mapcoords[1])/mapinfo.ps[1]) $    - mapinfo.mc[1]    return, long(mapcoords)end;;Find the C3 percentage from an image of C3 percentagesfunction findc3value, lat, lon, c3map  ;;;HACKING OUT THE C3map to run in COLORADO ONLY!!!  print, ' '  print, ' '  print, 'WARNING, WARNING, WARNING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'  print, ' this version of centfiles is ONLY using a C3 century crop type!!!!'  print, ' '  print, ' '  return, 90	envi_open_file, c3map, r_fid=imgfid	if imgfid eq -1 then begin		print, 'ERROR : Unable to open header file for ', c3map		print, 'Check ENVI .hdr, reset ENVI and IDL, and try again'		retall	endif	envi_file_query, imgfid, h_map=maph, ns=ns, nl=nl, $		xstart=xs, ystart=ys	if maph eq 0 then begin		print, 'ERROR : bad map info in ', c3map		print, 'Check ENVI .hdr, reset ENVI and IDL, and try again'		retall	endif		handle_value,maph, mapinfo	envi_file_mng, id=imgfid, /remove	utmpos=convertLLtoUTM([[lat],[lon]], mapinfo.proj.params[0])		imgcoords=coordToimagespace(utmpos, mapinfo)	print, ' '	c3=0.	openr, un, /get, c3map	point_lun, un, (imgcoords(1) * ns + imgcoords(0))*4	readu, un, c3	close, un	free_lun, un		return, c3*100end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	Sets envi header info (map and ns, nl, nb, type, interleave);;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;pro setCentHdr, info, fname	info.map.ps = ps	info.ns=windSize[1]	info.nl=windSize[2]	info.type=windSize[3] 		envi_setup_head, fname=fname, ns=info.ns, nl=info.nl, nb=info.nb, $		interleave=info.interleave, data_type=info.type, $		descrip=info.desc, map_info=info.map, /writeend	;;;;  set up the proper conversion for daycent;;pro setdaycent, unit, base  openw, oun, /get, base+'.convert'  printf, oun, '5'  printf, oun, base  printf, oun, base  printf, oun, '6'  printf, oun, base  printf, oun, base  printf, oun, '7'  printf, oun, base  close, oun  & free_lun, oun  printf, unit, 'Daycent_convert100 < '+base+'.convert'  printf, unit, 'daycent  -n '+base+' -s '+base  printf, unit, 'mv biowk.out '+base+'.out'end;; full.key file must be in weather directory, c3c4 must be a float map of c3 distribution;;	with an envi .hdr defining map information.  dates must be a list of dates for ;;	which spatial century maps should be created.  pro centfiles, ndvi,c3c4, wthdir, outdir, nocent=nocent, spatCfile, dates, $               withSTD=withSTD, daycent=daycent  envistart  print, 'this is the one!'  if n_elements(wthdir) eq 0 then wthdir = 'Weather'  if n_elements(c3c4) eq 0 then begin     print, 'centfiles, ndvi, c3c4, weatherDir, outputDir, nocent=nocent,spatCfile, ' + $       'withSTD=withSTD, daycent=daycent'     print, '  ndvi = ndvi image with ENVI header'     print, '        used to specify the location'     print, '  c3c4 = %C3 image with ENVI header'     print, '        used to spec CENTURY crop type'     print, '  weatherDir = directory containing'     print, '        CENTURY .wth files (optional, default="Weather")'     print, '  outputDIR = output directory'     print, '  nocent, set this keyword if .lis files exist already'     print, '  spatCfile = spatial output file (optional default="spatCmeta.out")'     print, '         ".out" will be appended to the filename'     print, '  dates = intarr(n,3)  3 = (year, mon, day)'     print, '  withSTD = add in Standing Dead to the spatial CENTURY output'     print, '  daycent = setup and run daycent instead of century (.wth files must be daily).  '     return  endif    if n_elements(spatCfile) eq 0 then spatCfile = 'spatCmeta'  ;;uses ENVI to return ndvi image bounds in UTM zone 14 coordinates  bounds=getBounds(ndvi)  if bounds(0) eq -1 then begin     print, 'ERROR with the NDVI file'     return  endif;;allow searches 10Km outside of ndvi image boundary;; edit : 7/9/2003 changed to 50km so that small images will;; (hopefully) work  largebounds = increaseBounds(bounds, 50000)  info=getFileInfo(ndvi)  wthpoints=pickwthfiles(largebounds, wthdir, info.map.proj.params[0])  help, wthpoints  if keyword_set(daycent) then suffix='.out' else suffix='.lis'  if not keyword_set(nocent) then $    openw, oun, /get, 'centbatch'  goodpoints=0    for i=0,n_elements(wthpoints)-1 do begin          ;; setup and run CENTURY     if not keyword_set(nocent) then begin        ;; initialize file names        sitename=(str_sep(wthpoints(i).name,'.'))[0]+'.100'        schedname=(str_sep(wthpoints(i).name,'.'))[0]+'.sch'        centbase=(str_sep(wthpoints(i).name,'.'))[0]        ;; generate weather statistics        cd, wthdir, current=current        dat=wthstat(wthpoints(i).name, daycent=daycent)        cd, current        ;; pick a CENTURY crop type based on the C3vsC4 map                                c3 = findc3value(wthpoints(i).lat, wthpoints(i).lon, c3c4)        crop = pickcrop(c3)                if dat(0) ne -1 then begin;; set up the Site.100 and Site.sch files           site100, [dat,wthpoints(i).lat,wthpoints(i).lon],outdir, sitename, c3=c3           sitesch, outdir, sitename,wthpoints(i).name,$             wthpoints(i).start,crop,schedname, daycent=daycent           print, 'CROP type = ',crop,' ---- C3% = ', c3           ;; set up the LIST.100 file           cd, outdir, current=currentdir           setuplist100, centbase, outdir           cd, currentdir           ;; add to  the batch processing file           printf, oun, 'mv '+outdir+path_sep()+centbase+'* .'+path_sep()           printf, oun, 'mv '+wthdir+path_sep()+centbase+'.wth .'+path_sep()           if keyword_set(daycent) then begin              setDaycent, oun, centbase           endif else begin              printf, oun, 'century -n '+centbase+' -s '+centbase;           printf, oun, 'cp '+outdir+path_sep()+centbase+'.bin'+' .'+path_sep()              printf, oun, 'list100 <'+centbase           endelse           printf, oun, 'mv '+centbase+'.wth '+wthdir+path_sep()           printf, oun, 'mv '+centbase+'* '+outdir+path_sep() ;           printf, oun, 'cp '+outdir+path_sep()+centbase+'.bin'+' .'+path_sep();				printf, oun, 'rm '+outdir+path_sep()+centbase+'.bin';				printf, oun, 'rm '+outdir+path_sep()+centbase+'.sch';				printf, oun, 'rm '+outdir+path_sep()+centbase+'.100'                      goodpoints=[goodpoints,i]           ;; we had some sort of error in the weather file        endif else print, 'ERROR : ', wthpoints(i).name                ;; if we are not running CENTURY...     endif else if file_test(outdir+path_sep()+ $                             (str_sep(wthpoints[i].name,'.'))[0]+suffix) then begin        goodpoints=[goodpoints,i]     endif       endfor  if not keyword_set(nocent) then $    free_lun, oun    goodpoints=goodpoints[1:n_elements(goodpoints)-1];; run the CENTURY batch process    if not keyword_set(nocent) then begin     free_lun, oun     file_chmod, 'centbatch' , '0744'o     spawn, 'centbatch'  endif    writespatcent, goodpoints, wthpoints, ndvi, spatCfile, outdir, dates  ;; we may need to find a way to wait for the centbatch process to;; return before we run spatCent so it may be best to comment this line;; until we can do this (at least when running CENTURY);; For now IDL appears to wait for a spawned process to return before;; continuing (for better or for worse, it helps here...)  spatCent, spatCfile, withSTD=withSTD, daycent=daycent  end