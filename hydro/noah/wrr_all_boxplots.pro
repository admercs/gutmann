PRO wrr_all_boxplots
  
  dirs=file_search("ihop[1-9]", /test_directory, count=ndirs)
  FOR curdir=0,ndirs-1 DO begin
     cd, dirs[curdir], current=olddir

     files=file_search("comb*[1-9]", count=nfiles)
     FOR curfile=0,nfiles-1 DO BEGIN
        old=setupplot(filename=files[curfile]+".ps")
        !p.multi=[0,1,2]
        BoxFlux, files[curfile], /hist
        resetplot, old
     endFOR

     cd, olddir
  ENDFOR

END

     
