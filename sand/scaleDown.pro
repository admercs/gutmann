;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	Reads an enviheader file.  ;;	    returns a struct :;;		    ns:number of samples in the file;;		    nl:number of lines in the file;;		    nb:number of bands in the file;;		    map: an envi map structure (includes utm coords and pixelsize);;		    desc: The description field in the .hdr;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;function getFileInfo, name	 envi_open_file, name, r_fid=id	 	 if id eq -1 then return, {errorstruct, name:name, ns:-1, nl:-1, nb:-1}	 envi_file_query, id, nb=nb, nl=nl, ns=ns, h_map=maph, descrip=desc, $	 	interleave=interleave, data_type=type	 handle_value, maph, map	 envi_file_mng, id=id, /remove	 return, {imagestruct, name:name, ns:ns, nl:nl, nb:nb, map:map, desc:desc, $	 	interleave:interleave, type:type}end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	Sets envi header info (map and ns, nl, nb, type, interleave);;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;pro setsandHdr, info, fname	envi_setup_head, fname=fname, ns=info.ns, nl=info.nl, nb=info.nb, $		interleave=info.interleave, data_type=info.type, $		descrip=info.desc, map_info=info.map, /writeend	function scaleDown, input, output, scaleFactor	envistart	info=getFileInfo(input)	if info.ns eq -1 then begin		print, 'Scale Down ERROR: ', input,' does not exist'		return,-1	endif				if info.interleave ne 0 and info.nb gt 1 then begin		print, 'ERROR scaling ', input, ' image'		print, '   Can not use non-BSQ formated files with more than one band'		return, -1	endif		imgLine=make_array(info.ns, scalefactor, type=info.type)		newnl=info.nl/scaleFactor	newns=info.ns/scaleFactor	newline = make_array(newns, type=info.type)		openr, un, /get, input	openw, oun, /get, output		for k=0, info.nb-1 do begin	for i=0, newnl-1 do begin		readu, un, imgLine		newline(*) = 0				for j=0, newns-1 do begin			window=imgline(j*scaleFactor:((j+1)*scaleFactor-1), *)			index=where(window ne 0)			if index(0) ne -1 then $				newline(j) = mean(window(index))		endfor				writeu, oun, newline	endfor	endfor			close, oun, un	free_lun, oun, un		info.ns=newns	info.nl=newnl	map=info.map	map.ps = map.ps * scalefactor	info.map=map	info.interleave=0	setsandHdr, info, output		return, 1end