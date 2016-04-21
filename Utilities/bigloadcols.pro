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
;   28 September2000, EDG - Made it truly handle enormous files with enormous
;                           data values if you set the flag /big
;		just not yet...
function bigloadcols,name,values, big=big
;  !error = 0 & on_ioerror,trouble
  lut = bytarr(256) & lut = lut + 1
;; exceptions for floating point notation NaN, 1.0E+5...
  lut(byte('N')) = 0 & lut(byte('a')) = 0
  lut(byte(' ')) = 0 & lut(byte(',')) = 0 & lut(byte('.')) = 0
  lut(byte('e')) = 0 & lut(byte('E')) = 0
  lut(byte('+')) = 0 & lut(byte('-')) = 0
  lut(48:57) = 0 ; byte('0') - byte('9')
  nlut = bytarr(256) & nlut(48:57) = 1
  openr,unit,name,/get
  ;
  ; check for a carriage return ascii-10 in the first 2048 bytes. if there
  ; isn't one then don't consider this formatted data
  ;
  info = fstat(unit)
  if (info.size eq 0) then begin
    ;
    ; empty file
    ;
    close,unit & free_lun,unit & print, 'EMPTY FILE' & return,-1 
  endif
  stuff = bytarr(2048<info.size) & readu,unit,stuff
  ret = where(stuff eq 10,count)
  if (count eq 0) then begin
    ;
    ; no carriage return in first 2048 bytes
    ;
    close,unit & free_lun,unit & print, 'No NewLine in first 2048 bytes' &return,-1 
  endif
  point_lun,unit,0 ; reset the file pointer
  ;
  ; read past any header text and the first line of columned data to
  ; determine the number of columns.
  ;
  header = 1 & count = ulong64(0)
  while (header eq 1) do begin
    line = '' & readf,unit,line
    bline = byte(strtrim(strcompress(line),2))
    if (total(lut(bline)) eq 0 and total(nlut(bline)) gt 0) then begin
      ; only valid characters are present, this is the first
      ; line of data.
      sptr = where(bline eq 32, ncol)
      num_cols = ncol + 1
      vals = dblarr(num_cols,10000)
      bline = string(bline) & slen = strlen(bline)
      vals(0,count) = double(bline)
      for i=1,num_cols-1 do $
         vals(i,count) = double(strmid(bline,sptr(i-1)+1,slen))
      header = 0
      count = double(1)
    endif
  endwhile

  if keyword_set(big) then begin input=dblarr(num_cols) 
	endif else  input = dblarr(num_cols)

  ; read in the rest of the columned data 
  while (not eof(unit)) do begin
    readf,unit,input
    if (n_elements(vals) le count * num_cols) then $ 
	if keyword_set(big) then begin vals=[[vals], [dblarr(num_cols, 10000)]]
	endif else vals = [[vals],[dblarr(num_cols,10000)]]

    vals(*,count) = input
    count = count + double(1)
  endwhile
  if (count eq 0) then begin
    ;  
    ; no valid data was read
    ;
    close,unit & free_lun,unit & print, 'Count = 0' & return,-1
  endif
  values = vals(*,0:count-1)
  ;
  ; if an io error occured, clean up and return -1
  ;
  trouble: if (!error ne 0) then num_cols = -1 & print, 'ioerror', count
  if (n_elements(unit) ne 0) then free_lun,unit 
  return,num_cols
end
