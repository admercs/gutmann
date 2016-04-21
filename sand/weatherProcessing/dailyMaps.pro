; INCLUDE FILES
@mapping.pro
@readENVIhdr.pro
@writeENVIhdr.pro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  INITIALIZATION ROUTINES
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; converts a string name of month into the month number
function convertMonth, moStr

;; simple error avoision (I don't say evasion, I say avoision...)
  if strlen(moStr) gt 3 then moStr=strmid(moStr, 0, 3)
  moStr=strlowcase(moStr)

  case moStr of 
    'jan' : return, 1
    'feb' : return, 2
    'mar' : return, 3
    'apr' : return, 4
    'may' : return, 5
    'jun' : return, 6
    'jul' : return, 7
    'aug' : return, 8
    'sep' : return, 9
    'oct' : return, 10
    'nov' : return, 11
    'dec' : return, 12
  endcase
  return, -1  ;oops
end

;; parse the input file into a meaningful structure
function getRunInfo, infile
  precFile=''        ;declare a string
  stnFile =''        ;declare a string
  imgFile =''        ;declare a string
  line    =''        ;declare a string
  list=intarr(3)     ;dummy values that will be erased

  openr, un, /get, infile

;read the name of the precipitation file
  readf, un, precFile
  readf, un, stnFile
  readf, un, imgFile

;read a date from each line until we reach the end of the file
  while not eof(un) do begin
    readf, un, line
    date=strsplit(line, /extract)
    date=[convertMonth(date(0)),fix(date(1)),fix(date(2))]
    list=[[list],[date]]
  endwhile

;figure out how many dates there are total.  
  n_dates=(n_elements(list)/3)-1
  list=list[*,1:n_dates]

;; sort dates to make finding the data associated with them faster
  sortable=list(2,*)*10000l + list(0,*)*100l + list(1,*)
  dex = sort(sortable)
  list=list(*,dex)

;; clean up and return
  close, un & free_lun, un

  return, {RunInfo, prec:precFile, stn:stnFile, img:imgFile, $
           n_dates:n_dates, dates:list}

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  FIND STATIONs ROUTINES
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Read in and return a list of all weather stations
;;  available in this stn file.  Also returns latitude
;;  longitude, and station COOPID
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function getList, stnFilename
  line=''
  list={stnElement, lon:0D, lat:0D, name:' ',stnID:0l}

;; open the station file. 
  openr, un, /get, stnFilename

;;read past the initial 2 header lines
    readf, un, line &    readf, un, line

;; read data and parse it into a list of stnElement structures
  while not eof(un) do begin

;; read the next line from the input file
    readf, un, line

;; parse the current line
    name = strcompress(strmid(line, 16,31), /remove_all)
    stnID= long(strmid(line, 0, 7))
    lat  = float(strmid(line, 137, 10))
    lon  = float(strmid(line, 147, 10))
    
;; ensure we are in the western hemisphere... if we aren't this will
;; cause problems, but then we are also hard coding zone 14!  
    if lon gt 0 then lon = lon*(-1)    
    utm = ll_to_utm(lon,lat, setzone=14)

;; add the current station data to the running list of data
    list=[[list],[{stnElement, lon:utm[0],lat:utm[1], $
                  name:name,stnID:stnID}]]
  endwhile
  
  sz=n_elements(list)
  list=list(1:sz-1)
  return, list
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; figure out which stations are within 10km of the image
;;  boundaries
function pickStations, info
  init=0l

; find image boundary and increase the bounds by 10km
  bounds=increaseBounds(getBounds(info.img), 10000)

; get a list of all stations available and their utm locations
  stnlist = getList(info.stn)

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; find the first valid point
  point={PT, xloc:stnlist(init).lon, yloc:stnlist(init).lat}
  while not isInBounds(point, bounds) do begin
    init=init+1
    point={PT, xloc:stnlist(init).lon, yloc:stnlist(init).lat}
  endwhile
  list=stnList(init)
  init=init+1

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; cat on all the other points that fall within the image boundary.  
  for i=init, n_elements(stnlist)-1 do begin
    point={PT, xloc:stnlist(i).lon, yloc:stnlist(i).lat}
    if isInBounds(point,bounds) then $
      list = [[list],[stnlist(i,*)]]
  endfor

  return, list
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  DATA RETRIEVAL ROUTINES
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Position file unit to point to the beginning of a specific
;;   station's listing
;;
;; search through the file unit until we match station name and
;; Station ID (this should happen at the same time).  
pro findStation, unit, station
  line=''
  name=''
  ID  =0l
  
  while (name ne station.name) and ID ne station.stnID $
    and not eof(unit) do begin
    line=''
    fileInfo = fstat(unit)  ; save our current file pointer

    readf, unit, line
    line=strsplit(line, ',' , /extract)
    name=strcompress(line(3), /remove_all)
    ID = long(line(1))
  endwhile

  point_lun, unit, fileInfo.cur_Ptr  
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;getDailyPrec picks out precipitation for a given date from a single
;;  line of data.  called by getNext  returns -1 is this is the
;;  incorrect line or if the particular date is missing
function getDailyPrec, date, line
  prec     = -1  ;default value
  firstDay = 9   ;column of first days value
  increment= 4   ;number of columns to shift for each additional day

  print, line

  curYear  = long(line(7))/100
  curMon   = long(line(7)) - (curYear*100)
  if curYear ne date(2) or curMon ne date(0) then begin
    print, 'badyear or month'
    print, date
    print, fix(curMon), '      ', fix(curYear)
    return, -1
  endif

  prec = long(line(firstDay + (increment*(date(1)-1))))

  if prec lt 0 then begin
    print, 'badprec', date, prec
    return, -1
  endif

  print, 'good', prec
  return, prec
end
;;;;;;;;;;;;;;;;
;; getNext called by getPrec
function getNext, unit, nextDate, stnID
  line     = ''
  curYear  =  0
  curMon   =  0
  curID    =  stnID
  fileInfo = fstat(unit) ;again, save file pointer

  while (curYear lt nextDate(2)) and (stnID eq curID) do begin
    line=''
    fileInfo = fstat(unit)      ;again, save file pointer
    readf, unit, line

    line=strsplit(line, ',', /extract)
    curYear = long(line(7))/100
    curID   = long(line(1))
  endwhile

  yearval=(curYear*100)
  while (curMon lt nextDate(0)) and (stnID eq curID) do begin
    line=''
    fileInfo = fstat(unit)      ;again, save file pointer
    readf, unit, line

    line=strsplit(line, ',', /extract)
    curMon = long(line(7)) - yearVal
    curID   = long(line(1))
  endwhile
  
  prec = getDailyPrec(nextDate, line)

  point_lun, unit, fileInfo.cur_Ptr
  return, prec
end
;;;;;;;;;;;;;;;;;;;
;; getPrec find precipitation data associated with each listed date.
;;
;;  pre : info.dates MUST BE SORTED! (more of a pre for getPrec)
;;  post: what you'd expect, an nDate array of floating point
;;    precipitation values from the previous day.  Missing values are
;;    filled with -1
function getPrec, unit, dates, stnID
  line = ''
  ndates=n_elements(dates(1,*))
  prec = fltarr(ndates)

  for i=0, ndates-1 do $
    prec(i) = getNext(unit, dates(*,i), stnID)

  return, prec
end

;;;;;;;;;;;;;;;;;;;;
;; Main data retrieval routine, calls findStation and getPrec
;; 
;;  pre : info.dates MUST BE SORTED! (more of a pre for getPrec)
;;  post: returns an nDates x nStations array of precipitation data
;;         missing values are tagged with -1
function getData, info, stnList
  nDates    = long(info.n_dates)
  nStations = n_elements(stnList)
  data      = fltarr(nDates,nStations)
  line      = ''

;; open and read past the header
  openr, un, /get, info.prec
  readf, un, line &   readf, un, line

  for i=0, nStations-1 do begin

;;set the file pointer to point at the beginning of station i
    findStation, un, stnList(i)

;; Read the appropriate precip data for each date.  If the correct
;; date is not available return -1 for that dates and it will be
;; ignored later.  
    data(*,i) = getPrec(un, info.dates, stnList(i).stnID)

  endfor
  
  close, un & free_lun, un
  return, data
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  MAIN
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro dailyMaps, infile, outfile
;; infile should be a text file with the name of a precip file and a
;; list of dates for which precip maps should be created.  
;; outfile is the filename to create a bsq, 500x500xN_dates byte image
;; of recent precip maps.  

  
;read the input file into a useful data structure
;  info.prec, info.inv, info.n_dates, info.dates
  info=getRunInfo(infile)
  
;find all of the stations that fall within (10km of) the bounds of
; the image we are concerned with.  Gets a list of UTM coordinates,
; Station names and station IDs
  stnList=pickStations(info)

;Generates an array n_dates x n_stations with precip values for the
;previous 24(?) hours (perhaps the number of days should be a parameter?
  data = getData(info, stnList)

  print, data

end
