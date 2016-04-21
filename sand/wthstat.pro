;;Read a single line of data from the .wth file designated
;;by unit. ON ERROR return, -1
function nextline, unit
	s=''

	if eof(unit) then return, -100

	readf, unit, s
	j=str_sep(s, ' ')
	line=j(where(j ne j(1)))
	
	if n_elements(line) ne 14 then begin
		print, 'oops'
		return, -100
	endif

	linevals=fltarr(12)
	tmp=0.
	for i=0,11 do begin
		reads, line(i+2), tmp
		linevals(i) = tmp
	endfor

	return, linevals
end


FUNCTION days_in_month, month, year
  case month of
     1 : days=31
     2 : days=(year mod 4 eq 0)? 29 : 28
     3 : days=31
     4 : days=30
     5 : days=31
     6 : days=30
     7 : days=31
     8 : days=31
     9 : days=30
     10: days=31
     11: days=30
     12: days=31
     else  : return, -1
  endcase
  return, days
end


;; compute the same statistics from a daycent .wth file
function daycentStats, fname
  tmaxdex=4
  tmindex=5
  precdex=6

  j=load_cols(fname, data)
  results=fltarr(12,4,3)

  firstyear= data[2,0]
  lastyear = data[2,n_elements(data[0,*])-1]
  n_years = lastyear - firstyear
  precdata=fltarr(n_years)

  for i=0,11 do begin

     for j=0, n_years-1 do begin
        monthDex=where(data[1,*] eq i+1 and $
                    data[precdex,*] ne -99.9 and $
                    data[2,*] eq firstyear+j)
        if monthdex[0] ne -1 then begin
           precdata[j]= total(data[precdex,monthDex])
        endif
     endfor

     monthDex=where(data[1,*] eq i+1 and data[tmindex,*] ne -99.9)
     if monthdex[0] ne -1 then begin
        tmindata=data[tmindex,monthdex]
     endif
     monthDex=where(data[1,*] eq i+1 and data[tmaxdex,*] ne -99.9)
     if monthdex[0] ne -1 then begin
        tmaxdata=data[tmaxdex,monthdex]
     endif

     
     if n_elements(precdata) gt 2 then $
       results[i,*,0]  = moment(precdata) $
     else return, -1
     if n_elements(tmindata) gt 2 then $
       results[i,*,1]  = moment(tmindata) $
     else return, -1
     if n_elements(tmaxdata) gt 2 then $
       results[i,*,2]  = moment(tmaxdata) $
     else return, -1
     
  endfor
  ;convert variance to stdev
  results[*,1,*] =   sqrt(results[*,1,*])

;;	Century only needs mean,stdev,skew for prec and means for tmin and tmax
;;	so we will subset  result for just those values
  subres=fltarr(12,5)
  subres(*,0:2) = results(*,0,0:2)
  subres(*,3) = results(*,1,0)
  subres(*,4) = results(*,2,0)
  resized=fltarr(60)
  resized(*)=subres(*,*)
  return, resized
end


;;Calculates total statistics from a .wth file.  These are used to create 
;;	stochastic weather in the Century model spin-up period.  
function wthstat, fname, daycent=daycent

	if (findfile(fname))(0) ne fname then return, -1

        if keyword_set(daycent) then return, daycentStats(fname)
	openr, un, /get, fname
	
	;;read in data from the file fname
	tmp = nextline(un)
	if tmp(0) eq -100 then return, -1
	precdat=tmp
	tmp = nextline(un)
	if tmp(0) eq -100 then return, -1
	tmindat=tmp
	tmp = nextline(un)
	if tmp(0) eq -100 then return, -1
	tmaxdat=tmp


	while not eof(un) do begin
		tmp = nextline(un)
		if tmp(0) eq -100 then return, -1
		precdat = [[precdat],[tmp]]
		tmp = nextline(un)
		if tmp(0) eq -100 then return, -1
		tmindat = [[tmindat],[tmp]]
		tmp = nextline(un)
		if tmp(0) eq -100 then return, -1
		tmaxdat = [[tmaxdat],[tmp]]
	endwhile
	free_lun, un

	result=fltarr(12,4,3)

	;;get basic statistics for each month ignoreing null values
	for i=0,11 do begin
          dex=where(precdat(i,*) ne -99.99)
          if dex(0) eq -1 then return, -1
          result(i,*,0) = moment(precdat(i,dex))

          dex=where(tmindat(i,*) ne -99.99)
          if dex(0) eq -1 then return, -1
          result(i,*,1) = moment(tmindat(i,dex))

          dex=where(tmaxdat(i,*) ne -99.99)
          if dex(0) eq -1 then return, -1
          result(i,*,2) = moment(tmaxdat(i,dex))
	endfor

	;; convert variance to stdev
	result(*,1,0) = sqrt(result(*,1,0))

;;	Century only needs mean,stdev,skew for prec and means for tmin and tmax
;;	so we will subset  result for just those values
	subres=fltarr(12,5)
	subres(*,0:2) = result(*,0,0:2)
	subres(*,3) = result(*,1,0)
	subres(*,4) = result(*,2,0)
	resized=fltarr(60)
	resized(*)=subres(*,*)
	return, resized
end
