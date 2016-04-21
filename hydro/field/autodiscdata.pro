;+
; NAME: autodiscdata
;
; PURPOSE: Should be run by an applescript invoked by a mail.app rule.  Processes email
;          attachments of info files for the DISC program
;
; CATEGORY: autofile
;
; CALLING SEQUENCE: autodiscdata
;
; INPUTS: two files in an attachments directory named *.info and *.data
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS: DISC input data file
;
; OPTIONAL OUTPUTS:
;
; COMMON BLOCKS:
;
; SIDE EFFECTS: 
;
; RESTRICTIONS:
;
; PROCEDURE: find files created in the last minute in attachments folder
;            make a list of all such files in a structure with .info, .data, and .output files
;            make_disc_data with these filenames
;            move results into a web directory (DiscData)
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;            original - summer 2005 - edg - incomplete
;-
pro addtoFileList, file, list
  IF n_elements(list) EQ 0 THEN BEGIN
     list={filelist, info:file, data:file, output:file}
     return
  ENDIF
  IF strmatch(file, '*info*') THEN BEGIN
     IF (list[n_elements(list)-1].info $
         NE list[n_elements(list)-1].data) THEN BEGIN
        


end

PRO autodiscdata
  files=file_search('~gutmann/Documents/Attachements/', /fully_qualify_path)
  for i=0,n_elements(files)-1 do begin
     result=file_info(files[i])
     if (systime(/seconds)-result.ctime) lt 600 then begin
        addtoFileList, files[i], filelist
     endif
  endfor
  
  for i=0,n_elements(filelist)-1 do begin
     make_disc_data, filelist[i].info, filelist[i].data, filelist[i].output
     file_move, filelist[i].output, '~gutmann/Sites/DiscData/' 
  ENDFOR
END
