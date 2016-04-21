pro warpWithGCPs, ref_file, warp_file, gcp_file, out_name

  envistart

  envi_open_file, warp_file, r_fid=fid
  envi_open_file, ref_file, r_fid=bfid

  if (fid eq -1 or bfid eq -1) then begin
     print, 'ERROR opening one of the input files : ', $
       ref_file, ' or ', warp_file
;     envi_batch_exit
     return
  endif

; read in gcp points
  cols=load_cols(gcp_file, pts)
  if cols ne 4 then begin
     print, 'ERROR with GCP file : ', gcp_file
     return
  endif
  pts=double(pts)

; setup appropriate values for dims and pos
  envi_file_query, fid, ns=ns, nl=nl, nb=nb
  dims = [-1, 0, ns-1, 0, nl-1]
  pos = lindgen(nb)
  
; register fid to bfid 
  envi_doit, 'envi_register_doit', $
    w_fid=fid, w_pos=pos, w_dims=dims, $
    b_fid=bfid, out_name=out_name, $
    pts=pts, r_fid=rfid

  envi_file_mng, id=fid, /remove         ; close 2B warped file
  envi_file_mng, id=bfid, /remove        ; close base file
  envi_file_mng, id=rfid, /remove        ; close output file

end
