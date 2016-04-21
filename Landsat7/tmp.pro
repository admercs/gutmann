
pro FileToNDVI, fname, outfile
  info=getFileInfo(fname)
  bandsize=info.ns*info.nl*info.type
  
;; Read in bands 3 and 4 from the input file
  openr, un, /get, fname

;;skip over the first 2 bands
  point_lun, un, bandsize*2l
  
  b3=intarr(info.ns, info.nl)
  b4=intarr(info.ns, info.nl)
  readu, un, b3
  readu, un, b4

;; Calculate NDVI
  NDVI=byte( ((FLOAT(b4-b3)/FLOAT(b4+b3))>0) *255 )

;; Write NDVI to disk
  openw, oun, /get, outfile
  writeu, oun, NDVI

  close, un, oun
  free_lun, un, oun

;; write the ENVI header file for the NDVI image
  info.nb=1
  info.type=1
  info.desc='NDVI from reflectance file {OLD DESCRIPTION: '+info.desc+'}'

  setENVIhdr, info, outfile
end
