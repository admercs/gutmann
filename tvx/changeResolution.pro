function changeResolution, inputFiles, ratio, curRes
;; process the NDVI input and output filenames
  fileBase=strsplit(inputFiles.ndvi, ".", /extract)
  suffix=fileBase[n_elements(fileBase)-1]
;; hack off the old extension (.masked or .curres)
  fileBase=file_basename(inputFiles.ndvi, suffix)
  outndvi=fileBase+"."+strcompress(curRes, /remove_all)

;; process the NDVI input and output filenames
  fileBase=strsplit(inputFiles.thermal, ".", /extract)
  suffix=fileBase[n_elements(fileBase)-1]
;; hack off the old extension (.masked or .curres)
  fileBase=file_basename(inputFiles.ndvi, suffix)
  outthermal=inputFiles.thermal+"."+strcompress(curRes, /remove_all)

;; process the ndvi data
  data=read_tiff(inputFiles.ndvi)
  sz=size(data)
  ;; resize the ndvi data
  newData=resizeImg, data, sz[1], sz[2], sz[1]/ratio, sz[2]/ratio
  write_tiff, newData, outndvi

;; process the thermal data  
  data=read_tiff(inputFiles.thermal)
  sz=size(data)
  ;; resize the thermal data
  newData=resizeImg, data, sz[1], sz[2], sz[1]/ratio, sz[2]/ratio
  write_tiff, newData, outthermal
  
  return, {ndvi:outndvi, thermal:outthermal}
end
