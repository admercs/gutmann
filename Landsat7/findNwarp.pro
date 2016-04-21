pro findNwarp

  ENVI, /restore_base_save_files
  ENVI_BATCH_INIT

  filelist=findfile('*')
  nfiles=n_elements(filelist)
  for i=0,nfiles-1 do begin
     if file_test(strmid(filelist[i],0,strlen(filelist[i])-1), /directory) then $
       filelist[i]=strmid(filelist[i],0,strlen(filelist[i])-1)
     if file_test(filelist[i], /directory) then begin
        cd, filelist[i], current=olddir
        
        if file_test('SCENE01', /directory) then begin
           cd, 'SCENE01'
           file=file_search('*.pts')
           if (file[0] ne -1) then begin
              infile=strmid(file[0], 0, strlen(file[0])-11)
              print, 'warping : ', infile, ' to combined1 with ', file[0]
              warpWithGCPs, 'combined1', infile, file[0], 'warped'+infile

           endif
        endif
        cd, olddir
     endif
  endfor
end

