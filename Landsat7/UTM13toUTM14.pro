pro warptoUTM14, infile, outfile
  FORWARD_FUNCTION  envi_proj_create, envi_get_map_info
  
; First restore all the base save files.
;
;  envi, /restore_base_save_files
;
; Initialize ENVI and send all errors
; and warnings to the file
; batch.txt
;
;  envi_batch_init, log_file='batch.txt'
;
; Open the input file
;
; Open the input file
  print, "Converting File...", infile
  envi_open_file, infile, r_fid=fid
  if (fid eq -1) then begin
     print, "ERROR"
;     envi_batch_exit
     return
  endif
;
; Setup the values for the keywords
;
  print, "Converting File..."
  envi_file_query, fid, ns=ns, nl=nl, nb=nb
  mapinfo = envi_get_map_info(fid=fid)
  
  pos = lindgen(nb)
  dims = [-1l, 0, ns-1, 0, nl-1]
  
  print, "Converting File..."
  o_proj = envi_proj_create(/utm, zone=14)
  o_pixel_size = mapinfo.ps
;
; Call the doit
;
  print, "Converting File..."
  envi_convert_file_map_projection, fid=fid, $
    pos=pos, dims=dims, o_proj=o_proj, $
    o_pixel_size=o_pixel_size, out_name=outfile, $
    grid=[50,50]
;   , warp_method=0, $
;    resampling=1, background=0

;
; close file in ENVI
;
  envi_file_mng, id=fid, /remove

;
; Exit ENVI
;
;  envi_batch_exit
end


pro UTM13toUTM14, pattern=pattern, out=out

;  envistart

  if not keyword_set(pattern) then pattern='*.bsq'
  if not keyword_set(out) then out='warped'

  files=findfile(pattern)
  for i=0, n_elements(files)-1 do begin
     print, files[i]
     warpToUTM14, files[i], out+files[i]
  endfor

;  envi_batch_exit
end
