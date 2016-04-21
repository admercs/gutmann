pro closeall
	fid=envi_get_file_ids()
	if fid(0) ne -1 then begin
		for i=0, n_elements(fid)-1 do begin
			envi_file_mng, id=fid(i), /remove
		endfor
	endif
end

