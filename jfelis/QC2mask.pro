;; reads a MODIS QC file and generates a mask for all pixels that are
;; generally considered "good".  Bad pixels are zero, good pixels are 1
PRO QC2mask, QCfname, maskfname

  res=query_tiff(QCfname, info)
;; this is the line where we do the real work
  sz=info.dimensions
  mask=make_array(sz[0],sz[1], type=1)

  for i=0, sz[1]-1 do begin
      data=read_tiff(QCfname, geotiff=geoinfo, sub_rect=[0,i,sz[0],1])
      maskDex=where((data mod 4) eq 0)
      if maskDex[0] ne -1 then $
        mask[maskDex, i]=1
  endfor
  write_tiff, maskfname, mask, geotiff=geoinfo
end
