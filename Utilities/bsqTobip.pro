pro bsqTobip, img, ns, nl, nb, out, type=typeif not keyword_set(type) then type=1openr, un, /get, imgopenw, oun, /get, outtypeLUT=[0,1,2,4,4,8,8]tsz=typeLUT(type)imsz=long(ns)*nlcurline = make_array(nb, ns, type=type)tmpline = make_array(ns, type=type)for j=0, nl-1 do begin	for i=0, nb-1 do begin		point_lun, un, long(tsz)*(i*imsz + long(j)*ns) 		readu, un, tmpline		curline(i,*) = tmpline	endfor	writeu, oun, curlineendforclose, oun, unfree_lun, oun, unend