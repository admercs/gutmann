;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Find and read meta data from the L7*HRF.FST file
;;
;;  Returns : 
;;    NS         = number of samples
;;    NL         = number of lines
;;    Gain[6]    = array of gains for each band
;;    Offset[6]  = array of offsets for each band
;;    SunElev    = Sun Elevation
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION getHRFinfo, HRFfile
  openr, un, /get, HRFfile
  line=''
  nb=6
  readf, un, line
  Gain=fltarr(nb)
  Offset=fltarr(nb)

;; read in number of samples and number of lines
  WHILE NOT STRMATCH(line, '*PIXELS PER LINE*') DO readf, un, line
  data=strsplit(line, /extract)
  ns=data[8]
  nl=data[12]
  ns = fix((strsplit(ns, '=',/extract))[0])
  nl = fix((strsplit(nl, '=',/extract))[0])

;; read in gain and offset values
  WHILE NOT strmatch(line, 'GAINS AND BIASES*') DO readf, un, line
  FOR i=0, nb-1 DO BEGIN
     readf, un, line
     data=strsplit(line, /extract)
     Gain[i] = float(data[1])
     Offset[i]=float(data[0])
  ENDFOR

;; read in Sun Elevation  
  WHILE NOT STRMATCH(line, 'SUN ELEVATION ANGLE*') DO readf, un, line
  data=strsplit(line, /extract)
  Sun_Elev = float((strsplit(data[3], '=', /extract))[0])

  close, un   & free_lun, un

;  print, gain
;  print, offset
;  print, ns, nl, Sun_Elev

  return, {MTLinfo, ns:ns, nl:nl, Gain:Gain, Offset:Offset, Sun_Elev:Sun_Elev}
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Find and read meta data from the L71*_MTL.txt file
;;
;;  Returns : 
;;    NS         = number of samples
;;    NL         = number of lines
;;    Gain[6]    = array of gains for each band
;;    Offset[6]  = array of offsets for each band
;;    SunElev    = Sun Elevation
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION getInfo, MTLfile

  IF NOT strmatch(MTLfile, '*MTL.txt') THEN $
    return, getHRFinfo(MTLfile)

;; Assume we have 6 reflectance bands
  nb=6
  line=' '

  OPENR, iun, MTLfile, /get
  READF, iun, line

;; Find and read the number of samples
  while not STRMATCH(line, '*SAMPLES_REF*') do $
    READF, iun, line
  ns=STRSPLIT(line, /extract)
  ns=FIX(ns[2])

;; the number of lines should be on the next line in the meta file
  READF, iun, line
  nl=STRSPLIT(line, /extract)
  nl=FIX(nl[2])

;; Find and read the gains for each band
  while not STRMATCH(line, '*GROUP = MIN_MAX_RADIANCE*') do READF, iun, line
  
  Gain=FLTARR(nb)
  Offset=FLTARR(nb)
  for i=0, nb-2 do begin
     READF, iun, line
     Lmax=FLOAT((strsplit(line, /extract))[2])
     READF, iun, line
     Lmin=FLOAT((strsplit(line, /extract))[2])
; computer the gain as the L range over the DN range
     Gain[i] = (Lmax-Lmin)/255.
     Offset[i] = Lmin
  endfor
;; skip over the two band 6 LMax-Min pairs
  for i=0,4 do READF, iun, line

;; finally computer Band 7 gain
  Lmax=FLOAT((strsplit(line, /extract))[2])
  READF, iun, line
  Lmin=FLOAT((strsplit(line, /extract))[2])
; computer the gain as the L range over the DN range
  Gain[5] = (Lmax-Lmin)/255.
  Offset[5] = Lmin


;; Really finally find and read the sun elevation
  while not STRMATCH(line, '*SUN_ELEVATION*') do READF, iun, line
  Sun_Elev=FLOAT((strsplit(line, /extract))[2])

  close, iun   & free_lun, iun

  return, {MTLinfo, ns:ns, nl:nl, Gain:Gain, Offset:Offset, Sun_Elev:Sun_Elev}

end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Finds the appropriate Dark Object Subtraction value given an image
;;   histogram
;;
;; Starts searching from the location of the maximum point on the
;;   histogram (max(histogram)).  Moves down the histogram bin by bin
;;   until it reaches a zero value.  the point above this zero value
;;   is the Dark Dbject Subtraction value.  Any pixels below this
;;   value are considered to be noise.  
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION getDarkObject, hist

;; starting location is at the maximum point on the histogram
;;   only look at hist from 1:255 because 0 will be the highest due to
;;   all of the zeros padding the edges of the image.  
  current = (WHERE(hist eq MAX(hist[1:255])))[0]
;; starting value is the histogram maximum value
  curVal=hist[current]

;; while the current value is not zero move down the histogram
  while (curVal ne 0) and (current ne 0) do begin
     current = current-1
     curVal = hist[current]
  endwhile

  if current eq 0 then return, 0
;; return the last position we had a non-zero histogram value for
  return, current+1
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      Reads an enviheader file.
;;          returns a struct :
;;                  ns:number of samples in the file
;;                  nl:number of lines in the file
;;                  nb:number of bands in the file
;;                  map: an envi map structure (includes utm coords
;;                  and pixelsize)
;;                  desc: The description field in the .hdr
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function getFileInfo, name
  
  envi_open_file, name, r_fid=id
  
  if id eq -1 then return, {errorstruct, name:name, ns:-1, nl:-1, nb:-1}
  
  envi_file_query, id, nb=nb, nl=nl, ns=ns, h_map=maph, descrip=desc, $
    interleave=interleave, data_type=type
  HANDLE_VALUE, maph, map
  envi_file_mng, id=id, /remove
  
  return, {imagestruct, name:name, ns:ns, nl:nl, nb:nb, map:map, desc:desc, $
           interleave:interleave, type:type}
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      Sets envi header info (map and ns, nl, nb, type, interleave)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro setENVIHdr, info, fname
  envi_setup_head, fname=fname, ns=info.ns, nl=info.nl, nb=info.nb, $
    interleave=info.interleave, data_type=info.type, $
    descrip=info.desc, map_info=info.map, /write
end


FUNCTION getL5Info, filename
  Sun_Elev = 70.                ;arbitrary solar elevation for now.
                                ;NDVI data does not require sun
                                ;elevation

;; get the Image info from the ENVI hdr instead.  
  info=getFileInfo(filename)

;; Gain and offset are constant for L5 (for now, this will actually
;; result in a ~10% error for later L5 images due to lamp changes
;; potentially we could use a look up table to fix these dependant
;; on the date.  
  Gain = [0.602431, 1.17510, 0.805765, 0.814549, 0.108078, 0.056980]
  Offset=[   -1.52,   -2.84,    -1.17,    -1.51,    -0.37,    -0.15]

  return,  {MTLinfo, ns:info.ns, nl:info.nl, Gain:Gain, Offset:Offset, Sun_Elev:Sun_Elev}
END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Main program :
;;  
;;    Corrects a Landsat 7 image to reflectance based on the Sensor Gain,
;;    Dark Object Subtraction, Exoatmospheric Solar Irradiance, and
;;    Sun angle.
;;
;;  Input :
;;  
;;    L7file       Landsat 7 6 band BSQ file name  must not contain
;;                 bands 6 or 8
;;    MTLfile      L71*_MTL.txt meta data file name
;;    outfile      Output file name (same ENVI header as input file)
;;
;;  4/4/2003  Ethan Gutmann
;;    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro L7toRefl, L7file, MTLfile, outfile, makebyte=makebyte, $
              makeNDVI=makeNDVI, Landsat=Landsat
  envistart
;; default to processing L7 data.  L5 was added 7/20/2003
  IF NOT keyword_set(Landsat) THEN Landsat=7

  nb = 6

;; Get calibration data from MTL file of constant data for L5
  IF Landsat EQ 7 THEN begin
;; read necessary meta data from MTL file
     info = getInfo(MTLfile)

  ENDIF ELSE IF Landsat EQ 5 THEN BEGIN 
;; get "constant" Landsat 5 calibration data
     info=getL5Info(L7file)
     outfile=MTLfile

  ENDIF ELSE BEGIN
;; Return and print an error message if Landsat is not 5 or 7.  
     print, 'ERROR : I do not know how to calibrate Landsat ', $
            strcompress(Landsat, /remove_all), ' data'
     return
  ENDELSE

;; the angle between the average surface normal and the incoming sunlight
  theta = (90-info.Sun_Elev) * !DTOR
  
;; Constant Exoatmospheric Solar Irradiance bands 1-5,7 
  IF Landsat EQ 7 THEN BEGIN 
     ;LANDSAT 7 values
     Eo = [1970.,1843.,1555.,1047.,227.1,80.53]
  ENDIF ELSE $
     ;LANDSAT 5 values
     Eo = [1957, 1826, 1554, 1036, 215.0, 80.67]

;; cross calibration values between landsat 5 and 7.  Divide 5 radiance by
;; cross_cal to get 7 radiance
  cross_cal = [0.9039, 1.6745, 1.4725, 1.3686, 1.0039, 1.3490]


;; set up file handling
  openr, un, /get, L7file
  ENVIinfo=getFileInFo(L7file)
  openw, oun, /get, outfile
  data=make_array(ENVIinfo.ns, ENVIinfo.nl, type=ENVIinfo.type)
  DarkObject=bytarr(nb)

  
;; Run through all bands finding dark objects, then computeing
;; reflectance and writing it to disk
  for i=0, nb-1 do BEGIN
     ;; skip the thermal band if it exists
     IF ENVIinfo.nb EQ 7 AND i EQ 5 THEN BEGIN 
        point_lun, (-1)*un, pointer
        point_lun, un, pointer+(ENVIinfo.ns*ENVIinfo.nl*ENVIinfo.type)
     ENDIF

     readu, un, data

;; Find the dark object for band i
     bandHistogram=HISTOGRAM(data)
     DarkObject[i] = getDarkObject(bandHistogram)

;; Combine terms so that we only do one addition and one
;; multiplication.  For the offset term we convert the Dark Object
;; from DN to reflectance and subtract that value, it includes info.offset.  
     gain   = (          info.Gain[i]         / (cos(theta) * Eo[i]))   *10000 *!PI
     offset = ((info.Gain[i] * DarkObject[i]) / (cos(theta) * Eo[i]))   *10000 *!PI
     IF Landsat EQ 5 THEN BEGIN
        gain   =   gain / cross_cal[i]
        offset = offset / cross_cal[i]
     ENDIF

;; Compute reflectance
     refl = fix((data*gain) - offset)
     index=where(refl lt 0, count)
     if count NE 0 then refl[index] = 0

     if keyword_set(makebyte) then begin
        mx=max(refl)
        refl = byte(refl* (255./mx))
        print, "The Maximum value in this band ", i, " is ", mx
     ENDIF
     IF keyword_set(makeNDVI) THEN BEGIN
        IF i EQ 2 THEN b3=refl
        IF i EQ 3 THEN b4=refl
     ENDIF

;; output data
     writeu, oun, refl
  endfor

  close, un, oun
  free_lun, un, oun

;; set up the ENVI .hdr file with a useful description and the proper
;; data type info
  if not keyword_set(makebyte) then ENVIinfo.type = 2
  ENVIinfo.nb=6
  ENVIinfo.desc='File Converted to reflectance with the following : Refl = 10000*(DN*Gain- DarkObject)*PI/(Irradiance*cos(Theta))                where Gain = '+STRING(info.Gain, /print)+',                    DarkObject = '+STRING(DarkObject, /print)+',               Irradiance = '+STRING(Eo, /print)+'                 Theta = '+STRING(theta, /print)+'                            old Header{'+ENVIinfo.desc+'}'
  setENVIhdr, ENVIinfo, outfile

  IF keyword_set(makeNDVI) THEN BEGIN
     NDVI=(float(b4)-b3)/(float(b4)+b3)
     NDVI=fix(NDVI*10000)
     print, "Mean NDVI value  =", mean(NDVI)/10000.
     openw, oun, /get, outfile+".ndvi"
     writeu, oun, NDVI
     ENVIinfo.nb=1
     ENVIinfo.type=2
     setENVIhdr, ENVIinfo, outfile+".ndvi"
     close, oun   & free_lun, oun
  ENDIF

end
