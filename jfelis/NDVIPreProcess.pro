pro NDVIPreProcess, ndvifile, QCmaskfile, outputFile
  data=read_tiff(ndvifile, geotiff=geotiff)
  sz=size(data)
  for i=0, sz[2]-1 do begin
      mask=read_tiff(QCmaskfile, sub_rect=[0,i,sz[1],1])
      dex=where(mask eq 0)
      if dex[0] ne -1 then data[dex,i] = 1
  endfor

  newdat=resizeImg(data, sz[1],sz[2],sz[1]/4, sz[2]/4)

  geotiff.modelpixelscaletag=geotiff.modelpixelscaletag*4
  write_tiff, outputFile, uint(newdat), geotiff=geotiff, /short
end
