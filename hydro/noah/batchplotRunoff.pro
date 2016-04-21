PRO batchplotRunoff
  rr=['i1','i5','i30']
  shps=['alpha','n','ts','ks']
  dz='5cm'

  cd, dz
  FOR i=0,n_elements(shps)-1 DO BEGIN
     FOR j=0,n_elements(rr)-1 DO BEGIN
        cd, shps[i]+'/'+rr[j], current=old
        plotRunoff, psfile=shps[i]+'_'+rr[j]+'.ps'
        cd, old
     endFOR
  ENDFOR
  cd, "../"
END

        
