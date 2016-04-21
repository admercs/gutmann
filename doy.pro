pro julian, day, mon, yr
  if n_elements(yr) eq 0 then yr=1
  if strlen(strcompress(mon, /remove_all)) lt 3 then begin
    print, 'You entered : ', mon, ' : for the month'
    return
  endif

  oldmon=mon
  mon = strlowcase(mon)
  mon = strmid(mon, 0, 3)

  case mon of
     'jan' : base=0
     'feb' : base=31
     'mar' : base=59
     'apr' : base=90
     'may' : base=120
     'jun' : base=151
     'jul' : base=181
     'aug' : base=212
     'sep' : base=243
     'oct' : base=273
     'nov' : base=304
     'dec' : base=334
     else  : begin
        print, 'You entered : ', oldmon, ' for the month.'
        return
     endelse
  endcase
  if ((yr mod 4) eq 0) and (mon ne 'jan') and (mon ne 'feb') then base=base+1
  
  print, base+day
end

pro julianFromNum, day, mon, yr
  if n_elements(yr) eq 0 then yr=1
  if mon  gt 12 then begin
    print, 'You entered : ', mon, ' : for the month'
    return
  endif

  case mon of
     1 : base=0
     2 : base=31
     3 : base=59
     4 : base=90
     5 : base=120
     6 : base=151
     7 : base=181
     8 : base=212
     9 : base=243
     10 : base=273
     11 : base=304
     12 : base=334
     else  : begin
        print, 'You entered : ', mon, ' for the month.'
        return
     endelse
  endcase
  if ((yr mod 4) eq 0) and (mon le 2) then base=base+1
  
  print, base+day
end

FUNCTION getDOY, day, mon, yr
  if n_elements(yr) eq 0 then yr=1
  if mon  gt 12 then begin
    print, 'You entered : ', mon, ' : for the month'
    return, -1
  endif

  case mon of
     1 : base=0
     2 : base=31
     3 : base=59
     4 : base=90
     5 : base=120
     6 : base=151
     7 : base=181
     8 : base=212
     9 : base=243
     10 : base=273
     11 : base=304
     12 : base=334
     else  : begin
        print, 'You entered : ', mon, ' for the month.'
        return, 0
     endelse
  ENDCASE

;; leap year calculation (good for a few thousand years
;;   so I won't worry about it just yet)
  IF ((yr mod 4) eq 0) and (mon le 2) then BEGIN
     base=base+1
     IF ((yr MOD 100) EQ 0) AND ((year MOD 400) NE 0) THEN base=base-1
  ENDIF  
  return, base+day
end


pro doy, day, mon

  if n_elements(mon) GT 0 then begin
    julian, day, mon
    return
  endif

  if day lt 32 then begin
    print, 'January : ', strcompress(string(day))
    return
  endif
  if day lt 60 then begin
    print, 'February : ', strcompress(string(day-31))
    return
  endif
  if day lt 91 then begin
    print, 'March : ', strcompress(string(day-59))
    return
  endif
  if day lt 121 then begin
    print, 'April : ', strcompress(string(day-90))
    return
  endif
  if day lt 152 then begin
    print, 'May : ', strcompress(string(day-120))
    return
  endif
  if day lt 182 then begin
    print, 'June : ', strcompress(string(day-151))
    return
  endif
  if day lt 213 then begin
    print, 'July : ', strcompress(string(day-181))
    return
  endif
  if day lt 244 then begin
    print, 'August : ', strcompress(string(day-212))
    return
  endif
  if day lt 274 then begin
    print, 'September : ', strcompress(string(day-243))
    return
  endif
  if day lt 305 then begin
    print, 'October : ', strcompress(string(day-273))
    return
  endif
  if day lt 335 then begin
    print, 'November : ', strcompress(string(day-304))
    return
  endif
  if day lt 366 then begin
    print, 'December : ', strcompress(string(day-334))
    return
  endif
end

  
