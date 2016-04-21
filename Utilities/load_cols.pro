; $Id: load_cols.pro,v 1.1 94/01/05 15:36:01 shapiro Exp $
;+
; NAME:
;   load_cols
;
; PURPOSE:
;   function for reading in ascii data formatted into columns
;
; CALLING SEQUENCE:
;   num_cols = load_cols(name,values)
;
; PARAMETERS:
;   name:    name of file to read from.
;   values:  fltarr(num_cols,num_lines) containing the data on exit
;
; KEYWORDS:
;   none
;
; RETURN VALUE:
;   load_cols returns the number of columns the data contains or,
;     -1 for an invalid file.
;
; COMMON BLOCKS:
;   none
;
; PROCEDURE:
;   read the file in one line at a time and only allow valid
;   bytes ('0'-'9','+','-','e','E','.') in the column data.  allows
;   for some 'invalid' text before the data starts, however nothing
;   invalid after the data starts is allowed. 
;
; SIDE EFFECTS:
;   none
;
; RESTRICTIONS:
;   none
;
; COMMENTS:
;
; MODIFICATION HISTORY:
;   23 November 1991, ABL - Initial revision.
;    5 December 1991, ATS - Routine now returns instead of crashing when
;                             called with an invalid file name.
;    2 January  1992, PJB - Standardized comment header.
;   28 May      1992, ABL - Rewrote logic to handle any size file, run
;                           considerably faster and a great deal more
;                           tolerant of ill-formed data.
;   18 February 2001, EDG - Added a check for newlines in addition to the 
;                           check for carriage returns. Also added "better"
;                           error reporting
;   2001              EDG - Lumped addition of new elements into groups of 10000
;                           to speed up processing of HUGE arrays
;   2003              EDG - added characters N, a, A, n to the list of non-header
;                           characters
;   20 February 2006  EDG - added compress keyword to load data from a
;                           gzipped file
;
;-
function load_cols,name,values, double=double, compress=compress
;  !error = 0 & on_ioerror,trouble
  lut = bytarr(256) & lut = lut + 1
;; exceptions for floating point notation N[A,a]N, 1.0E+5...
  lut(byte('N')) = 0 & lut(byte('a')) = 0 & lut(byte('A')) = 0
  lut(byte(' ')) = 0 & lut(byte(',')) = 0 & lut(byte('.')) = 0
  lut(byte('e')) = 0 & lut(byte('E')) = 0
  lut(byte('+')) = 0 & lut(byte('-')) = 0
  lut(48:57) = 0 ; byte('0') - byte('9')
  nlut = bytarr(256) & nlut(48:57) = 1
  openr,unit,name,/get, compress=compress
  ;
  ; check for a carriage return ascii-10 in the first 2048 bytes. if there
  ; isn't one then don't consider this formatted data
  ;
  info = fstat(unit)
  if (info.size eq 0) then begin
    ;
    ; empty file
    ;
    close,unit & free_lun,unit & print, 1 & return,-1 
  endif
  stuff = bytarr(2048<info.size) & readu,unit,stuff
  ret = where(stuff eq 10,count)
  if (count eq 0) then begin
    ;
    ; no carriage return in first 2048 bytes
    ; check for newline 
    ;
    ret = where(stuff eq 13, count)
    if (count eq 0) then begin
        close,unit & free_lun,unit & print, 2 & return,-1 
    endif
endif
  point_lun,unit,0 ; reset the file pointer
  ;
  ; read past any header text and the first line of columned data to
  ; determine the number of columns.
  ;
  header = 1 & count = 0l
  while (header eq 1) do begin
    line = '' & readf,unit,line
    bline = byte(strtrim(strcompress(line),2))
    if (total(lut(bline)) eq 0 and total(nlut(bline)) gt 0) then begin
      ; only valid characters are present, this is the first
      ; line of data.
       tmp=strsplit(line, ',', /extract)
       IF n_elements(tmp) EQ 1 THEN tmp=strsplit(line, /extract)

       num_cols=n_elements(tmp)
       IF keyword_set(double) THEN BEGIN
          vals=dblarr(num_cols,10000)
          vals[*,0]=double(tmp)
       ENDIF ELSE BEGIN 
          vals=fltarr(num_cols,10000)
          vals[*,0]=float(tmp)
       ENDELSE

;      sptr = where(bline eq 32, ncol)
;      num_cols = ncol + 1
;      IF keyword_set(double) THEN BEGIN
;         vals = dblarr(num_cols,10000)
;      ENDIF ELSE $
;        vals = fltarr(num_cols,10000)
;      bline = string(bline) & slen = strlen(bline)
;      vals(0,count) = float(bline)
;      for i=1,num_cols-1 do BEGIN
;         IF keyword_set(double) THEN BEGIN
;            vals(i,count) = double(strmid(bline,sptr(i-1)+1,slen))
;         ENDIF ELSE $
;           vals(i,count) = float(strmid(bline,sptr(i-1)+1,slen))
;      endFOR
      
      header = 0
      count = 1l
    endif
  endwhile
  IF keyword_set(double) THEN BEGIN
     input = dblarr(num_cols)
  ENDIF ELSE $
    input = fltarr(num_cols)
  ; read in the rest of the columned data 
  while (not eof(unit)) do begin
    readf,unit,input
    if (n_elements(vals) le count * num_cols) then BEGIN
       IF keyword_set(double) THEN BEGIN
          vals = [[vals],[dblarr(num_cols,10000)]]
       ENDIF ELSE $
         vals = [[vals],[fltarr(num_cols,10000)]]
     endIF

    vals(*,count) = input
    count = count + 1l
  endwhile
  if (count eq 0) then begin
    ;  
    ; no valid data was read
    ;
    close,unit & free_lun,unit & print, 3 & return,-1
  endif
  values = vals(*,0:count-1)

  if (n_elements(unit) ne 0) then free_lun,unit 
  return,num_cols

  ;
  ; if an io error occured, clean up and return -1
                                ;
trouble: if (!error ne 0) then begin print, !error_state & num_cols = -1 & endif
   data=intarr(1) ; clear up memory?
  if (n_elements(unit) ne 0) then free_lun,unit 
  return,-1
end
