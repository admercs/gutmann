;; assumes two bands of longs.  1st band = NDVI, 2nd band = QA
;;  also assumes BSQ format
pro MODmask, fname
  info=readENVIhdr(fName)

  NDVIproduced=2l
  NDVIbad=1l
  utility=2l^2 + 2l^3 + 2l^4 + 2l^5
  aerosol=2l^6 + 2l^7
  adjacency=2l^8
  atmBRDF=2l^9
  clouds=2l^10
  landWater=2l^11 + 2^12
  snowIce=2l^13
  shadow=2l^14
  model=2l^15
  
  openr, un, /get, fname
;  point_lun, un, info.ns * info.nl * 4 ;4bytes = size of a long
;  data=assoc(un, lonarr(info.ns, info.nl, info.nb))
  data=lonarr(info.ns, info.nl, info.nb)
  mask=bytarr(info.ns, info.nl)
  readu, un, data
  QA = data(*,*,1)

  first = QA and NDVIproduced
  second= QA and NDVIbad
  value = (QA and utility)/4
  vdex=where(value lt 7)

  dex=where((first eq 0 and second eq 0) or $
            (first eq 0 and second gt 0 and value lt 6), complement=badPix)
  if dex(0) ne -1 then $
    mask(dex)=1

  
;  window, 0, xsize=1000,ysize=1000
  print, fname
  tvscl, congrid(mask(*,*), 1000,1000), /order
  img=data(*,*,0)
  img(badPix) = 0
  tvscl, congrid(img, 1000,1000), /order

  snow  = QA and snowIce
  sdex=where(snow gt 0)
  img(sdex) = 0
  tvscl, congrid(img, 1000,1000), /order
;  window, 1, xsize=1000,ysize=1000
;   tvscl, congrid(QA,1000,1000)
;   wait, 10
;   print, 'PRODUCED? bright = bad'
;   tvscl, congrid(QA and NDVIproduced, 1000, 1000)
;   wait, 10
;   print, 'Quality? bright=bad'
;   tvscl, congrid(QA and NDVIbad, 1000, 1000)
;   wait, 10
;   tvscl, congrid(QA and utility, 1000, 1000)
;   wait, 10
;   tvscl, congrid(QA and aerosol, 1000, 1000)
;   wait, 10
;   tvscl, congrid(QA and adjacency, 1000, 1000)
;   wait, 10
;   tvscl, congrid(QA and atmBRDF, 1000, 1000)
;   wait, 10
;   tvscl, congrid(QA and clouds, 1000, 1000)
;   wait, 10
;   tvscl, congrid(QA and shadow, 1000, 1000)
;   wait, 10
;   tvscl, congrid(QA and model, 1000, 1000)
;   wait, 10

  close, un
  free_lun, un
end

  
