;+
; NAME: resizeImg
;
; PURPOSE: resize a geotiff and compute the standard deviation of the
;   values used to generate each new pixel.  Output two image files.  
;
; CATEGORY: Image manipulation, geotiff
;
; CALLING SEQUENCE: resizeImg, "inputfile", "outputfileBASENAME",
;                              out_numberofSamples, out_numberofLines
;
; INPUTS: input geotiff filename, output filename (without the .tif)
;
; OPTIONAL INPUTS: badVal
;
; KEYWORD PARAMETERS:
;      badVal=badVal  set this equal to the value in the input file
;                     you want to ignore.  Default is -3000 (it will
;                     also ignore badVal-1)
;
; OUTPUTS:  outfilefileBASENAME+"_data.tif"
;           outfilefileBASENAME+"_stdev.tif"
;
; OPTIONAL OUTPUTS:
;
; COMMON BLOCKS: <none>
;
; SIDE EFFECTS: <none>
;
; RESTRICTIONS: <none>
;
; PROCEDURE: 
;
;
;
; EXAMPLE: resizeImg, "input.tif", "output", 1000,2000, badVal=-9999
;
;
; MODIFICATION HISTORY:
;          2003/2004?-edg - original
;          11/3/04  - edg - serious rewrite to read one line of a geotiff
;                           file at a time and add the badVal keyword
;
;-

PRO resizeImg, fname, outfname, out_ns, out_nl, badVal=badVal

  IF NOT keyword_set(badVal) THEN badVal=-3000

  res=query_tiff(fname, info)
  in_ns=info.dimensions[0]
  in_nl=info.dimensions[1]

  ratioS=float(in_ns)/out_ns
  ratioL=float(in_nl)/out_nl

;; create output arrays
  newData=fltarr(out_ns,out_nl)
  stdData=fltarr(out_ns,out_nl)

;; loop through all of the pixels in the new image averaging
;;   and computing standard deviations appropriately
  for j=0, out_nl-1 do begin

;; read in data for the current output line
     startY=round(j*ratioL)
     endY=round((j+1)*ratioL)

     sr=[0,round(j*ratioL), in_ns, endY-startY]
     data=read_tiff(fname, geotiff=geotiff, sub_rect=sr)
     FOR i=0, out_ns-1 DO begin
;; as long as we know the ratio of old pixels to new pixels (and
;;   it is an integer), we can just calculate which pixels to use, this
;;   saves calling where on a potentially HUGE array over and over again
        curData=data[round(ratioS*i):round(ratioS*(i+1)-1), *]

;; calling where on a small array is cheap computationally
        index = where(curData NE badVal and curData NE badVal-1)
;; if there were no valid data points than store 9999 in the output
        if index[0] eq -1 then begin
           newData[i,j]=badVal
           stdData[i,j]=badVal
        endif else begin
;; otherwise compute the mean and standard deviation
           newData[i,j]=mean(curData[index])
           IF n_elements(index) GT 1 THEN BEGIN 
              stdData[i,j]=stdev(curData[index])
           endIF ELSE stdData[i,j]=badVal
        endelse
     ENDFOR
  endFOR

;; change the pixel size in the output geotiff
  geotiff.MODELPIXELSCALETAG[0]*=ratioS
  geotiff.MODELPIXELSCALETAG[1]*=ratioL

  write_tiff, outfname+"_stdev.tif", stdData, geotiff=geotiff, /float
  write_tiff, outfname+"_data.tif", newData, geotiff=geotiff, /float

END
