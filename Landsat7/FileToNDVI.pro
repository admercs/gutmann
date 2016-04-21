
PRO FileToNDVI, fname, outfile
  info=getFileInfo(fname)
  bandsize=long(info.ns)*info.nl*info.type
  
;; Read in bands 3 and 4 from the input file
  OPENR, un, /get, fname

;;skip over the first 2 bands
  POINT_LUN, un, bandsize*2l
  
  b3=MAKE_ARRAY(info.ns, info.nl, type=info.type)
  b4=MAKE_ARRAY(info.ns, info.nl, type=info.type)
  READU, un, b3
  READU, un, b4

;  window, xs=1000, ys=1000
;  tvscl, b3[2000:3000,2000:3000]
  print, min(b3), max(b3)
;  wait, 10
;  tvscl, b4[2000:3000,2000:3000]
  print, min(b4), max(b4)

;; Calculate NDVI
  top=b4-b3
  bot=b4+b3
;  tvscl, top[2000:3000,2000:3000]
  print, min(top), max(top)
;  tvscl, bot[2000:3000,2000:3000]
  print, min(bot), max(bot)

  n1=float(top)/bot
  print, min(n1), max(n1)
  n2=fix((n1>0)*10000)
  print, min(n2), max(n2)

  NDVI=FIX( (((FLOAT(b4)-b3)/(FLOAT(b4)+b3))>0) *10000 )
  print, min(NDVI), max(NDVI)
;; Write NDVI to disk
  OPENW, oun, /get, outfile
  WRITEU, oun, NDVI

  CLOSE, un, oun
  FREE_LUN, un, oun

;; write the ENVI header file for the NDVI image
  info.nb=1
  info.type=2
  info.desc=string('NDVI from reflectance file '+fname+ $
                   ' {OLD DESCRIPTION: '+info.desc+'}')

  setENVIhdr, info, outfile
END

