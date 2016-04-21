PRO plotall, fname
  
  IF n_elements(fname) EQ 0 THEN fname="plotall.ps"

  dirs=file_search("ihop*")
  bestSOIL=strarr(9)

;; selected from LE
  bestSOIL[0] = 'out_sandyclayloam_842'
  bestSOIL[1] = 'out_sandyclayloam_883'
  bestSOIL[2] = 'out_sandyloam_1633'
  bestSOIL[3] = 'out_loam_1840'
  bestSOIL[4] = 'out_loam_1271'
  bestSOIL[5] = 'out_clayloam_1240'
  bestSOIL[6] = 'out_siltyclayloam_1421'
  bestSOIL[7] = 'out_siltyclayloam_1421'
  bestSOIL[8] = 'out_siltyclayloam_1970'

;; selected from Ts Correlation
  bestSOIL[0] = 'out_sandyclayloam_842'
  bestSOIL[1] = 'out_sandyclayloam_956'
  bestSOIL[2] = 'out_sandyloam_839'
  bestSOIL[3] = 'out_loam_1853'
  bestSOIL[4] = 'out_loam_725'
  bestSOIL[5] = 'out_clayloam_1884'
  bestSOIL[6] = 'out_siltyclayloam_328'
  bestSOIL[7] = 'out_siltyclayloam_328'
  bestSOIL[8] = 'out_siltyclayloam_297'

;; selected from Ts normalized
  bestSOIL[0] = 'out_sandyclayloam_842'
  bestSOIL[1] = 'out_sandyclayloam_971'
  bestSOIL[2] = 'out_sandyloam_802'
  bestSOIL[3] = 'out_loam_1885'
  bestSOIL[4] = 'out_loam_1471'
  bestSOIL[5] = 'out_clayloam_1424'
  bestSOIL[6] = 'out_siltyclayloam_1910'
  bestSOIL[7] = 'out_siltyclayloam_1905'
  bestSOIL[8] = 'out_siltyclayloam_1412'

;; LE new
  sday=30
  eday=36
  bestSOIL[0] = 'out_sandyclayloam_860'
  bestSOIL[1] = 'out_sandyclayloam_759'
  bestSOIL[2] = 'out_sandyloam_1214'
  bestSOIL[3] = 'out_loam_1445'
  bestSOIL[4] = 'out_loam_1832'
  bestSOIL[5] = 'out_clayloam_1473'
  bestSOIL[6] = 'out_siltyclayloam_328'
  bestSOIL[7] = 'out_siltyclayloam_2122'
  bestSOIL[8] = 'out_siltyclayloam_1421'

;; ts corr 
  sday=30
  eday=36
  bestSOIL[0] = 'out_sandyclayloam_929'
  bestSOIL[1] = 'out_sandyclayloam_841'
  bestSOIL[2] = 'out_sandyloam_1278'
  bestSOIL[3] = 'out_loam_1296'
  bestSOIL[4] = 'out_loam_1755'
  bestSOIL[5] = 'out_clayloam_1650'
  bestSOIL[6] = 'out_siltyclayloam_1688'
  bestSOIL[7] = 'out_siltyclayloam_295'
  bestSOIL[8] = 'out_siltyclayloam_328'

  class=strarr(9)
  measured=strarr(9)
  texture=strarr(9)

  oldp=setupplot(filename=fname)
  !p.multi=[0,1,2]
  !p.charsize=1

  FOR i=0,n_elements(dirs)-1 DO BEGIN
     cd, current=olddir, dirs[i]
     texture[i]=(strsplit(bestSOIL[i], '_',/extract))[1]
     class[i]=file_search(texture[i], /fold_case)
     measured[i]="IHOPUDS"+strcompress(i+1,/remove_all)+".txt"

     IF i EQ 0 THEN dayoffset=1 ELSE dayoffset=0

     noah_plot_flux_texture, texture[i], /nops, var=[7,2], /skipn, keyday=47, $
       classmeans=class[i], measuredLE=measured[i], bestSHP=bestSOIL[i], /legend, $
       title=dirs[i]+'  '+texture[i], startday=sday+dayoffset, endday=eday+dayoffset, $
       /remove_diurnal_ts, /nosetup
     cd, olddir
  ENDFOR
  resetplot, oldp

END
