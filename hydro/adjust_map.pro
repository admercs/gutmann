;+
; NAME: adjust_map
;
; PURPOSE: adjust rainfall in the first 365 days of a noah weather 
;            input file to match a given mean annual precipitation (MAP)
;
; CATEGORY: noah model inputs
;
; CALLING SEQUENCE: adjust_map, inputfile, MAP, outputfile, nsteps
;
; INPUTS:
;            inputfile = name of the noah weather file to use as input
;            MAP       = Mean Annual Precip to match
;            outputfile= name of the new noah weather file to write
;
; OPTIONAL INPUTS:
;            nsteps    = number of time steps per day
;                        (if not supplied findnsteps will attempt to find this
;                         value, and will default to 480)
;
; KEYWORD PARAMETERS: <none>
;
; OUTPUTS: outputfile
;
; OPTIONAL OUTPUTS: <none>
;
; COMMON BLOCKS: <none>
;
; SIDE EFFECTS: <none>
;
; RESTRICTIONS: <none>
;
; PROCEDURE: Read data from input file
;            match the MAP of the first 365 days to the supplied MAP value
;                    determine nsteps from the day column in the input file
;                    if there are enough days find the ratio between real MAP
;                    and rainfall in the first 365 days
;                    adjust the first 365 days of rainfall to match MAP
;            read the header from the input file
;            write the output file
;
; EXAMPLE: adjust_map, 'IHOPUDS1', 654, 'adjustedIHOPUDS1'
;
; MODIFICATION HISTORY:
;           edg - 2/16/2006 - original
;-

;  uses the median distance between day changes to determine dt
;  (AND thus how long a year is)
;  default to 480
FUNCTION findnsteps, day
  index=where(day[1:*]-day[0:n_elements(day)-2] eq 1)
  IF index[0] EQ -1 THEN BEGIN 
     print, "MAP adjustment made assuming 480 time steps per day (dt=3min)"
     nsteps=480
  ENDIF ELSE $
    nsteps=fix(median(index[1:*]-index[0:n_elements(index)-2]))

  return, nsteps
END

; read the first 4 lines and return them as a vertical array
FUNCTION getHeader, infile
  openr, un, /get, infile
  line=""
  readf, un, line
  output=line
  readf, un, line
  output=[[output], [line]]
  readf, un, line
  output=[[output], [line]]
  readf, un, line
  output=[[output], [line]]
  close, un
  free_lun, un
  return, output
END


;  Forces the first Year of rain data to match MAP for spinup purposes
FUNCTION matchMAP, rain, MAP, day, nsteps
  IF n_elements(nsteps) EQ 0 THEN nsteps=findnsteps(day)

  IF n_elements(rain) LT nsteps*365l THEN BEGIN 
     print, "Record too short to adjust, no MAP adjustment made : ", $
            nsteps, n_elements(rain)/nsteps
  ENDIF ELSE BEGIN 
     adjustment=MAP/total(rain[0:nsteps*365l-1])
     rain[0:nsteps*365l-1]*=adjustment
     print, "Rain for the first year adjusted by : ", adjustment;, $
;            nsteps, total(rain[0:nsteps*365-1]), nsteps*365l-1
  ENDELSE 

  return, rain
END


; PURPOSE: adjust rainfall in the first 365 days of a noah weather 
;            input file to match a given mean annual precipitation (MAP)
PRO adjust_map, infile, MAP, outfile, nsteps
  junk=load_cols(infile, data)

;; this does the work of actually changing precip values
  data[10,*]=matchMAP(data[10,*], MAP, data[1,*], nsteps)

  header=getheader(infile)
  
  openw, oun, outfile, /get
  printf, oun, header
  FOR i=0l, n_elements(data[0,*])-1 DO BEGIN
     printf, oun, data[*,i], format='(4I7,10F10.4)'
  endFOR
  close, oun
  free_lun, oun

END

