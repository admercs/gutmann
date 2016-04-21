;; takes the filename for a red band and the filename for a NIR band,
;; outputs an NDVI file scaled by 10000 to the input ndvi filename
PRO makeNDVI, redfname, NIRfname, ndvifname
;; read the input data
  red=read_tiff(redfname)
  nir=read_tiff(NIRfname, geotiff=geoinfo)

;; hack to get the smallest xy size though they SHOULD be the same  
  sz=size(red)
  sz2=size(nir)
  realsz=min([sz[1],sz2[1]])
  realsz=[realsz,min([sz[2],sz2[2]])]
  sz[1:2]=realsz

;; make the NDVI image
  ndvi=intarr(sz[1],sz[2])
  for i=0,sz[2]-1 do begin
    ndvi[*,i]=fix(10000*(float(nir[*,i])-red[*,i])/(nir[*,i]+red[*,i]))
    
    
;; make the minimum ndvi value be -4000
    lowNDVI=where(ndvi[*,i] LT -4000)
    IF lowNDVI[0] NE -1 THEN ndvi[lowNDVI,i] = -4000

;; mask out values that were originally -9999 or 0
    badIndex=where(nir[*,i] EQ -9999 $
                   OR (nir[*,i] EQ 0 AND red[*,i] EQ 0) $
                   OR red[*,i] EQ -9999)
    IF badIndex[0] NE -1 THEN ndvi[badIndex,i] = -9999
 ENDFOR

;; write the output file
  write_tiff, ndvifname, 10000+ndvi, geotiff=geoinfo, /short
END 
