;+
; NAME: e00_Poly2Tiff
;
; PURPOSE: Convert Arc Export file format (.e00) files into geoTiff files
;
; CATEGORY: File Import/Export
;
; CALLING SEQUENCE: e00_Poly2Tiff, e00_Filename, geotiff_Filename, resolution
;
; INPUTS:
;          e00_Filename : Name of the e00 file to be imported
;          geotiff_Filename : Name of the output geotiff file
;
; OPTIONAL INPUTS:
;          resolution : spatial resolution of the geotiff in meters
;              DEFAULT : 1000m
;
; KEYWORD PARAMETERS: NONE
;
; OUTPUTS: NONE (geotiff file)
;
; OPTIONAL OUTPUTS: NONE
;
; COMMON BLOCKS: NONE
;
; SIDE EFFECTS: NONE (that I know of ;)
;
; RESTRICTIONS: NONE (that I know of ;)
;
; PROCEDURE:
;
; EXAMPLE:
;            e00_Poly2Tiff, "soilsMap.e00", "soilsMap.tif", 100
;
; MODIFICATION HISTORY:
;            02/18/2005 - edg - original
;
;  (c) 2005 Ethan Gutmann
;
;-


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Searches through a file for a line that matches the given line/pattern
;; 
;;  returns 0 if it does not find the pattern,
;;  returns 1 if it does
;;
;; If the saveline keyword is set it leaves the fileunit pointing at the
;;   position in the file that contains the given pattern
;;   
;; If the saveline keyword is not set it leaves the fileunit pointing at the
;;   position the line after the line that contains the pattern
;;   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION findLine, un, line, saveline=saveline
  curline=''
  ;; Search through the file for the string line.  In general
  ;;   this will be the very next line and no searching is really necessary
  IF keyword_set(saveline) THEN BEGIN
     WHILE NOT strmatch(curline, line) AND NOT eof(un) DO BEGIN 
        point_lun, -1*un, pos
        readf, un, curline
     ENDWHILE
     IF NOT eof(un) THEN point_lun, un, pos
  endIF ELSE WHILE NOT strmatch(curline, line) AND NOT eof(un) DO readf, un, curline
  
  IF eof(un) THEN BEGIN 
     ;; maybe the line came before the point we started at so
     ;;  go back to the beginning of the file and search again
     point_lun, un, 0
     IF keyword_set(saveline) THEN BEGIN
        WHILE NOT strmatch(curline, line) AND NOT eof(un) DO BEGIN 
           point_lun, -1*un, pos
           readf, un, curline
        ENDWHILE
        IF NOT eof(un) THEN point_lun, un, pos
     endIF ELSE WHILE NOT strmatch(curline, line) AND NOT eof(un) DO readf, un, curline
     IF eof(un) THEN return, 0
  ENDIF
  return, 1
END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; readARC reads the "ARC" section of an e00 file (if it exists) and returns
;;   an array of structures {info, points}
;;     info = a 6 element array :
;;       [cov#, covID, fromNode, toNode, Lpoly, Rpoly, N_coords]
;;     points = a 2xmaxPoints array :
;;       [[x1,y1],[x2,y2], ... ,[x_n,y_n], ... ,[x_maxPoints,y_maxPoints]]
;;       but only the first n (defined by N_coords) are used
;;
;;  OPTIONAL KEYWORD : maxPoints, defines the maximum number of points
;;     in an arc, default value is 500, it is not clear if the e00 file format
;;     allows arcs with more than 499 points, but just incase this keyword
;;     makes it easy to fix if so
;;
;; This is likely to be the slowest part of the program as it generally has
;;   the most file I/O to do
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION readARC, un, maxPoints=maxPoints
  line=''
  IF NOT keyword_set(maxPoints) THEN maxPoints=500

  IF NOT findLine(un, 'ARC *') THEN return, -1

  readf, un, line
;; keep reading in arcs until we hit the end of the ARC section (defined by -1 0 0 0...)
  WHILE NOT $
    strmatch(line, '        -1         0         0         0         0         0         0') $
    AND NOT eof(un) DO BEGIN

; the current line contains the info for the next arc segment
     curinfo=fix(strsplit(line, /extract))
     
     ;; check to make sure there aren't more points in this arc than we can handle
     IF curinfo[6] GT maxPoints THEN BEGIN
        print, "ERROR : Found an arc with",strcompress(curinfo[6]), " points"
        print, "ERROR : PROGRAM DOES NOT SUPPORT ARCS WITH MORE THAN", $
               strcompress(maxPoints)," POINTS BY DEFAULT"
        print, "   To avoid this re run with keyword maxPoints set to a value"
        print, "   greater than", strcompress(curinfo[6])
        ;; we could dynamically fix this but it would be a little tricky
        ;;  so just report an error for now... readCNT solves this well,
        ;;  I should implement that solution here... eventually
        return, -1
     ENDIF

     ;; read all coordinates on the current arc, there are two on each line
     curarc=dblarr(2,maxPoints)
     FOR i=0, curinfo[6]-1, 2 DO BEGIN
;        IF eof(un) THEN return, -1  ; uncomment this line to enable slower error checking
        readf, un, line
        curline=double(strsplit(line, /extract))
        curarc[*,i]=curline[0:1]
        IF NOT (i EQ curinfo[6]-1) THEN $
          curarc[*,i+1]=curline[2:3]
     endFOR
     
;; if this is the first arc store it in the arcs variable, else add it to the list of arcs
     IF n_elements(arcs) EQ 0 THEN $
       arcs={info:curinfo, points:curarc} ELSE $
       arcs=[arcs, {info:curinfo, points:curarc}]
     
;     IF eof(un) THEN return, -1  ; uncomment this line to enable more error checking
     readf, un, line
  endWHILE

  return, arcs
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; readCNT reads the "CNT" section of an e00 file (if it exists) and returns
;;   an array of [info(3), labels(n)] x n_centers
;;     info = a 3 element array :
;;       [n_labels, center_x, center_y]
;;     labels = a n_labels array :
;;       each label is a reference into the LAB section which in turn references
;;       the PAT section
;;
;;  note that for the sevregsoil312.e00 file this function could be replaced with
;;    indgen(505) to get the labels (not the polygon centers obviously)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION readCNT, un
  line=''
  curlabel=0
  maxPolys=5000
  maxLabels=10
  centers=dblarr(maxLabels, maxPolys)

;; find the beginning of the Center section
  IF NOT findLine(un, 'CNT *') THEN return, -1

  curcenter=0
  readf, un, line
;; keep reading in centers until we hit the end of the CNT section (defined by -1 0 0 0...)
  WHILE NOT $
    strmatch(line, '        -1         0         0         0         0         0         0') $
    AND NOT eof(un) DO BEGIN
     info=double(strsplit(line, /extract))

;; error checking and correction
     WHILE info[0] GT maxLabels-3 DO BEGIN 
        centers=[centers, dblarr(maxLabels, maxPolys)]
        maxLabels*=2
     ENDWHILE
     
;; read in the labels
     centers[0:2,curcenter]=info
     FOR i=3,info[0]+2 DO BEGIN
;        IF eof(un) THEN return, -1
        readf, un, curlabel
        centers[i,curcenter]=curlabel
     endFOR
     curcenter++

;; error checking and correction
     WHILE curcenter GE maxPolys DO BEGIN
        centers=[[centers],[dblarr(maxLabels,maxPolys)]]
        maxPolys*=2
     ENDWHILE

     readf, un, line
  ENDWHILE

  return, centers[*,0:curcenter-1]
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; read the LAB label section return a double array of 4xn_polygon 
;;   [coverage ID, polygonID, x_coord, y_coord]
;;
;; return, -1 on error
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION readLAB, un
  line=''
  maxPolys=5000
  labels=dblarr(4,maxPolys)
  i=0
 
  IF NOT findLine(un, 'LAB *') THEN return, -1
  
  readf, un, line
  WHILE NOT strmatch(line, '        -1         0 0.0000000E+00 0.0000000E+00') $
    AND NOT eof(un) DO BEGIN

     labels[*,i]=double(strsplit(line, /extract))
     i++

     ;;skip the "label box window" as it is not used
     readf, un, line
     IF NOT eof(un) THEN readf, un, line

;; error checking and correction
     IF i GE maxPolys THEN BEGIN
        labels=[[labels],[dblarr(4,maxPolys)]]
        maxPolys*=2
     ENDIF
  ENDWHILE

  return, labels[*,0:i-1]
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Read the polygon topology PAL section
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION readPAL, un
  line=''
  maxPolys=5000
  maxArcs=500*3
  polys=intarr(maxArcs,maxPolys)
  info=dblarr(5,maxPolys)
  i=0
  
  IF NOT findLine(un, 'PAL *') THEN return, -1

  readf, un, line
  done= strmatch( $
         line, '        -1         0         0         0         0         0         0') $
        OR eof(un) 
  WHILE NOT done DO BEGIN
     
     info[*,i]=double(strsplit(line, /extract))

; error checking and correction
     IF info[0,i]*3 GT maxArcs THEN BEGIN
        polys=[polys,intarr(maxArcs, maxPolys)]
        maxArcs*=2
     ENDIF

     FOR j=0,info[0,i]-2, 2 DO BEGIN
        readf, un, line
        polys[j*3:(j*3+5),i]=fix(strsplit(line, /extract))
     ENDFOR

     IF info[0,i] MOD 2 EQ 1 THEN BEGIN
        readf, un, line
        polys[j*3:(j*3+2),i]=fix(strsplit(line, /extract))
     ENDIF

     i++
     readf, un, line
     
     done= strmatch( $
            line, '        -1         0         0         0         0         0         0') $
           OR  eof(un) 

;; error checking and correction
     IF i GE maxPolys AND NOT done THEN BEGIN
        polys=[[polys],[dblarr(maxArcs,maxPolys)]]
        info=[[info],[dblarr(5,maxPolys)]]
        maxPolys*=2
     ENDIF
  ENDWHILE

  return, {arcs:polys[*,0:i-1], info:info[*,0:i-1]}
END



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Parse a parameter, value pair into the projInfo struct
;; 
;;  Right now we probably only handle UTM projections correctly
FUNCTION storeInfo, projInfo, param, value
  CASE param OF 
     "Projection" : projInfo.name=value
     "Zone"       : projInfo.zone=fix(value)
     "Datum"      : projInfo.datum=value
     "Zunits"     : projInfo.Zunits=value
     "Units"      : projInfo.units=value
     "Spheroid"   : projInfo.sphere=value
     "Xshift"     : projInfo.xshift=value
     "Yshift"     : projInfo.yshift=value
     "Parameters" : projInfo.param=value

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
FUNCTION readPRJ, un
  line=''
;; initialize the structure.  None of the structure elements on the second line are
;; actually used currently
  projInfo={name:"", zone:-1, datum:"", units:"", $
            Zunits:"", sphere:"", xshift:0.0, yshift:0.0, param:""}

  IF NOT findLine(un, 'PRJ *') THEN return, -1

;; read through the rest until we hit the End Of Prj (EOP) tag
;;   parsing the lines as we go
  readf, un, line
  WHILE line NE "EOP" AND NOT eof(un) DO BEGIN
     IF line NE "~" THEN BEGIN
        newLine=strsplit(line, /extract)
        param=newLine[0]
        IF n_elements(newLine) GT 1 THEN $
          value=newLine[1]
        IF NOT storeInfo(projInfo, param, value) THEN return, -1
     ENDIF
     readf, un, line
  ENDWHILE

;; if we made it this far we done well, so return the results
  return, projInfo
END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Read the BND info file.  it should just contain the UTM boundaries.
;;
;; Currently it assumes a fairly strict file format, so if the file is not
;;   as expected, things can go badly
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION readBND, un
  line=""

  IF NOT findLine(un, "*.BND *", /saveLine) THEN return, -1
  FOR i=0,5 DO readf, un, line
  
  return, double(strsplit(line, /extract))
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; read the Look Up Table data from the info section of the e00 file.  
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION readLUT, un
  line=""
  IF NOT findLine(un, "*.LUT *", /saveline) THEN return, -1
  readf, un, line
  n_records=fix((strsplit(line, /extract))[4])
  values=strarr(n_records)
  names=strarr(n_records)
  index=intarr(n_records)
  symbols=intarr(n_records)

  FOR i=1,5 DO readf, un, line

  FOR i=0, n_records-1 DO BEGIN
     readf, un, line

     index[i]=fix(strmid(line, 0,4))
     symbols[i]=fix(strmid(line, 4,4))
     values[i]=strmid(line, 8,15)
     names[i]=strmid(line, 23,60)
     IF NOT eof(un) THEN readf, un, line
     IF eof(un) THEN return, -1
  endFOR
  
  return, {index:index,symbols:symbols,values:values,names:names}
END

FUNCTION readPAT, un
  line=""
  
  IF NOT findLine(un, "*.PAT *", /saveline) THEN return, -1

  readf, un, line
  n_records=fix((strsplit(line, /extract))[5])
  
  soilNum = intarr(n_records)
  soilID  = intarr(n_records)
  soil    = intarr(n_records)

  FOR i=1,5 DO readf, un, line

  FOR i=0,n_records-1 DO BEGIN
     readf, un, line
     tmp=strsplit(line, /extract)
     soilNum[i]=fix(tmp[2])
     soilID[i]=fix(tmp[3])
     IF n_elements(tmp) EQ 5 THEN $
       soil[i]=fix(tmp[4])

     IF eof(un) THEN return, -1
  ENDFOR

  return, {soilNum:soilNum, soilID:soilID, soil:soil}

END


FUNCTION readIFO, un
  line=""
  IF NOT findLine(un, "IFO *") THEN return, -1
  
  bounds=readBND(un)
  LUT=readLUT(un)
  PAT=readPAT(un)

  return, {bounds:bounds,LUT:LUT,PAT:PAT}
END

FUNCTION read_holes, polyList, arcs, centers, labels, info, i, initialArc
  n_arcs=polyList.info[0,i]
  n_coords=0
  last=0
  maxHoles=100
  curhole=0

  n_points=lonarr(maxHoles)
  x=dblarr(500l*n_arcs,maxHoles)
  y=dblarr(500l*n_arcs,maxHoles)
  FOR j=initialArc,n_arcs-1 DO BEGIN 
     
     IF polyList.arcs[j*3,i] EQ 0 THEN BEGIN 
        n_points[curhole]=n_coords
        curhole++ 
        n_coords=0
        last=0
     endIF ELSE IF polyList.arcs[j*3,i] GT 0 THEN BEGIN 
        x[last:n_coords-1,curhole]= arcs[curArc].points[0,0:curPoints-1]
        y[last:n_coords-1,curhole]= arcs[curArc].points[1,0:curPoints-1]
     endIF ELSE BEGIN 
        x[last:n_coords-1,curhole]= reverse(arcs[curArc].points[0,0:curPoints-1],2)
        y[last:n_coords-1,curhole]= reverse(arcs[curArc].points[1,0:curPoints-1],2)
     ENDELSE

  ENDFOR
  maxPoints=max(n_points)
  return, {n_holes:curhole+1, n_points:n_points[0:curhole], $
           x:x[0:maxPoints-1,0:curhole], y:y[0:maxPoints-1,0:curhole]}

END

;; take the Polygon topology, arc coordinates, and attribut info and make a polygon
FUNCTION makePoly, polyList, arcs, centers, labels, info, i

  n_arcs=polyList.info[0,i]
  n_coords=0
  last=0
  pause=''
;  curPoly={value:0, $
;           x:dblarr(n_elements(arcs[i].points[0,*]*n_arcs)), $
;           y:dblarr(n_elements(arcs[i].points[0,*]*n_arcs)), $
;           n:0}

  x=dblarr(500l*n_arcs)
  y=dblarr(500l*n_arcs)
  n_holes=0
  FOR j=0,n_arcs-1 DO BEGIN
     curArc=abs(polyList.arcs[j*3,i])-1
     
     ;; if curArc == -1 then we polyList.arcs=0 and is invalid?
     IF curArc NE -1 THEN BEGIN 
        curPoints=arcs[curArc].info[6]
        n_coords+=curPoints
        
        IF polyList.arcs[j*3,i] GT 0 THEN BEGIN 
           x[last:n_coords-1]= arcs[curArc].points[0,0:curPoints-1]
           y[last:n_coords-1]= arcs[curArc].points[1,0:curPoints-1]
        endIF ELSE BEGIN 
           x[last:n_coords-1]= reverse(arcs[curArc].points[0,0:curPoints-1],2)
           y[last:n_coords-1]= reverse(arcs[curArc].points[1,0:curPoints-1],2)
        ENDELSE

        last=n_coords
        
     endIF ELSE BEGIN 
        n_holes++
        BREAK
     endELSE 
  ENDFOR

  holes={n_holes:0,n_points:0,x:0,y:0}

;  IF n_holes GT 0 THEN holes=read_holes(polyList, arcs, centers, labels, info, i, j)

  IF centers[3,i] EQ 0 THEN value = 0 ELSE $
    value=info.PAT.soil[labels[0,centers[3,i]-1]]

  IF n_coords LE 1 THEN $
    return, {n:0,value:0,x:0,y:0,holes:holes}

  return, {n:n_coords,value:value,x:x[0:n_coords-1],y:y[0:n_coords-1], holes:holes}

END

FUNCTION getGeo, proj, bounds
  return, 0
END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; getPolys takes an e00File name as input, reads the file and returns a structure
;;   with the bounds of the polygon, the list of polygons, and the projection
;;
;; All real work is done by separate subroutines
;;
;; returns -1 on error
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION getPolys, e00File, maxPoints=maxPoints
  openr, e00, /get, e00File
  line=''
  readf, e00, line ; EXP  0 /PATH/TO/ORIGINAL/EXPORT/FILE

  print, 'Reading arcs...'
  arcs=readARC(e00, maxPoints=maxPoints)
;  IF arcs EQ -1 THEN return, -1

  print, 'Reading centers...'
  centers=readCNT(e00)
;  IF centers EQ -1 THEN return, -1
  
  print, 'Reading labels...'
  labels=readLAB(e00)
;  IF labels EQ -1 THEN return, -1

  print, 'Reading polygon topology...'
  polyList=readPAL(e00)
;  IF polyList EQ -1 THEN return, -1
  
  print, 'Reading projection...'
  projection=readPRJ(e00) ; this will skip over TOL, SIN, and LOG
;  IF projection EQ -1 THEN return, -1
  
  print, 'Reading info...'
  info=readIFO(e00)
;  IF info EQ -1 THEN return, -1

  close, e00
  free_lun, e00

  print, 'Compiling information and returning...'
  return, {bounds:info.bounds, $
           polys:polyList, $
           arcs:arcs, $
           centers:centers, $
           labels:labels, $
           info:info, $
           geo:getGeo(projection, info.bounds)}
END

  
PRO e00_Poly2Tiff, e00File, tiffFile, resolution
  ;; default value for resolution = 1000m (1km)
  IF n_elements(resolution) EQ 0 THEN resolution = 1000

  ;; this is where we do most of the work
  result=getPolys(e00File)
;  IF result EQ -1 THEN return
;  IF result.polys EQ -1 OR result.geo EQ -1 THEN return


  ;; calculate the number of pixels needed in the output tiff
  ;;  and make an array for that output
  N_x = fix(abs(result.bounds[0]-result.bounds[2])/resolution)+1
  N_y = fix(abs(result.bounds[1]-result.bounds[3])/resolution)+1
  img=uintarr(N_x, N_y)

  ;; loop through all polygons filling in the appropriate area of
  ;;   the output image
  FOR i=0, n_elements(result.centers[0,*])-1 DO BEGIN

     ;; polyfillv returns the indexs into the img array that should be filled by a
     ;; polygon surrounded by the x,y pairs given.  x and y are converted into image
     ;; coordinates by subtracting the minimum UTM values and dividing by the resolution
     curpoly=makePoly(result.polys,result.arcs,result.centers,result.labels,result.info,i)
     IF curpoly.n NE 0 THEN BEGIN 
        index=polyfillv((curpoly.x-result.bounds[0])/resolution, $
                        (curpoly.y-result.bounds[1])/resolution, $
                        N_X, N_Y)
        
        ;; set the positions in the image defined by pollyfillv to the value defined in
        ;;  the e00 file for this polygon
        IF curPoly.holes.n_holes GT 0 THEN $
          saveholes=img
        
        img[index]=curpoly.value

        IF curPoly.holes.n_holes GT 0 THEN BEGIN 
           FOR curHole=0, curPoly.holes.n_holes-1 DO BEGIN
              curpoints=curPoly.holes.n_points[curHole]-1
              index=polyfillv((curPoly.holes.x[0:curpoints,curHole]-result.bounds[0])/resolution, $
                              (curPoly.holes.y[0:curpoints,curHole]-result.bounds[1])/resolution, $
                              N_X,N_Y)
              img[index]=saveholes[index]
           ENDFOR
        ENDIF

     endIF 
  ENDFOR

  ;; write the resulting geotiff
  write_tiff, tiffFile, img, /short ;, geotiff=result.geo

END
