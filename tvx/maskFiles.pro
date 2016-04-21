;; Takes two input files and a mask file.
;; Masks the input files and subsets them down to the smallest area with data.
;; Returns the filenames of the output files
function maskFiles, inputFiles, maskfile

; input filenames
  thermalFile=inputFiles.thermal
  ndviFile = inputFiles.ndvi

;output filenames
  outNDVIfile=ndviFile+".masked"
  outThermalfile=thermalFile+".masked"

; input data
  ndvi_data=read_tiff(ndviFile)
  thermal_data=read_tiff(thermalFile)

; mask file data
  maskinfo=readENVIhdr(maskfile)
  maskdata=make_array(maskinfo.ns, maskinfo.nl, type=maskinfo.type)

;; perform the actual masking  
  index=where(maskdata eq 0)
  ndvi_data[index]=-9999
  thermal_data[index]=-9999

;; compute x pixel locations in the mask  
  x=index mod maskinfo.ns
;; compute y pixel locations in the mask  
  y=index / maskinfo.ns

;; compute new image bounds for the subset
  minx=min(x)
  maxx=max(x)
  miny=min(y)
  maxy=max(y)
  
;; subset the ndvi and thermal data
  outndvi=ndvi_data[minx:maxx,miny:maxy]  
  outthermal=thermal_data[minx:maxx,miny:maxy]

;; write the output data
  write_tiff, outNDVIfile, outndvi  
  write_tiff, outThermalfile, outthermal

;; return the new filenames  
  return, {ndvi:outNDVIfile, thermal:outThermalfile}
end
