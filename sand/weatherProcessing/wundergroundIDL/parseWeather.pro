;+
; NAME: parseWeather
;
; PURPOSE: Parses wunderground.com DailyHistory.html files into a
; format readable by CENTURY as weather files.  
;
; CATEGORY: Century Weather file manipulation
;
; CALLING SEQUENCE: parseWeather
;
; INPUTS: none, but current directory must have sub directories with
; valid wunderground.com DailyHistory.html files
;
; OPTIONAL INPUTS: NONE
;
; KEYWORD PARAMETERS: NONE
;
; OUTPUTS: Files are created in each sub directory.  These files
; contain the monthly output values and are named after the weather
; station.  Both RAW (Daily) and wth (monthly data) are generated.  
;
; OPTIONAL OUTPUTS: NONE
;
; COMMON BLOCKS: NONE
;
; SIDE EFFECTS: NONE
;
; RESTRICTIONS: NONE
;
; PROCEDURE: Searches through all directories in the current directory
; for *.html* Daily History files from wunderground.com.  Parses these
; files to find tmax, tmin, and precip data for all stations.  Outputs
; monthly average tmin and tmax as well as total precipitation for the
; month.  
;
; EXAMPLE:
;
; MODIFICATION HISTORY: Original 6/17/2002  Ethan Gutmann
;
;-
function getName, fname
  openr, un, /get, fname
  line= ' '
  while not eof(un) and not strmatch(line, '<h1>History for*') do $
    readf, un, line

  close, un
  free_lun, un

  stationName=(strsplit((strsplit(line,/extract))(2),',',/extract))(0)
  return, stationName
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Read the Date from a file unit.  Searches for selected options in
;;  the form at the top of the page.  Returns date as [Month,Day,Year]
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function getDate, unit
  line=' '

  while not strMatch(line, '<option SELECTED*') and not eof(unit) do $
    readf, unit, line
  if not strMatch(line, '<option SELECTED*') then return, [-99,-99,-99]

;; Read the Month.  Uses the value field rather than the displayed text.
  month=fix((strsplit(line,'"',/extract))(1))
  if not eof(unit) then readf, unit, line


  while not strMatch(line, '*<option selected*') and not eof(unit) do $
    readf, unit, line
  if not strMatch(line, '*<option selected*') then return, [-99,-99,-99]

;; Read the day
  day=fix((strsplit((strsplit(line,'>',/extract))(1),'<',/extract))(0))
  if not eof(unit) then readf, unit, line


  while not strMatch(line, '*<option selected*') and not eof(unit) do $
    readf, unit, line

;; Read the year
  if not strMatch(line, '*<option selected*') then return, [-99,-99,-99]
  year=fix((strsplit((strsplit(line,'>',/extract))(1),'<',/extract))(0))

  return, [month,day,year]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function getTmax, unit
  line=' '
  while not strMatch(line, '<tr><td>Max Temperature</td>') and not eof(unit) do $
    readf, unit, line
  while not strMatch(line, '*; C') and not eof(unit) do $
    readf, unit, line
  if eof(unit) then return, -99.99
  
  Tmax=float((strsplit((strsplit(line, '>',/extract))(1), '<',/extract))(0))
  return, Tmax
end
;;;;;;;;;;;;;;;
;; getTmin
;;;;;;;;;;;;;;;
function getTmin, unit
  line=' '
  while not strMatch(line, '<tr><td>Min Temperature</td>') and not eof(unit) do $
    readf, unit, line
  while not strMatch(line, '*; C') and not eof(unit) do $
    readf, unit, line
  if eof(unit) then return, -99.99
  
  Tmin=float((strsplit((strsplit(line, '>',/extract))(1), '<',/extract))(0))
  return, Tmin
end
;;;;;;;;;;;;;;;;
;; getPrec
;;;;;;;;;;;;;;;;
function getPrec, unit
  line=' '
  while not strMatch(line, '<tr><td>Precipitation</td>') and not eof(unit) do $
    readf, unit, line
  while not strMatch(line, '*<b>*</b>*') and not eof(unit) do $
    readf, unit, line
  if strMatch(line, '*<b>-</b>*') then return, 0.

;; skip ahead to the centigrade line  
  while not strMatch(line, '*<b>*</b>*cm') and not eof(unit) do $
    readf, unit, line
  if eof(unit) then return, -99.99
  
  prec=float((strsplit((strsplit(line, '>',/extract))(1), '<',/extract))(0))
  return, prec
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Get the Date, Tmin, Tmax, and precipitation record for every file
;;  in fileList.  Return an array with one row for each file.  Each
;;  row is in the form [Month, Day, Year, Tmax, Tmin, Prec].
;;  Precipitation is recorded in centimeters, Temperature is in
;;  degrees Celsius.  
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function getData, fileList
  dateList=intarr(3,n_elements(fileList))
  TmaxList=fltarr(n_elements(fileList))
  TminList=fltarr(n_elements(fileList))
  PrecList=fltarr(n_elements(fileList))

  for i=0,n_elements(fileList)-1 do begin
    openr, un, /get, fileList(i)

     dateList(*,i)=getDate(un)
     TmaxList(i)=getTmax(un)
     TminList(i)=getTmin(un)
     PrecList(i)=getPrec(un)

    close, un & free_lun, un
  endfor

  return, [dateList, transpose(TmaxList),transpose(TminList),transpose(PrecList)]  
end

pro writeData, data, file
  openw, oun, /get, file
  printf, oun, data
  close, oun
  free_lun, oun
end

pro parseWeather
  list=findfile('./')
  set_plot, 'PS'
  for i=0,n_elements(list)-1 do begin
    if file_test(list(i),/directory) then begin
      cd, list(i)
      datalist=findfile('DailyHistory.html*')
      outfile=getName(datalist(0))

      rawData=getData(datalist)
      writeData, rawData, outfile+'.RAW'
;      monthly=makeMonthly(rawData)
;      writeData, monthly, outfile+'.wth'
      index=where(rawData(5,*) gt -50)

      cd, '../'

      print, list(i)
      if index(0) ne -1 then $
        plot, rawData(5,index)
    endif
    
  endfor
  device, /close
  set_plot, 'X'

end

