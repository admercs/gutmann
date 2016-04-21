
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

  readf, un, line
  landCover=line
  readf, un, line
  landCoverIndex=line

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

  return, {landCover:landCover, landCoverIndex:landCoverIndex, $
           mountainMask:mountainMask, $
           nmasks:n, subsetMask:files[0:n-1], $
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


PRO makeAltTvX, inputfile, fast=fast, plotNcovers=plotNcovers

  files=getFileList(inputfile)
  IF NOT keyword_set(plotNcovers) THEN plotNcovers=8
  
;;  loop through all days of interest
  FOR day =222, 228 DO BEGIN
     curdayFiles=selectfilesfor(day, files.data)
     print, curdayFiles
     curdayFiles=maskFiles(curdayFiles, files.mountainMask, /FullSize)


;; loop over three subsets
     FOR subset=0,files.nmasks DO BEGIN
        LandCover=files.landCover
        LandCoverIndex=files.landCoverIndex
        subsetName="Full Area"
        IF subset eq 0 then maskFileNames=curdayFiles else begin
           maskFileNames=maskFiles(curdayFiles, files.subsetMask[subset-1])
           LandCover=maskFiles({ndvi:LandCover, thermal:LandCover}, $
                               files.subsetMask[subset-1])
           subsetName=(strsplit(files.subsetMask[subset-1],'.',/extract))[0]
           LandCover=LandCover.ndvi
        ENDELSE

;; loop over resolution (2^x) 1km -> 32km
        oldres=1 ;km
        plotFile='2001_'+strcompress(day, /remove_all)+ '_'+$
          strcompress(subset,/remove_all)+ '_'+$
          strcompress(oldRes, /remove_all)+'km.ps'
        print, "plotting : ", plotFile

        plotTvXAlt, maskFileNames, plotFile, LandCover, $
          day, oldRes, subsetName,LandCoverIndex, $
          ct=12, ncover=plotNcovers

;        densplot, maskFileNames.ndvi, maskFileNames.thermal, $
;          plotFile+'_dense.tif', $
;          lowx=10000, hix=20000, lowy=14500, hiy=17000
        FOR resolution=1,5 DO BEGIN
           curRes=fix(2.^resolution)
           print, ""
           print, "-----------------------------------"
           print, "    ", strcompress(fix(curRes)), " km"
           
           plotFile='2001_'+strcompress(day, /remove_all)+'_'+ $
                    strcompress(subset,/remove_all)+'_'+$
                    strcompress(curRes, /remove_all)+'km'

           print, "Resizeing Altitude Data"
           LandCover=resizeAlt(LandCover, curRes/oldres, curRes)
           print, "Resizeing Data Files"
           resFiles=changeResolution(maskFileNames,curRes/oldres, curRes)
           print, "plotting : ", plotFile
           plotTvXAlt, resFiles, plotFile+'.ps', LandCover, $
             day, curRes, subsetName, landCoverIndex, $
             ct=12, ncover=plotNcovers
;           densplot, resFiles.ndvi, resFiles.thermal, plotFile+'_dense.tif', $
;                     lowx=8000, hix=20000, lowy=13500, hiy=17000
           oldres=curRes
           maskFileNames=resfiles
        endFOR
     ENDFOR
  ENDFOR

END

