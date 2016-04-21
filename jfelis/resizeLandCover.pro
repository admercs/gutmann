FUNCTION mode, data
  map=intarr(30)

  map[data]++
  mostvals=max(map)
  dex=where(map EQ mostvals)
  IF n_elements(dex) GT 1 THEN return, 16 $ ; 16 is our null value (water)
  ELSE return, dex
END


FUNCTION resizeLandCover, landCoverMap, scaleDownBy, newRes

  outfile=(strsplit(landCoverMap, '.', /extract))[0]+"."+ $
          strcompress(newRes, /remove_all)+".tif"

  IF n_elements(scaleDownBy) EQ 0 THEN scaleDownBy =2

  data=read_tiff(landCoverMap, geotiff=geotiff)
  
  sz=size(data)
  ns=sz[1]
  nl=sz[2]
  out_ns=ns/scaleDownBy
  out_nl=nl/scaleDownBy
  ratioS=scaleDownBy
  ratioL=scaleDownBy

  newData=uintarr(ns/scaleDownBy, nl/scaleDownBy)

  FOR i=0l, n_elements(newData)-1 DO BEGIN

     ;; integer division and modulo arithmetic.
     curS= i MOD out_ns
     curL= i / out_ns

     ;; not entirely sure about the -1 part...
     curData=data[ratioS*curS:(ratioS*curS)+ratioS-1, $
                  ratioL*curL:(ratioL*curL)+ratioL-1]

     ;; calling where on a small array is cheap computationally
     index = where(curData NE 16)  ;; 16 = water
     ;; if there were no valid data points than store 16 (water) in the output
     if index[0] eq -1 then begin
        newData[i]=16
     endif else begin
        ;; otherwise compute the mean and standard deviation
        newData[i]=mode(curData[index])
     endelse
  ENDFOR

  geotiff.MODELPIXELSCALETAG*=scaleDownBy
  write_tiff, outfile, newData, geotiff=geotiff
  return, outfile
END
