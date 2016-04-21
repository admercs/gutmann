;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; moderate sobel edge in green = 30, nir=30, ndvi=100function checkPointFull, ndvi, img, edgemap, filter, penalty	;;filter is ?*3*2	h=size(ndvi) &	ns = h(1) &	nl = h(2)	h=size(filter) 	&	n=h(1)	newedgemap=edgemap		totalmisses = 0l &	totalhits=0l &	currentmisses=0l &	currenthits=0l	bigmisses=0l	x=intarr(3)	y=intarr(3)	for i=0, n-1 do begin		x=filter(i,*,0)				y=filter(i,*,1)		if edgemap(x(1),y(1)) eq 10 and edgemap(x(0),y(0)) eq 0 then begin			totalhits=totalhits+1			currenthits=currenthits+1			if currenthits gt 1 then currentmisses=0		endif $		else if edgemap(x(2),y(2)) eq 10 and edgemap(x(1),y(1)) eq 0 then begin			totalhits=totalhits+1			currenthits=currenthits+1			if currenthits gt 1 then currentmisses=0		endif $		else begin			totalmisses=totalmisses+1			currentmisses=currentmisses+1			if currentmisses gt 4 then currenthits=0			if currentmisses gt 3 and currenthits ne 0 then bigmisses=bigmisses+1;;;;;;;;;;;;;;;;;;;;;;;;;	Note, this worked well when I left the initial if statement to currentmisses gt 1;;		ie, we never count big misses, we might be penalizeing too much now.;;;;;;;;;;;;;;;;;;;;;;;				endelse		if currenthits gt 0 then newedgemap(x(1), y(1))=20;	tvscl, newedgemap, 0	endfor	return, fix(totalhits-totalmisses-(penalty*bigmisses))end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;function dist, a, b	a=float(a)	return, sqrt(float((a(0)-b(0))^2) + (a(1)-b(1))^2)end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;function find_point_at_dist_rad, center, dist, angle	x=byte(center(0) + (cos(angle) * dist))	y=byte(center(1) + (sin(angle) * dist))	return, [x,y]end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;function createEdgeSearch, size	nsrchs=size*4		;;this is the number of angles we will search around the circle	filter=bytarr(nsrchs, 3, 2)	;;the filter will store three x,y locations in a line from				;; the center	d=size/2	cx=(size/2)+1	cy=(size/2)+1	radIncrement = (2.*!PI)/nsrchs	for i=0, nsrchs-1 do begin		loc=find_point_at_dist_rad([cx, cy], d-1, (radIncrement*i))		filter(i, 0, *)=loc		loc=find_point_at_dist_rad([cx, cy], d, (radIncrement*i))		filter(i, 1, *)=loc		loc=find_point_at_dist_rad([cx, cy], d+1, (radIncrement*i))		filter(i, 2, *)=loc	endfor	return, filterend;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;function initSearch, ndvi, threshold, size	h=size(ndvi)	ns = h(1)	nl = h(2)	halfsize=(size+6)/2	circles=intarr(ns, nl);; first order search that tells us where to look more closely;; quarter circle should be about 175 pixels, half=350, full=700	for i=halfsize, ns-halfsize-1 do begin	for j=halfsize, nl-halfsize-1 do begin		lowx=i-halfsize+2 & hix=i+halfsize-1		lowy=j-halfsize+2 & hiy=j+halfsize-1		circles(i,j) = n_elements(where(ndvi(lowx:hix, lowy:hiy) ge threshold))	endfor	endfor	return, circlesend;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;function createNDVIbyte, img	h=size(img)	ns = h(1)	nl = h(2)	tmpndvi=fltarr(ns, nl)	tmpndvi=(Float(img(*,*,3))-img(*,*,2))/(Float(img(*,*,3))+img(*,*,2))	if max(tmpndvi) gt 1 then $		tmpndvi(where(tmpndvi gt 1)) = 1	if min(tmpndvi) lt 0 then $		tmpndvi(where(tmpndvi lt 0)) = 0	ndvi=bytarr(ns, nl)	ndvi=byte(tmpndvi*250)	tmpndvi=bytarr(1)	return, ndviend;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;function findALLedges, ndvi, img, ndvithresh, imgthresh	h=size(img)	ns=h(1)	nl=h(2)	nb=h(3)	sob=sobel(ndvi)	sobf=intarr(nl,ns,nb)	for i=0, nb-1 do begin		tmp=sobel(img(*,*,i))		sobf(*,*,i) = tmp	endfor	;tvscl, sobf(*,*,1)	tmp = bytarr(1)	edgemap=bytarr(ns, nl)	edgemap(where(sob ge ndvithresh)) = 10	edgemap(where(sobf(*,*,0) ge imgthresh)) = 10	edgemap(where(sobf(*,*,1) ge imgthresh)) = 10	edgemap(where(sobf(*,*,2) ge imgthresh)) = 10	return, edgemapend;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;function make_circle_filter, size	nsize=fix(size+5)	newfilter=intarr(nsize, nsize)	for i=0, nsize-1 do begin		for j=0, size-1 do begin			d=(fix(dist([i,j],[nsize/2, nsize/2])) - nsize/2)			if d le -2 then $				newfilter(i,j)=-1		endfor	endfor	return, newfilterend;make_circle_array;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;function findcenters, map, threshold	index = where(map gt threshold)		x = index mod 1000	y = index / 1000		return, transpose([[x],[y]])end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	returns a score based on how accurate the current map is;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;function test, map, locs, locunit	;	newmap=lonarr(400,400);	newmap(101:300,101:300) = map	newmap = map	score = 0	threshold = 1000	search = 10		locations = locs+3;	index = where(locations(0,*) gt 10 and locations(0,*) lt 990 and $;				locations(1,*) gt 10 and locations(1,*) lt 990);	if index(0) ne -1 then begin;		locations = locations(*,index);	endif else return, -1		avePiv = 0.	totPivs = n_elements(locations(0,*))	allvals=lonarr(totPivs)		;;find the ideal threshold for this image (find all pivots, errors of commision are allowed)	for i=0, totPivs-1 do begin		x = locations(0,i)		y = locations(1,i)				curval= max(newmap(x-search:x+search,y-search:y+search));		print, curval, threshold		threshold = min([threshold, curval])		avePiv = avePiv+curval						;print, 'Current pivot =',curval	endfor			avePiv= avePiv/totPivs			print, 'Threshold for this map=',threshold		index = where(newmap lt -150)	newmap(index) = -150		index = where(newmap gt threshold and newmap ne 0)	;;if no where in the image is registered as a pivot then quit	if index(0) eq -1 then return, [float(score), 0.,0.,float(threshold), float(max(map)), avePiv]		;tvscl, newmap,0	for i=0l, n_elements(index)-1 do begin						x = index(i) mod 1000		y = index(i) / 1000				windowmax = max(newmap(x-search:x+search,y-search:y+search)) 		windowindex = where(newmap(x-search:x+search,y-search:y+search) eq windowmax)		if newmap(index(i)) lt windowmax then begin;			print, 'got one'			newmap(index(i)) = -200		endif else if n_elements(windowindex) gt 1 then begin			for j=1, n_elements(windowindex)-1 do begin				tmpx = x - search + (windowindex(j) mod (search*2)+1)				tmpy = y - search + (windowindex(j)  /  (search*2)+1)								newmap(x,y) = -200			endfor		endif	endfor	;tvscl, newmap,1	currentlocs = findcenters(newmap, threshold)	index = where(currentlocs(0,*) gt 10 and currentlocs(0,*) lt 990 and $				currentlocs(1,*) gt 10 and currentlocs(1,*) lt 990)	currentlocs = currentlocs(*,index)	printf, locunit, [-99,-99]	printf, locunit, currentlocs	print, n_elements(currentlocs(0,*))			tmp = newmap	tmp(*,*) = 0			scores = bytarr(max([n_elements(locations),n_elements(currentlocs)]),2)	print, 'there should be', n_elements(locations(0,*)), ' pivots'	for j=0, n_elements(currentlocs(0,*))-1 do begin		curx = currentlocs(0,j)		cury = currentlocs(1,j)				if curx ne -1 then $			tmp(curx,cury) = 255	for k=0l, n_elements(locations(0,*))-1 do begin					checkX = locations(0,k)		checkY = locations(1,k)							if curx lt checkX+search and curx gt checkX-search and $			cury lt checkY+search and cury gt checkY-search then begin	;; j keeps track of which pivots that we detected were real							scores(j,0) = 1	;; k keeps track of which of the real pivots we managed to find			scores(k,1) = 1		endif	endfor	endfor		;tv, tmp	score = total(scores(*,0))	gottem = total(scores(*,1))		return, [float(score), float(gottem), float(n_elements(currentlocs(0,*))),float(threshold), float(max(map)), avePiv]end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;pro findcrops, imgF, outF, ns, nl, nb, pivotfile;;searches for standard (~25? pixel diameter) crop circles, halves, and quarters	search_size=25;;for my testing ease	if n_elements(imgF) eq 0 then imgF='200.bsq'	if n_elements(outF) eq 0 then outF='tmpout'	if n_elements(ns) eq 0 then ns=200	if n_elements(nl) eq 0 then nl=200	if n_elements(nb) eq 0 then nb=4;; reads in the image file, for now we will assume we can read the entire img at once;;	also assumes byte bsq files	openr, iun, /get, imgF 	img=bytarr(ns,nl,nb) &	readu, iun, img	close, iun &			free_lun, iun	openw, o1un, /get, outF	openw, o2un, /get, string(outF+'.other')	openw, o3un, /get, string(outF+'.best')	openw, o4un, /get, string(outF+'.results')	ndvi=createNDVIbyte(img)	locations = load_cols(pivotfile, locs)	locations = locs(1:2,*)	;	locations = [[61,29],[60,56],[88,57],[88,85],[60,82],[33,82],[141,113],$;		[167,114],[168,60],[33,136],[87,164]];[168,88],	;	for search_size=24., 26., 0.1 do begin		halfsize=(search_size+6)/2		filter=createEdgeSearch(search_size)		centerfilter=make_circle_filter(search_size)		othermap=lonarr(ns, nl)	;;initial search to minimize the number of places we need to search in the end		circles=initSearch(ndvi, 100, search_size)	;;initially using 125		quartercirclearea=fix(!pi*(halfsize^2)/4)		print, 'quarter circle area=', quartercirclearea		full_Index=where(circles gt quartercirclearea)		full_Size=n_elements(full_Index);	for penalty=0,20 do begin	;;initially 10... err 0;	for edgethresh=10, 20 do begin		edgethresh = 20		penalty = 1		print, search_size, edgethresh, penalty		edgemap=findALLedges(ndvi, img, edgethresh*10, edgethresh*3)		newmap=make_array(ns, nl, type=2, value=-1000)		markerinterval= full_Size /10		tmpmark=0		;tvscl, ndvi, 0		;tvscl, edgemap, 1		bms = 0						for i=0l, full_Size-1 do begin			x=(full_Index(i) mod ns)-1 &	y=(full_Index(i)  /  ns)-1			xlow=x-halfsize+1 & xhi=x+halfsize 	   &	ylow=y-halfsize+1 & yhi=y+halfsize						tmpmapval = checkPointFull( ndvi(xlow:xhi, ylow:yhi),	$				img(xlow:xhi, ylow:yhi, *),		$				edgemap(xlow:xhi, ylow:yhi, *),		$				filter, penalty)			newmap(full_Index(i)) = tmpmapval						if i/markerinterval gt tmpmark then begin				tmpmark=i/markerinterval				print, tmpmark, i			endif			othermap(full_Index(i))=total(edgemap(xlow:xhi, ylow:yhi) * centerfilter)			endfor				i=min(newmap(where(newmap eq -1000)))		newmap(where(newmap eq -1000)) = i-10		writeu, o1un, fix(newmap)		writeu, o2un, fix(othermap)		newmap=temporary(newmap)+(othermap/100) ;;this subtracts for any internal edges		writeu, o3un, fix(newmap);		tmpresults = test(newmap, locations);		print, 'Total pivots ? - real pivots found, threshold, max threshold, ave threshold';		print, tmpresults;		writeu, o4un, tmpresults;	endfor;	endfor;	endfor	close, o1un, o2un, o3un, o4un	free_lun, o1un, o2un, o3un, o4unend;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;pro testcrops, FCoutput, resultfile, pivotfile, locfile;	locations = [[61,29],[60,56],[88,57],[88,85],[60,82],[33,82],[141,113],$;		[167,114],[168,60],[33,136],[87,164]]	locations = load_cols(pivotfile, locs);	if locations eq -1 then return;	locations = locs(1:2,*)	locations = locs		openr, un, /get, FCoutput	data=intarr(1000,1000,231)	openw, locun, /get, locfile		readu, un, data	close, un & free_lun, un		results = fltarr(6,11,21)		for i=0, 230 do begin		results(*,i mod 11, i/11) = test(data(*,*,i), locations, locun)	endfor		openw, oun, /get, resultfile	writeu, oun, results	close, oun & free_lun, oun	end