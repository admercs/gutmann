;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Parses station data from a single line of text from the stn file
;;    Assumes character spacing in the file is identical to that sent from
;;    NCDC in 2003.  There are no delimiters in that file.  
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION parseStation, line
  stnID   = LONG(STRMID(line, 0, 6))
  stnName = STRCOMPRESS(STRMID(line, 16, 29), /remove_all)

; read Lat Long info 
  lat=STRSPLIT(STRMID(line, 136,6),':',  /extract)
  lon=STRSPLIT(STRMID(line, 148,9),':',  /extract)

;Calculate latitude and Longitude, assumes we are in the North-West
;hemisphere
  lat = 100*FIX(lat(0)) + FIX(lat(1))
  lon = 100*FIX(lon(0)) - FIX(lon(1))

  RETURN, {stnList, stnName:stnName, stnID:stnID, lat:lat, lon:lon}
END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Reads the stn file, returns an array of structures
;;    each structure contains the station name, ID, and location
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION getStationList, stnFile
  OPENR, un, /get, stnFile

  line=''
  READF, un, line  &  READF, un, line
  READF, un, line
  stnList=parseStation(line)

  WHILE NOT EOF(un) DO BEGIN
     READF, un, line
     stnList=[stnlist, parseStation(line)]
  ENDWHILE

  CLOSE, un & FREE_LUN, un
  RETURN, stnList
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Reads a list of filenames from the input file
;;   one filename per line.
;;   Returns an array of filenames
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION getFileNames, filename

; open the file
  OPENR, un, /get, filename

; Initialize variables as strings
  namelist=''
  name=''

; Initialise the list of names
  READF, un, namelist
  
; Read in one line at a time until we get to
;   the end of the file.  
  WHILE NOT EOF(un) DO BEGIN
     readf, un, name

; add the current name to the list
     namelist=[namelist,name]
  ENDWHILE

;clean up
  CLOSE, un & FREE_LUN, un

; and return the resulting array of filenames
  RETURN, namelist
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; sorts a list of filenames by the first year in the file
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION reorder, filelist, inityear
  
  nfiles=n_elements(filelist)
  yrs=intarr(nfiles)

;; read in the first year for each file
  FOR i=1, nfiles-1 DO BEGIN
     line=''
     OPENR, un, /get, filelist[i]
;; skip the file header
     READF, un, line  &   READF, un, line
;; read the first line
     READF, un, line
     
     line=STRSPLIT(line, ',', /extract)
     yrs[i] = FIX(STRMID(line[7], 0,4))
     CLOSE, un  &  FREE_LUN, un
  ENDFOR

;; bubble sort algorithm
;;  while not sorted
;;     examine all pairs of adjacent array elements and exchange
;;     values that are out of order.  
  sorted=0
  pass=0
  WHILE NOT sorted DO BEGIN
     sorted=1
     FOR i=1, nfiles-pass-2 DO BEGIN
        IF yrs[i] GT yrs[i+1] THEN BEGIN
; exchange out of order years
           tmp      = yrs[i]
           yrs[i]   = yrs[i+1]
           yrs[i+1] = tmp

; exchange out of order filenames
           tmp           = filelist[i]
           filelist[i]   = filelist[i+1]
           filelist[i+1] = tmp

           sorted=0
        ENDIF
     ENDFOR
     pass=pass+1
  ENDWHILE
;;keep track of the first year for the full.key file
  inityear = yrs[0]
  RETURN, filelist 

END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; reads weather data from a single line from a file.  returns a
;; structure containing the station name
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION parseLine, line
  line=STRSPLIT(line, ',', /extract)

  gain   = 4
  offset = 9

  index=(indgen(31)*gain)+offset
  data=float(line[index])
  index=where(data eq -99999) 
;  FOR i=0, 30 DO BEGIN
;     data[i]=FLOAT(line[(i*gain)+offset])
;     if data[i] eq -99999 then data[i] = -99.9
;  ENDFOR

  stationName = STRCOMPRESS(line[3], /remove_all)
  stationID   = LONG(line[1])
  wbanID      = LONG(line[2])
  weatherType = line[5]
  year        = FIX(strmid(line[7], 0,4))
  month       = FIX(strmid(line[7], 4,2))


;; Convert the units of DATA into Century Units
  CASE STRMID(weatherType, 0, 1) of 
     'P' : data = data* 0.0254    ; convert hundredths of inches to cm
     'T' : data = (data - 32) / 1.8 ; convert degrees F to degrees C
     ELSE : print, "ERROR, weather type not found : ", weatherType
  ENDCASE
  if index[0] ne -1 then data[index] = -99.9


  RETURN, {month, stnName:stationName, stnID:stationID, wbID:wbanID, $
           yr:year, mo:month, type:weatherType, data:data}
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Checks to make sure we have Precip, tmin and tmax for a station,
;;    if not, it fills in the missing element with null values, and
;;    changes the file pointer so that it is looking at the previous
;;    line again
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro verifyData, data, i, un, last

  case i mod 3 of 
;; if i mod 3 eq 0 then this SHOULD be PRCP, if it isn't, fix it
     0 : if (data[i]).type ne 'PRCP' then begin
            data[i] = {month, stnName:(data[i]).stnName, stnID:(data[i]).stnID, $
                       wbID:(data[i]).wbID, yr:(data[i]).yr, mo:(data[i]).mo, $
                       type:'PRCP', data:replicate(-99.9, 31)}
            point_lun, un, last
         endif
;; if i mod 3 eq 1 then this SHOULD be TMAX, if it isn't, fix it
     1 : if (data[i]).type ne 'TMAX' then begin
            data[i] = {month, stnName:(data[i-1]).stnName, stnID:(data[i-1]).stnID, $
                       wbID:(data[i-1]).wbID, yr:(data[i-1]).yr, mo:(data[i-1]).mo, $
                       type:'TMAX', data:replicate(-99.9, 31)}
            point_lun, un, last
         endif
;; if i mod 3 eq 2 then this SHOULD be TMIN, if it isn't, fix it
     2 : if (data[i]).type ne 'TMIN' then begin
            data[i] = {month, stnName:(data[i-1]).stnName, stnID:(data[i-1]).stnID, $
                       wbID:(data[i-1]).wbID, yr:(data[i-1]).yr, mo:(data[i-1]).mo, $
                       type:'TMIN', data:replicate(-99.9, 31)}
            point_lun, un, last
         endif
  endcase

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Reads weather data from the file and returns an array of structures
;;   with the station name, start and ending year,  and associated data values
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION readData, filename
  OPENR, un, filename, /get
  line=''

; skip the header information
  READF, un, line &   READF, un, line

;read the first data line and parse it into a useful structure
  READF, un, line
  tmp=parseLine(line)
  data=replicate(tmp, 10000)
  curMax=10000l
  i=1l
; read in the remaining lines, parse, and add them to the array
  WHILE NOT EOF(un) DO BEGIN  
     while not eof(un) and i lt curMax do begin
        line=' '

;; store our current file position so that we can return if this isn't
;; the proper element (prcp, tmin, tmax)
        point_lun, -1*un, last_point

; read in the next line
        READF, un, line

; parse it into a useful data structure
        data[i]=parseLine(line)

; check to make sure it is the proper element (prcp, tmin, tmax) and
; correct it if not.  
        verifyData, data, i, un, last_point
           
        i=i+1
     endwhile

;; if we haven't hit the end of the file than we must have overflowed
;; our data structure, allocate another 10000 entries.  
     if not eof(un) then begin
        data=[data, replicate(tmp, 10000)]
        curMax=curMax+10000
     endif
  ENDWHILE

;; chop off the extra space at the end of the data structure  
  data=data[0:i-1]
  print, i, " lines read (or filled as NULL) from : ", filename

;; cleanup
  CLOSE, un  & FREE_LUN, un

  RETURN, data
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  getStnData grabs all data from database from a given station
;;    First makes sure we are pointing at the correct station.  If we
;;    are not then there may be an extra station in the data File, in
;;    which case we skip it... or there may be an extra station in the
;;    stn file.  Which we check via the alphabetical ordering of
;;    the two station names.  
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION getStnData, station, data, startPt

;; make sure we are pointed at the correct station to begin with.  if
;; we are not then there must be an extra station in this file so we
;; will skip it.  
  initStart=startPt
  npts=n_elements(data)
  if startPt eq npts then begin
     out=data[npts-1]
     out.stnID=-1
     return,out
  endif
  IF (station GT (data[startPt]).stnName) THEN BEGIN
     WHILE ((data[startPt]).stnName LT station) and (startPt lt npts-1) DO $
       startPt=startPt+1
  ENDIF 
  IF station LT (data[startPt]).stnName THEN BEGIN
;     startPt = initStart  only if we want to look at all of these
;     again
     tmp = data[startPt]
     tmp.stnID=-1
     return, tmp
  ENDIF
;; read first station data
  output=data[startPt]
  startPt=startPt+1
  curID = (data[startPt]).stnID

;; while we are still looking at the same station, add the current
;; data on to our list of data
  WHILE((data[startPt]).stnName EQ station) and $
    ((data[startPt]).stnID EQ curID) and (startPt lt npts-1) DO BEGIN
     output=[output,data[startPt]]
     startPt=startPt+1
  ENDWHILE
  if startPt eq npts-1 and (data[startPt]).stnName eq station then begin
     output=[output,data[startPt]]
     startPt=startPt+1
  endif

;; return our final list of data
  return, output
END

;; returns the julian day given the day, month, and optionally year
;; (for leap years)
FUNCTION julianFromNum, day, mon, yr
  if n_elements(yr) eq 0 then yr=1  ; non-leap year by default
  if mon  gt 12 then begin
    return, -1
  endif

  case mon of
     1  : base=0
     2  : base=31
     3  : base=59
     4  : base=90
     5  : base=120
     6  : base=151
     7  : base=181
     8  : base=212
     9  : base=243
     10 : base=273
     11 : base=304
     12 : base=334
     else  : return, -1
  endcase
  if ((yr mod 4) eq 0) and (mon gt 2) then base=base+1
  
  return, base+day
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


;;
;; Writes a month of NULL values (-99.9) to the current output file
;;
pro writeNULLmonth, oun, month, year
  ndays=days_in_month(month, year)
  for day=1, ndays do begin
     printf, oun, $
       FORMAT='(I2," ",I2," ", I4," ",I3," ",F8.3," ",F8.3," ",F8.3)', $
       day, month, year, $
       julianFromNum(day, month, year), $
       -99.9, -99.9, -99.9
  endfor
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  printStation  writes the output files!
;;    INPUT :  all of the data for one station, and an output file name
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro printStation, fname, data

  if (data[0]).type ne "PRCP" and $
    (data[1]).type ne "TMAX" and $
    (data[2]).type ne "TMIN" then return
  
  openw, oun, /get, fname
  npoints=n_elements(data)

;; for all data chunks in this file
;;  lastmonth=((data[0]).mo-1)
  lastmonth=0  ;; day cent expects it to start with day 1.  
;;  lastyear=(data[0]).yr
  lastyear=1975  ;; and I am lazy so it will start with 1975 by default
  if lastmonth eq 0 then begin
     lastmonth=12 
     lastyear=lastyear-1
  endif

  for i=0, npoints-1,3 do begin
     curmonth = (data[i]).mo
     curyear  = (data[i]).yr
;; lots of ugly logic follows... basically just keeps checking to see
;; if the months all follow in order, if they don't it prints null
;; data until it reaches the next month for which we have data.  
     if (curmonth ne (lastmonth+1)) and (curmonth ne lastmonth) and $
       (lastyear le curyear) then begin
        if (curmonth ne 1) or (curyear ne (lastyear+1)) or (lastmonth ne 12) then begin
           ;; oops!  the data file missed a month (or two)
           done=0
           while not done do begin
              if lastmonth eq 12 then begin
                 lastmonth =1  & lastyear = lastyear+1
              endif else lastmonth = lastmonth+1

;; this is where we print the null data.  at this point lastyear and
;; last month have already been incremented by one month so the names
;; are a little confusing.  
              writeNULLmonth, oun, lastmonth, lastyear
              
              if ((lastmonth+1 eq curmonth) and (lastyear eq curyear)) or $
                ((lastmonth eq 12) and (curmonth eq 1) and $
                 ((lastyear+1) eq curyear)) then done=1
           endwhile
        endif
     endif
     ndays=days_in_month((data[i]).mo, (data[i]).yr)

;; for all days in the month
     for day=0, ndays-1 do begin
; check that we still have three more lines, one for each data type
        if i+2 lt npoints then begin
           printf, oun, $
             FORMAT='(I2," ",I2," ", I4," ",I3," ",F8.3," ",F8.3," ",F8.3)', $
             day+1, $
             (data[i]).mo, $
             (data[i]).yr, $
             julianFromNum(day+1, (data[i]).mo, (data[i]).yr), $
             (data[i+1]).data[day], $
             (data[i+2]).data[day], $
             (data[i]).data[day]
        endif
     endfor
     lastmonth=(data[i]).mo
     lastyear=(data[i]).yr
  endfor
  close, oun   & free_lun, oun
END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  write the DayCent .wth weather files
;;    First searches through all data files for the information about
;;    each station.  Once it has that data compiled it passes it on to
;;    printStation.  
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRO writeFiles, data, stations

;; keeps track of where we are in each data array so that getStnData
;; doesn't need to read the entire array each time.  This assumes the
;; arrays are in the same order.  
  curPt=lonarr(n_elements(data))
  curPt[*]=0l
  help, *data[0]
;; for all stations listed in the stn file
  FOR i=0, n_elements(stations)-1 DO BEGIN
     curName=(stations[i]).stnName
     
; get station data from the first data file
     tmp2=curPt[0]
     stnData=getStnData(curName, *data[0], tmp2)
     curPt[0]=tmp2
; get station data from all other data files
     FOR j=1, n_elements(data)-1 DO BEGIN
        tmp2=curPt[j]
        tmp=getStnData(curName, *data[j], tmp2)
        curPt[j]=tmp2
        if (tmp[0]).stnID ne -1 then begin
           stnData=[stnData,tmp]
        endif else stnData=tmp
     ENDFOR
     print, curPt
; write this station to a file
     if (stnData[0]).stnID ne -1 then $
       printStation, curName+'.wth', stnData
  ENDFOR

END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  write a .key file that lists all stations wth latitude, longitude
;;  and starting year (assumed to be 1975 because most are).
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro writeKeyFile, stnlist, inityear, keyfile
;; default name is full.key
  if not keyword_set(keyfile) then keyfile='full.key'
  if not keyword_set(inityear) then inityear=1975
;; open file
  openw, oun, /get, keyfile

;; loop through all stations printing out the relavent data
  for i=0, n_elements(stnlist)-1 do begin
     printf, oun, (stnlist[i]).stnName+'.wth', (stnlist[i]).lat, -1*(stnlist[i]).lon, inityear
  endfor

;; cleanup
  close, oun   & free_lun, oun
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   MAIN PROGRAM
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRO dayCentWeather, inputFile
  stnFile=0
  first_datFile=1

;; make sure the files are in chronological order
  filelist=reorder(getFileNames(inputFile), inityear)
  print, filelist

  stnList=getStationList(filelist[stnFile])
  print, stnList[50]
  writeKeyFile, stnList, inityear

  data=PTR_NEW(readData(filelist[first_datFile]))
  FOR i=first_datFile+1, n_elements(filelist)-1 DO BEGIN
     newdata=PTR_NEW(readData(filelist[i]), /no_copy)
     data=[data,newdata]
  ENDFOR
  help, data
  writeFiles, data, stnList

  
  FOR i=0, n_elements(data)-1 DO $
    PTR_FREE, data[i]
  
END
