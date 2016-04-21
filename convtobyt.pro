;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	Reads the number of images we will concatenate
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function getNumberOfImages, unit
	 nimg=0
	 readf, unit, nimg
	 print, nimg
	 return, nimg
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	Reads the names of the images we will concatenate
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function getImageNames, unit, nimgs
	 names=strarr(nimgs)
	 tmp=''
	 for i=0, nimgs-1 do begin
	     readf, unit, tmp
	     names(i)=tmp
	 endfor

	 return, names
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	Gets envi header info (map and ns, nl, nb, type, interleave)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function getImageInfo, names, nimgs
	 
	 for i=0, nimgs-1 do begin
	     envi_open_file, names(i), r_fid=id
	     if id eq -1 then return, -1
	     envi_file_query, id, ns=ns, nl=nl, nb=nb, h_map=maph,	$
			      interleave=interleave, data_type=type,	$
			      xstart=xstart, ystart=ystart
	     handle_value, maph, mapinfo

	     tmp={fileInfo, ns:ns, nl:nl, nb:nb, map:mapinfo,		$
			      interleave:interleave, type:type,	$
			      xstart:xstart, ystart:ystart}

	     if n_elements(list) ne 0 then begin
		list=[[list], [tmp]]
	     endif else list=[tmp]

	endfor

	return, list
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	MAIN PROGRAM
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro convtobyt, meta, ndvi=ndvi

openr, metaun, /get, meta
nimgs=getNumberOfImages(metaun)
names=getImageNames(metaun, nimgs)
close, metaun	& free_lun, metaun

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;this is where we do most of the interesting stuff
fileInfo=getImageInfo(names, nimgs)
if n_elements(fileInfo) lt 2 then begin 
   print, 'ERROR -1', names
   return
endif

for i=0, nimgs-1 do begin
    info=fileInfo(i)
    line=make_array(info.ns, type=info.type)

    newline=bytarr(info.ns)

    openr, un, /get, names(i)
    openw, oun, /get, string(names(i), '.byt')

    for j=0, info.nl-1 do begin
    for k=0, info.nb-1 do begin
	readu, un, line
	       if keyword_set(ndvi) then begin
		  index=where(line lt 0)
		  if index(0) ne -1 then $
		     line(index) = 0
		  index=where(line gt 1)
		  if index(0) ne -1 then $
		     line(index) = 1
		  newline=byte(line*255)
		endif else newline=byte(line)

	writeu, oun, newline
    endfor
    endfor
    
    close, oun, un	& free_lun, oun, un

;; we can delete files as we go, but until I know this works it is a dangerous
;; option
;    envi_open_file, r_fid=fid, names(i)
;    envi_file_mng, id=fid, /remove, /delete

endfor

end