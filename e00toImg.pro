;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Takes an arc export e00 file and converts it to an ENVI image file
;;  complete with ENVI header.
;;
;; Currently the e00 file must have it's sections in the following order
;;   GRD
;;   LOG  (optional)
;;   PRJ  (optional, but header may not be written without it)
;;   IFO  (optional)
;;
;; This program could be extented to allow other e00 formats.  
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; reads in the first two lines and verifies that we are working with a GRD e00 file
FUNCTION init, un
  line=""
  readf, un, line               ; junk line with old imported filename
  readf, un, line               ; junk line GRD 2
  grd=(strsplit(line, /extract))[0]
  IF line NE "GRD  2" THEN BEGIN
     print, "second line not what I was expecting..."
     print, " got : ", line
     print, " expecting : GRD 2"
     return, 0
  ENDIF
  return, 1
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; reads the header info from the .e00 GRD section
;;
;; should be :
;;   ns  nl  1NULLVALUE
;;   PixelSizeX  PixelSizeY
;;   East  North
;;   West  South
;;
;; Coordinates are assumed to be in UTM zone 13...
;;  where is that specified?!?
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION getInfo, un, info
  line=""

  readf, un, line
  data=strsplit(line, /extract)

  ; line should be Number of Samples, Number of Lines, 1NULL data value
  ns=fix(data[0])
  ns=ns+5-(ns MOD 5)     ; number of samples is always rounded to the nearest 5
  nl=fix(data[1])
  null=double(strmid(data[2],1,strlen(data[2])-1))
  
  psx=0.  &  psy=0.
  readf, un, psx, psy
  
  ;; upper left Easting and Northing
  ulE=0d & ulN=0d
  ;; bottom right Easting and Northing
  brE=0d & brN=0d
  readf, un, ulE, brN
  readf, un, brE, ulN
  info={ns:ns, nl:nl, psx:psx, psy:psy, coords:[ulE, ulN, brE, brN], null:null}
  return, 1
END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Reads through the GRD section writing each line to a binary
;;  data file as integers.  Returns true if it reaches the EOG tag
;;  and there is more data left in the file
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION writeDataFile, un, info, imgFname
;; setup
  openw, oun, /get, imgFname
  data=dblarr(info.ns)
  nl=0
  line=""

;; read through file converting and writing output as we go
;;   EOG is the End Of Grid tag in the file
  WHILE line NE "EOG" AND NOT eof(un) DO BEGIN
     point_lun, -1*un, oldpos
     readf, un, line
     IF line NE "EOG" THEN BEGIN
        point_lun, un, oldpos
        readf, un, data

        dex=where(data EQ info.null)
        IF dex[0] NE -1 THEN data[dex]=0
        data=fix(data)
        writeu, oun, data
        nl++
     ENDIF

  ENDWHILE
  close, oun  & free_lun, oun
  
;; We don't really trust the number of lines read from the header
;; yet because it seems to have been wrong before so we have an
;; easy test here.  
  IF info.nl NE nl THEN BEGIN
     print, nl, info.nl
     info.nl=i
  ENDIF
  
  IF eof(un) THEN return, 0 ELSE return, 1
END




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; skips over the LOG section of the e00 file if it exists
FUNCTION skipLOG, un
  
;; save the position of the file pointer
  point_lun, -1*un, oldPos
  
;; read the first line
  line=""
  readf, un, line
  
;; if the LOG section doesn't exist than set the file pointer
;; back to where it was and return
  IF (strsplit(line, /extract))[0] NE "LOG" THEN BEGIN
     point_lun, un, oldPos
     return, 1
  ENDIF
  
;; read through until we hit the End Of Log marker (EOL)
  WHILE line NE "EOL" AND NOT eof(un) DO readf, un, line
  
;; if we ran off the end of the file then return and error
  IF eof(un) THEN return, 0
  return, 1
END




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Parse a parameter, value pair into the projInfo struct
;; 
;;  Right now we probably only handle UTM correctly
FUNCTION storeInfo, projInfo, param, value
  CASE param OF 
     "Projection" : projInfo.name=value
     "Zone"       : projInfo.zone=fix(value)
     "Datum"      : projInfo.datum=value
     "Zunits"     :
     "Units"      : projInfo.units=value
     "Spheroid"   :
     "Xshift"     :
     "Yshift"     :
     "Parameters" :

     ELSE : BEGIN
;; not sure what we hit but we should print it out for debugging
;;   and return an error 
        print, param, value
        return, 0
     ENDELSE 
  ENDCASE 
  return, 1
END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; read through the PRJ section storing parameter values as
;;  appropriate in the projInfo struct
FUNCTION getProjInfo, un, info, projInfo

;; initialize the structure
  projInfo={name:"", zone:-1, datum:"", units:""}

;; save the position of the file pointer
  point_lun, -1*un, oldPos

;; read the first line
  line=""
  readf, un, line
;; if the first line is not PRJ then we are not in a projection section
;;  and we should exit (return an error so the main program can exit as well
  IF (strsplit(line, /extract))[0] NE "PRJ" THEN BEGIN
     point_lun, un, oldPos
     return, 0
  ENDIF

;; read through the rest until we hit the End Of Prj (EOP) tag
;;   parsing the lines as we go
  readf, un, line
  WHILE line NE "EOP" DO BEGIN
     IF line NE "~" THEN BEGIN
        newLine=strsplit(line, /extract)
        param=newLine[0]
        IF n_elements(newLine) GT 1 THEN $
          value=newLine[1]
        IF NOT storeInfo(projInfo, param, value) THEN return, 0
     ENDIF
     readf, un, line
  ENDWHILE

;; if we made it this far we done well, so return a true value
  return, 1
END

FUNCTION writeHeader, fname, info, proj
;  ll=utm_to_ll(info.coords[0], info.coords[1], proj.datum, zone=proj.zone)

  writeENVIhdr, fname+".hdr", ns=info.ns, nl=info.nl, nb=1, $
                dtype=2, lon=info.coords[0], lat=info.coords[1], interleave=0, $
                ps=[info.psx, info.psy], zone=proj.zone, $
                projection=proj.name, units=proj.units, $
                datum=proj.datum
  return, 1
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Main Program
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRO e00toImg, e00fname, imgFname

  openr, un, /get, e00fname

;; reads the first two lines and makes sure it starts with a GRD 
  IF NOT init(un) THEN return

;; reads in the GRD header information (ns, nl, null, location)
  IF NOT getInfo(un, info) THEN return
  help, info, /str

;; reads the data from the GRD section and writes it to a binary file
  IF NOT writeDataFile(un, info, imgFname) THEN return

;; skips over the LOG section in the e00 file
  IF NOT skipLOG(un) THEN return

;; reads the projection information  
  IF NOT getProjInfo(un, info, projInfo) THEN return

;; writes and ENVI header so we can open the file easily
  IF NOT writeHeader(imgFname, info, projInfo) THEN return

  close, un
  free_lun, un
END

