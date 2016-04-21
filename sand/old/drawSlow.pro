pro drawSlow, polygon, ns, nl	if n_elements(ns) eq 0 then begin		ns = max(polygon(0,*)) + 100		nl = max(polygon(1,*)) + 100	endif		sz = n_elements(polygon(0,*))			offsetx = min(polygon(0,*)) - 100	offsety = min(polygon(1,*)) - 100		nns = ns - offsetx	nnl = nl - offsety		img=bytarr(1000, 1000)	xScale = fix(nns / 1000) + 1	yScale = fix(nnl / 1000) + 1		timedelay = 3. / ((sz/20)+1)	window, xsize=1000,ysize=1000	polygon(0,*) = (polygon(0,*)-offsetx)/xscale		polygon(1,*) = (polygon(1,*)-offsety)/yscale			for i=0, sz-1 do begin		plots, polygon(*,0:i), /device	;		img(fix(polygon(0,i)-offsetx)/xScale, fix(polygon(1,i)-offsety)/yScale) = 1;		if i mod 20 eq 0 then begin;			tvscl, img, /order;			wait, timedelay;		endif	endfor;	tvscl, img, /order;	wait, 1;	wdelete	end