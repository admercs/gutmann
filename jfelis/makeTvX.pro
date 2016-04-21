
;; read the file list in from the input file
;;
;; input file should be a text file that has a mask file on each line
;; followed by a reflectance (NDVI?) directory, and a thermal
;; directory.  
FUNCTION getFileList, inputfile
  openr, un, /get, inputfile
  line=""
  n=0

  readf, un, line
  mountainMask=line

  files=""
  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     files=[files, line]
  endWHILE
  nfiles=n_elements(files)
  files=files[1:nfiles-1]
  nfiles--
  
;; the first n-2 files are the subset mask files, the last 2 files are
;; the data directory filenames
  n=nfiles-2

  return, {mountainMask:mountainMask, nmasks:n, subsetMask:files[0:n-1], $
           data:files[nfiles-2:nfiles-1]}
END


;; search through the ndvi directory for all files matching the day
;; ditto for the thermal directory
FUNCTION selectfilesfor, day, dirNames
return, {ndvi:file_search(dirNames[0]+ $
                          '2001_'+strcompress(day, /remove_all)+ $
                          '_1kmNDVI.tif'), $
         thermal:file_search(dirNames[1]+ $
                             '2001_'+strcompress(day, /remove_all)+ $
                             '_mosaic.LST*sub_masked.tif')}
END


PRO makeTvX, inputfile, fast=fast

  files=getFileList(inputfile)
  
;;  loop through all days of interest
  FOR day =222, 226 DO BEGIN
     curdayFiles=selectfilesfor(day, files.data)
     print, curdayFiles
     curdayFiles=maskFiles(curdayFiles, files.mountainMask)


;; loop over three subsets
     FOR subset=0,files.nmasks DO BEGIN
         if subset eq 0 then maskFileNames=curdayFiles else $
           maskFileNames=maskFiles(curdayFiles, files.subsetMask[subset-1])

;; loop over resolution (2^x) 1km -> 32km
        oldres=1 ;km
        plotFile='2001_'+strcompress(day, /remove_all)+ '_'+$
          strcompress(subset,/remove_all)+ '_'+$
          strcompress(oldRes, /remove_all)+'km.ps'
        print, "plotting : ", plotFile
        plotTvX, maskFileNames, plotFile, day, oldRes, subset
        densplot, maskFileNames.ndvi, maskFileNames.thermal, plotFile+'_dense.tif', $
          lowx=10000, hix=20000, lowy=14500, hiy=17000
        FOR resolution=1,5 DO BEGIN
           curRes=fix(2.^resolution)
           print, ""
           print, "-----------------------------------"
           print, "    ", strcompress(fix(curRes)), " km"
           
           plotFile='2001_'+strcompress(day, /remove_all)+'_'+ $
                    strcompress(subset,/remove_all)+'_'+$
                    strcompress(curRes, /remove_all)+'km'

           resFiles=changeResolution(maskFileNames,curRes/oldres, curRes)
           print, "plotting : ", plotFile
           plotTvX, resFiles, plotFile+'.ps', day, curRes, subset
           densplot, resFiles.ndvi, resFiles.thermal, plotFile+'_dense.tif', $
                     lowx=8000, hix=20000, lowy=13500, hiy=17000
           oldres=curRes
           maskFileNames=resfiles
        endFOR
     ENDFOR
  ENDFOR

END

