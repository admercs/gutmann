pro monmeanmax, data

	i=load_cols(data, wind)

	j=wind(0,*) + float(wind(1,*))/12
	k=j+double(wind(2,*))/(31*12)

	initj=j(0)
	initk = k(0)

	curmo = fltarr(31)
	daily = 0.
	count=0
	i=0
	totcount=0l
	total=ulong64(0)

	for ck=0l, n_elements(k)-1 do begin

		if k(ck) eq initk then begin
			if wind(4,ck) ne 9 then begin	;;bad data label
				daily=daily+wind(4,ck)
				count=count+1
			endif
		endif else begin
			if count ne 0 then begin
				curmo(i) = daily/count
			endif
			count=0
			daily=0.
			i=i+1
			initk = k(ck)
			if wind(4,ck) ne 9 then begin
				count=count+1
				daily = wind(4,ck)
			endif
		endelse

		if j(ck) ne initj then begin
			total = total+ulong64(max(curmo))
			i=0
			if ulong64(max(curmo)) ne 0 then begin
				totcount = totcount+1
			endif
			curmo(*) = 0.
			initj=j(ck)
		endif

	endfor


	print, (total)/double(totcount)

end