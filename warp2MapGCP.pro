pro warp2MapGCPs, warp_file, gcp_file, out_name

  envistart

  envi_open_file, warp_file, r_fid=fid

  if (fid eq -1 eq -1) then begin
     print, 'ERROR opening one of the input files : ', $
      warp_file
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

;
; Create the projection of the map coordinates
;
  units = envi_translate_projection_units('Meters')
  proj = envi_proj_create(/utm, zone=18, $
                          datum='WGS-84', units=units)
  pixel_size = [1.5, 1.5]
  

; register fid to bfid 
  envi_doit, 'envi_register_doit', $
    w_fid=fid, w_pos=pos, w_dims=dims, $
    out_name=out_name, pixel_size=pixel_size,$
    pts=pts, r_fid=rfid, proj=proj

  envi_file_mng, id=fid, /remove         ; close 2B warped file
  envi_file_mng, id=rfid, /remove        ; close output file

end
