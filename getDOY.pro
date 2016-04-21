;; Returns the Day Of the Year given a numerical day, month, year
;;   if year is not included then it is assumed NOT to be a leap year
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
        return, -1
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
