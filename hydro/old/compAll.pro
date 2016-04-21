;; Loads the data from two noah runs (out put files specified by file1
;; and file2.)
;;
;; Returns the mean and max difference in Soil Skin Temperature
;; between the two runs at 11AM, noon, 1PM, and 2PM, over 5 days.  
;;
;; Specifically written to look at the delta T between a sandy soil
;; run and a clay soil run
;;
;; 10/17/2003
function computeDiff, file1, file2
;; read in the data files
  !error=0
  j=load_cols(file1, dat1)
  j=load_cols(file2, dat2)

  dayGain=48    ;; 48 timesteps/day
  hourOffset=22 ;; 11AM
  days=indgen(4)+3;+224 ;20 ;; the days we want to look at 224, 225, 226, 227
  index=days*daygain+houroffset ;; compute the index into the full array
  index=[index, index+2, index+4, index+6] ;; add 12noon 1PM, and 2PM
  index=[index, index+1]  ;; add the half hours too

;; 2 = skin temperature
  ave=sqrt(mean((dat1[2,index]-dat2[2,index])^2))
  mx=max(abs(dat1[2,index]-dat2[2,index]))
;; 8 = top layer temperature
  ave2=sqrt(mean((dat1[8,index]-dat2[8,index])^2))
  mx2=max(abs(dat1[8,index]-dat2[8,index]))
  return, [ave, mx, ave2, mx2]
end


;; read in the filenames from a file named fileList
;; returns an array of file names
FUNCTION readFiles, fname
  name=''
  list=''

  openr, un, /get, fname
  readf, un, list

  WHILE NOT eof(un) DO BEGIN
     readf, un, name
     list=[list,name]
  ENDWHILE
  close, un  & free_lun, un

  return, list
END

PRO compAll, outputfile
  openw, oun, /get, outputfile

  files=readFiles("fileList")
  files2=readFiles("fileList2")
  nfiles=n_elements(files)
  FOR i=0, nfiles-1 DO BEGIN
     dat=computeDiff(files[i], files2[i])
     printf, oun, dat[0], dat[1], dat[2], dat[3]
;, i, j, ' ',files[i], ' ', files2[i]
     print, dat[0], dat[1], dat[2], dat[3], i, ' ', files[i], ' ', files2[i]
  ENDFOR
  
  close, oun  & free_lun, oun

END


