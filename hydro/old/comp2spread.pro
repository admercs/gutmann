;; read in the filenames from a file named fileList
;; returns an array of file names
FUNCTION readFiles
  name=''
  list=''

  openr, un, /get, 'fileList'
  readf, un, list

  WHILE NOT eof(un) DO BEGIN
     readf, un, name
     list=[list,name]
  ENDWHILE
  close, un  & free_lun, un

  return, list
END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This is sort of the meat of the work.
;;
;; Reads in a column formated data file with columns : 
;;  RMS, max, xpos, ypos, name1, name2
;;
;; returns an array that is max(xpos) x max(ypos) x 2 in size
;;  where the 3rd dimension (2 deep) is RMS and max dT
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION readdata, datafile
  IF n_elements(datafile) EQ 0 THEN datafile='newoutput.out'
  openr, un, /get, datafile
  line=''

;; read first line
  readf, un, line
;; split it
  temp=strsplit(line, /extract)
;; convert to floats
  data=float(temp[0:3])

;; read the rest of the data and cat it on to the first line
  WHILE NOT eof(un) DO BEGIN 
     readf, un, line
     temp=strsplit(line, /extract)
     data=[[data], [float(temp[0:3])]]
  ENDWHILE

;; can't find a way to reform this data without a for loop
;; the data do not completely fill the array so reform does not work
  newDat=fltarr(max(data[2,*])+1, max(data[3,*])+1, 2)
  FOR i=0, n_elements(data[0,*])-1 DO BEGIN
     newDat[data[2,i], data[3,i], 0] = data[0,i]
     newDat[data[2,i], data[3,i], 1] = data[1,i]
  ENDFOR

  close, un  & free_lun, un
  return, newDat
END


;; write out a space delimeted spreadsheet
PRO writeSpreadSheet, names, data
  openw, oun, /get, 'output.csv'


  FOR j=0,1 DO BEGIN 
     printf, oun, names
     FOR i=0, n_elements(data[0,*,j])-1 DO BEGIN
        printf, oun, names[i], ' ', data[*,i,j]
     ENDFOR 
  ENDFOR 
  close, oun
  free_lun, oun
END



PRO comp2spread, datafile

  names=readFiles()
  data= readdata(datafile)

  writeSpreadSheet, names, data

end
