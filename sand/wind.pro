pro wind, windbinary, out

openr, un, /get, windbinary
openw, oun, /get, out

wind={windfile, PO:'  ',$
	wban:0l, $
	name:'                        ', $
	param:'    ', $
	to:0b, $
	year:intarr(1), $
	data:intarr(372), $
	mean:intarr(13), $
	maxs:intarr(13), $
	mins:intarr(13)}

readu, un, wind
curname=wind.name
curparam=wind.param

curcount=0l
mcurcount=0l
curval=ulong64(0)
mcurval=ulong64(0)

data=wind.data
byteorder,data
index=where(data gt 0)
if n_elements(index) gt 1 then begin
   curcount=n_elements(index)
   curval=total(data(index))
   curval=ulong64(curval)	;;unsigned 64-bit ensures we don't overflow, I hope
endif

dat=wind.maxs
byteorder, dat
index=where(dat gt 0 and dat lt 500)
if index(0) ne -1 then begin
   mcurcount=n_elements(index)
   mcurval=total(dat(index))
   mcurval=ulong64(mcurval)	;;unsigned 64-bit ensures we don't overflow, I hope
endif


while not eof(un) do begin
	readu, un, wind

;;if we are in the same data group continue gathering data
	if wind.name eq curname and wind.param eq curparam then begin
		data=wind.data
		byteorder, data

		index=where(data gt 0)
		if n_elements(index) gt 1 then begin
			curcount=curcount+n_elements(index)
			curval=curval+total(data(index))
		endif

		dat=wind.maxs
		byteorder, dat
;		plot, dat/24., yrange=[0,50]
;		xyouts, 2, 40, wind.name
		index=where(dat gt 0 and dat lt 500)
		if index(0) ne -1 then begin
			mcurcount=mcurcount+n_elements(index)
			mcurval=mcurval+total(dat(index))
		endif

;;else this is a new data group, so we will write data to disk and start over
	endif else begin
		curval = curval/double(curcount)
		curval = curval/24.
		if n_elements(curval) gt 1 then begin
		   print, n_elements(curval)
		   curval=mean(curval)
		endif
		mcurval = mcurval/double(mcurcount)
		mcurval = mcurval/24.
		if n_elements(mcurval) gt 1 then begin
		   print, n_elements(mcurval)
		   mcurval=mean(mcurval)
		endif

;;one meter = 0.00062 miles  one sec= 1/3600 hours : mile/hr = 1/3600 * 0.00062 = 0.45
		curval = curval*0.45
		mcurval=mcurval*0.45
		printf, oun, curname, curparam, curval, curcount, mcurval, mcurcount
		
		curcount=0l
		mcurcount=0l
		curval=wind.data
		byteorder, curval
		index=where(curval gt 0)
		if n_elements(index) gt 1 then begin
			curcount=n_elements(index)
			curval=total(curval(index))
			curval=ulong64(curval)
		endif			

		curparam=wind.param
		curname=wind.name

		dat=wind.maxs
		byteorder, dat
		index=where(dat gt 0 and dat lt 500)
		if index(0) ne -1 then begin
			mcurcount=mcurcount+n_elements(index)
			mcurval=mcurval+total(dat(index))
		endif

	endelse
endwhile

close, un, oun
free_lun, un, oun

end
