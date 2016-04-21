PRO makeTvX, inputfile

  files=getFileList(inputfile)
  
;;  loop through all days of interest
  FOR day =222, 228 DO BEGIN
     curdayFiles=selectfilesfor(day, files.data)

;; loop over three subsets
     FOR subset=1,3 DO BEGIN
        maskFileNames=maskFiles(curdayFiles, files.subsetMask[i])

;; loop over resolution (2^x) 1km -> 32km
        oldres=1 ;km
        FOR resolution=1,5 DO BEGIN
           curRes=2.^resolution
           
           plotFile=strcompress(day, /remove_all)+ "-"+$
             strcompress(subset,/remove_all)+ "-"+$
             strcompress(curRes, /remove_all)+".ps"

           resFiles=changeResolution(maskFileNames,curRes/oldres, curRes)
           plotTvX, resFiles, plotFile
           oldres=curRes
           maskFileNames=resfiles
        endFOR
     ENDFOR
  ENDFOR

END


;; read the file list in from the input file
;;
;; input file should be a text file that has a mask file on each line
;; followed by a reflectance (NDVI?) directory, and a thermal
;; directory.  
FUNCTION getFileList, inputfile
  openr, un, /get, inputfile
  line=""

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
  return, {subsetMask:files[0:nfiles-3],data:files[nfiles-2:nfiles-1]}
END


;; search through the ndvi directory for all files matching the day
;; ditto for the thermal directory
FUNCTION selectfilesfor, day, dirNames
  return, {ndvi:file_search(dirNames[0], $
                            "*_"+strcompress(day, /remove_all)+"_*"), $
           thermal:file_search(dirName[1], $
                            "*_"+strcompress(day, /remove_all)+"_*")}
END

