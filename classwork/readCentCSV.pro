;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Read Century v.5 csv output files
;;
;; return a structure with {header, data}
;;
;; Reads a very strict file structure, and does not check for errors
;;   12 header lines (ignored)
;;   one line with column names, each of which must be in quotes
;;   n lines that must have exactly the same number of columns as the header
;;     and must be separated by commas.  
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION readCentCSV, filename

;; the number of header lines
  header=12

;; guess the number of data lines
  datalines=(2002-1990)*12+1

  openr, un, /get, filename  
  line=''

  ;; skip over the header
  FOR i=0, header DO readf, un, line
  
;; read the column headings from the last line we read in
  header=strsplit(line, '"', /extract)
  header=header[indgen((n_elements(header)+1)/2)*2]
  
;; assume the same number of columns for the data
  data=fltarr(n_elements(header), datalines)

  i=0
;; read in data until we reach the end of the file
  WHILE NOT eof(un) DO BEGIN
     
;; check that we haven't run past the end of the data array,
;;   and make it larger if we did
     IF i GT n_elements(data[0,*])-1 THEN $
       data=[[data],[fltarr(n_elements(header), datalines)]]
     
     readf, un, line
     data[*,i]=float(strsplit(line, ',', /extract))
     i++
  endWHILE
  
;; if we didn't guess the right number of lines, then truncate that dataset
;;   to match what we actually read
  IF --i LT (n_elements(data[0,*])) THEN $
    data=data[*,0:i]

;; file clean up
  close, un
  free_lun, un

;; return output values in a convenient structure
  return, {header:header, data:data}
END

