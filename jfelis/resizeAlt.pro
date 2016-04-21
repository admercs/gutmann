function resizeAlt, inputFile, ratio, curRes
;; process the NDVI input and output filenames
  fileBase=strsplit(inputFile, ".", /extract)
  fileBase=fileBase[0]
;; hack off the old extension (.masked or .curres)
;  fileBase=file_basename(inputFiles.ndvi, suffix)
  outfile=fileBase+"."+strcompress(curRes, /remove_all)+'.tif'

;; process the ndvi data
  data=read_tiff(inputFile)
  sz=size(data)
  ;; resize the ndvi data
  newData=resizeImg(data, sz[1], sz[2], sz[1]/ratio, sz[2]/ratio, inputFile)
  write_tiff, outfile, uint(newData), /short

  return, outfile
end
