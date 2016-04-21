function changeResolution, inputFiles, ratio, curRes
;; process the NDVI input and output filenames
  fileBase=strsplit(inputFiles.ndvi, ".", /extract)
  fileBase=fileBase[0]
;; hack off the old extension (.masked or .curres)
;  fileBase=file_basename(inputFiles.ndvi, suffix)
  outndvi=fileBase+"."+strcompress(curRes, /remove_all)+'.tif'

;; process the NDVI input and output filenames
  fileBase=strsplit(inputFiles.thermal, ".", /extract)
  fileBase=fileBase[0]
;; hack off the old extension (.masked or .curres)
;  fileBase=file_basename(inputFiles.ndvi, suffix)
  outthermal=fileBase+"."+strcompress(curRes, /remove_all)+'.tif'

;; process the ndvi data
  data=read_tiff(inputFiles.ndvi)
  sz=size(data)
  ;; resize the ndvi data
  newData=resizeImg(data, sz[1], sz[2], sz[1]/ratio, sz[2]/ratio, inputFiles.ndvi)
  write_tiff, outndvi, uint(newData), /short

;; process the thermal data  
  data=read_tiff(inputFiles.thermal)
  sz=size(data)
  ;; resize the thermal data
  newData=resizeImg(data, sz[1], sz[2], sz[1]/ratio, sz[2]/ratio, inputFiles.thermal)
  newData>=0
  write_tiff, outthermal, uint(newData), /short
  
  return, {ndvi:outndvi, thermal:outthermal}
end
