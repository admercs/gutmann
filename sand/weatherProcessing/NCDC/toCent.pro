pro MakeKeyFile, stnFile, startYr, names, keyFile
  if n_elements(keyFile) eq 0 then keyFile='full.key'

  openr, un, /get, stnFile
  openw, oun, /get, keyFile

  line=''

;; Skip the header
  readf, un, line &  readf, un, line

  for i=0, n_elements(names)-1 do begin
    readf, un, line
    thisname=strcompress(strmid(line, 16,29), /remove_all)

    while not strcmp(thisname,names(i)) do begin
      readf, un, line
      thisname=strcompress(strmid(line, 16,29), /remove_all)
    endwhile

; read info from this line of the file
    lat=strsplit(strmid(line, 136,6),':',  /extract)
    lon=strsplit(strmid(line, 148,9),':',  /extract)

;Calculate latitude and Longitude, assumes we are in the North-West
;hemisphere
    lat = 100*fix(lat(0)) + fix(lat(1))
    lon = 100*fix(lon(0)) - fix(lon(1))

    if strlen(thisname) gt 14 then thisname=strmid(thisname,0,14)
; Write output to file
    printf, oun, thisname+'.wth', lat, lon, startYr(i)
 
  endfor
  close, oun, un
  free_lun, oun, un
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Read the first data segment, counting the number of lines
;;  necessary for an entire data segment and moving the file pointer
;;  to the beginning of the next data segment.  Then return the data
;;  and year for the first segment in the named variables given
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro readFirst, un, maxT, minT, prec, name, year

  yearoffset=6

;; set up initial variables
  maxT=replicate(-99.99,12)
  minT=replicate(-99.99,12)
  prec=replicate(-99.99,12)
  line=' '
  dataDex = (indgen(12)*5) + yearoffset+5

;;read basic information about this segment.  e.g. name and year
  point_lun, (-1*un),location ;negative unit number GETS location?
  readf, un, line
  line=strsplit(line, ',', /extract)
  name=strcompress(line(yearoffset-4),/remove_all)
  cur_name=name
  year=fix(line(yearoffset))
  cur_year=year

;reset file to initial position
  point_lun, un, location

; Read and process the data
  while (year eq cur_year) and strcmp(name, cur_name) and not eof(un) do begin
    line=' '
    readf, un, line
    line=strsplit(line, ',', /extract)

    cur_name=strcompress(line(2),/remove_all)
    type=line(yearoffset-2)
    cur_year=fix(line(yearoffset))

    if (year eq cur_year) and strcmp(name, cur_name) then begin
      point_lun, (-1*un),location
      case type of 
        'MMNT': minT = (float(line(dataDex)) -320)/18 ;tenths of degrees F to 
        'MMXT': maxT = (float(line(dataDex)) -320)/18 ; degrees C
        'TPCP': prec = float(line(dataDex))  * 0.0254 ;0.01in = 0.0254 cm
        else:
      endcase
    endif

  endwhile

  badDex = where(minT lt -5000)
  if badDex(0) ne -1 then          minT(badDex) = -99.99
  badDex = where(maxT lt -5000)
  if badDex(0) ne -1 then          maxT(badDex) = -99.99
  badDex = where(prec lt -2000)
  if badDex(0) ne -1 then          prec(badDex) = -99.99
  
;; reset the location to the previous line
  if not eof(un) then $
    point_lun, un, location
end

;;;;;;;;;;;;;;;;;;;;;;
;;
;; write a century .wth file based on the data collected.  
;;
;;;;;;;;;;;;;;;;;;;;;;
pro writeWTHfile, fname, tMax, tMin, prec, startyr, nyears

;; presumably this is a limitation of CENTURY?
  if strlen(fname) gt 14 then fname=strmid(fname,0,14)
  
  openw, oun, /get, fname
  for i=0, nyears-1 do begin
    printf, oun, 'prec  '+strcompress(string(startyr+i),/remove_all) $
            + strjoin(string(format='(F7.2)', prec(*,i)))
    printf, oun, 'tmin  '+strcompress(string(startyr+i),/remove_all) $
            + strjoin(string(format='(F7.2)', tMin(*,i)))
    printf, oun, 'tmax  '+strcompress(string(startyr+i),/remove_all) $
            + strjoin(string(format='(F7.2)', tMax(*,i)))
  endfor

  close, oun
  free_lun, oun
end
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Main Program
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro toCent, datFile, stnFile, keyFile=keyFile
  if n_elements(datFile) eq 0 then begin
    datFile=(findfile('*dat.txt'))(0)
    stnFile=(findfile('*stn.txt'))(0)
  endif else if n_elements(stnFile) eq 0 then begin
    stnFile=(findfile('*stn.txt'))(0)
  endif

  startyr=0
  names=' '
  openr, un, /get, datFile
  
  line=''

; skip the header
  readf, un, line & readf, un, line
  
  readFirst, un, maxT, minT, prec, new_name, year
  while not eof(un) do begin
    
    station_name=new_name
    i=0
    
    readFirst, un, new_maxT, new_minT, new_prec, new_name, new_year
    last_year=new_year
;    if not strcmp(new_name, station_name) then startyr=[startyr
    while strcmp(new_name,station_name) and not eof(un) do begin
       
       while new_year gt last_year+1 do begin
;        print, 'missing year!', new_year, year(i)
          maxT=[[maxT],[replicate(-99.99,12)]]
          minT=[[minT],[replicate(-99.99,12)]]
          prec=[[prec],[replicate(-99.99,12)]]
          year=[year,year(i)+1]
          i=i+1
          last_year=last_year+1
       endwhile
       last_year=new_year
       
       if new_year gt 1998 and new_year lt 2002 then begin
          if n_elements(where(new_maxT eq -99.99)) gt 1 or $
            n_elements(where(new_minT eq -99.99)) gt 1 or $
            n_elements(where(new_prec eq -99.99)) gt 1 then $
            
          new_year=-99
       endif
       
       maxT=[[maxT],[new_maxT]]
       minT=[[minT],[new_minT]]
       prec=[[prec],[new_prec]]
       year=[year,new_year]
       i=i+1
       
       readFirst, un, new_maxT, new_minT, new_prec, new_name, new_year
       if new_year eq -99 then i=j
       if last_year eq -99 then i=j
       
    endwhile
    print,' exit ',station_name
    index=where(year eq -99) ;;this is our error check
;    print, n_elements(year), index(0)
    if index(0) eq -1 and $
      n_elements(year) gt 20 and $
      year(n_elements(year)-1) eq 2002 then begin
       
       writeWTHfile, station_name+'.wth', maxT, minT, prec, year(0), n_elements(year)
       startyr = [startyr,year(0)]
       names=[names,station_name]
;      print, 'saving'
    endif 
    
;; set up the next iteration
    maxT=new_maxT
    minT=new_minT
    prec=new_prec
    year=new_year
 endwhile  
 startyr=startyr(1:n_elements(startyr)-1)
 names=names(1:n_elements(names)-1)
 
 MakeKeyfile, stnFile, startyr, names, keyFile
end

