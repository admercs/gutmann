pro buffer100Lines, INfname, OUTfname, buffer=buffer
  if not keyword_set(buffer) then buffer=100

  data=read_tiff(INfname, geotiff=geoinfo)
  sz=size(data)
  newData=make_array(sz[1]+2*buffer, sz[2]+2*buffer, type=sz[3])
  newData[buffer-1:sz[1]+buffer-2,buffer-1:sz[2]+buffer-2]=data

  data=0
  
  geoinfo.modeltiepointtag[3]-=buffer*geoinfo.modelpixelscaletag[0]
  geoinfo.modeltiepointtag[4]+=buffer*geoinfo.modelpixelscaletag[1]

  type=sz[3]
  
  CASE type OF
     1:  write_tiff, OUTfname, newData, geotiff=geoinfo
     2:  write_tiff, OUTfname, uint(long(newData)+10000), $
                     geotiff=geoinfo, /short
     3:  write_tiff, OUTfname, ulong(long64(newData)+ulong64(2)^32), $
                     geotiff=geoinfo, /long
     4:  write_tiff, OUTfname, newData, geotiff=geoinfo, /float
     12: write_tiff, OUTfname, newData, geotiff=geoinfo, /short
     13: write_tiff, OUTfname, newData, geotiff=geoinfo, /long
  ENDCASE 
END 
