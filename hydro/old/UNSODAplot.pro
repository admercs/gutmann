;; Reads a text file with colmns separated by ';'s and
;;   text fields are surrounded by '"'s
;;
;; Takes a filename and string as input
;; checks to see if the third column in the filename matches the input string
;; if it does then the number from the first column is added to a list
;; This list is the final output
FUNCTION getCodes, fname, type

;; open the general.csv input file
  openr, un, fname, /get
  line="" ; define list so that readf knows what to read
  list=0  ; initial value so we can concatenate to something

;; search through the entire file
  WHILE NOT eof(un) DO BEGIN
     ;;read a line
     readf, un, line
     ;; split the line in to an array using ";" as delimiters
     data=strsplit(line, ";", /extract)
     ;; get the soil type string from the third column
     curtype=data[3]
     ;; if the current soil type matches the input soil type then add
     ;;  the code from the first column to the list
     IF strmatch(curtype, '"'+type+'"') THEN list=[list,fix(data[0])]
  ENDWHILE 

;; close the file and free the unit number
  close, un  &  free_lun, un
;; remove the first dummy elements from the list and
;; return the codes found in the file that matched the input type
  return, list[1:n_elements(list)-1]
END 



;; general driver routine to plot SHPs from UNSODA database
PRO UNSODAplot, general, hk,hsmc, type1=type1, type2=type2


  IF n_elements(general) EQ 0 THEN general="general.csv"
  IF NOT keyword_set(type1) THEN type1="sand"
  IF NOT keyword_set(type2) THEN type2="loam"

;; read Conductivity - suction Head data
  junk=load_cols(hk, hkdata)
;; read Soil Moisture Content - suction Head data
  junk=load_cols(hsmc, hsmcdata)

;; find all of the codes that match soil type 1
  dex1=getCodes(type1)
;; find all of the codes that match soil type 1
  dex2=getCodes(type2)

;; print out the number of each that were found.  
  print, n_elements(dex1), type1
  print, n_elements(dex2), type2
  
;;
;; Stopped development here because Marcel Schaap sent me a MUCH
;; easier to read data base.
;; See ROSETTA-UNSODAdb.txt or newRosetta.txt
;; 
;  curves1=getCurves(dex1, hkdata)
;  curves2=getCurves(dex2, hkdata)
;
;  window, 0, xs=1000, ys=1000
;  plotData, curves1
;  window, 1, xs=1000, ys=1000
;  plotData, curves2

end

