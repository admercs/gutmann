;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	Reads an enviheader file.  ;;	    returns a struct :;;		    ns:number of samples in the file;;		    nl:number of lines in the file;;		    nb:number of bands in the file;;		    map: an envi map structure (includes utm coords and pixelsize);;		    desc: The description field in the .hdr;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;function getFileInfo, name	 envi_open_file, name, r_fid=id	 	 if id eq -1 then return, {errorstruct, name:name, ns:-1, nl:-1, nb:-1}	 envi_file_query, id, nb=nb, nl=nl, ns=ns, h_map=maph, descrip=desc, $	 	interleave=interleave, data_type=type	 if maph eq -1 then return, {errorstruct, name:name, ns:-1, nl:-1, nb:-1}	 	 handle_value, maph, map	 envi_file_mng, id=id, /remove	 return, {imagestruct, name:name, ns:ns, nl:nl, nb:nb, map:map, desc:desc, $	 	interleave:interleave, type:type}end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	Sets envi header info (map and ns, nl, nb, type, interleave);;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;pro setHdr, info, fname	envi_setup_head, fname=fname, ns=info.ns, nl=info.nl, nb=info.nb, $		interleave=info.interleave, data_type=info.type, $		descrip=info.desc, map_info=info.map, /writeend;;searches a list of filenames and returns the name of the largest filefunction largestfile, fileNames	sizeList=lonarr(n_elements(fileNames))	for i=0, n_elements(fileNames)-1 do begin		if file_test(fileNames(i)) then begin			openr, un, /get, fileNames(i)			sizeList(i) = (fstat(un)).size			close, un			free_lun, un		endif	endfor	largest=max(sizeList)	if largest eq 0 then return, -1	index=where(sizeList eq largest)	if index(0) eq -1 then return, -1		return, fileNames(index(0))end;; uses envi to find the number of samples and lines in fname, then opens fname;;	and converts it to ndvi (assumes a 6-7 band landsat image) and writes it to outfnamepro makeByteNDVI, fname, outputdir, outfname		info=getFileInfo(fname)		openr, un, /get, fname		cd, outputdir, current=olddir		if file_test(outfname) then begin		print, 'ERROR: ',outfname,' already exists'		cd, olddir		return	endif		bandoffset = info.ns*info.nl	startpt = bandoffset*2		curline = bytarr(info.ns, 100)	outline = bytarr(info.ns, 100)		openw, oun, /get, outfname	point_lun, un, startpt	curpointer = (fstat(un)).cur_ptr		nruns = info.nl/100	modval = nruns / 10		for i=0, nruns-1 do begin		readu, un, curline		point_lun, un, curpointer + bandoffset		readu, un, outline		if i mod modval eq 0 then $			print, round((float(i)/(nruns-1)) * 100), '%'					outline = ((outline - float(curline))/$				(float(curline) + outline))		index = where(outline lt 0 or outline eq 0/0.)		if index(0) ne -1 then begin			outline(index) = 0		endif				outline = byte(outline * 255)				writeu, oun, outline				curpointer = (fstat(un)).cur_ptr		point_lun, un, curpointer - bandoffset		curpointer = (fstat(un)).cur_ptr	endfor		curline=bytarr(info.ns, info.nl mod 100)	outline=bytarr(info.ns, info.nl mod 100)	readu, un, curline	point_lun, un, curpointer+bandoffset	readu, un, outline	outline = ((outline - float(curline))/$			(float(curline) + outline))	index = where(outline lt 0 or outline eq 0/0.)	if index(0) ne -1 then begin		outline(index) = 0	endif		outline = byte(outline * 255)		writeu, oun, outline			close, oun, un	free_lun, un, oun		info.nb = 1	setHdr, info, outfname		cd, olddirendfunction isAnImage, fname	if file_test(fname) and not file_test(fname, /Directory) then begin		openr, un, /get, fname		size=(fstat(un)).size		close, un		free_lun, un		return, size gt 5000000	endif else return, 0 eq 1end;;searches for a cd in /Volumes/, then searches it for imagery;;	converts images into NDVI images in the current directorypro cdToNDVI	envistart	cd, current=old	cdcd		scenes=file_search('*')	for i=0, n_elements(scenes)-1 do begin		thisScene=(strsplit(scenes(i), ':', /extract))(0)		if file_test(thisScene, /Directory) then begin			cd, thisScene, current=baseDir						print, thisScene			dates=file_search('*')			for j=0, n_elements(dates)-1 do begin				thisDate=(strsplit(dates(j), ':', /extract))(0)				if file_test(thisDate, /Directory) then begin					print, thisDate										cd, thisDate, current=sceneDir					images=findfile('*')					thisImage=largestfile(images)					print, thisImage					if thisImage ne -1 then $						makeByteNDVI, thisImage, old, thisScene+'-'+thisDate								cd, sceneDir				endif else if isAnImage(thisDate) then begin					thisImage = thisDate										print, thisImage, ' NEEDS TO HAVE A FILENAME FIXED!!!!!!!!!!!'					makeByteNDVI, thisImage, old, thisScene+'-'+thisImage							endif			endfor				cd, baseDir		endif	endfor		cd, old	print, '*************************************************************'	print, 'completed ', thisDate	print, '*************************************************************'end