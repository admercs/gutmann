FUNCTION readvals, files, day, varcol=varcol
  IF NOT keyword_set(varcol) THEN varcol=7
  morning=24
  afternoon=33
  vals=fltarr(2,n_elements(files))

  FOR i=0, n_elements(files)-1 DO BEGIN 
     junk=load_cols(files[i], data)
     vals[*,i]=[i,mean(data[varcol, (day*48l+morning):(day*48l+afternoon)])]
  endFOR
  return, vals
END



PRO histoplots_fig3, basedir=basedir
  old=setupplot(filename='histoplots_fig3.ps')
  !p.multi=[0,2,6]
  !y.minor=1
  IF keyword_set(basedir) THEN cd, basedir, current=originaldir

  files=file_search('ihop?')
  varcol=12

  bestSOIL=strarr(11)
  
;; no corrections were applied to the sev sites, so original "best" soils are still used
   bestSOIL[9] = 'out_loam_1691'
   bestSOIL[10] = 'out_clayloam_1474'


;; after updating albedos  
  bestSOIL[0] = 'out_siltloam_1846'
  bestSOIL[1] = 'out_loam_1840'
  bestSOIL[2] = 'out_sandyloam_1392'
  bestSOIL[3] = 'out_siltyclayloam_1444'
  bestSOIL[4] = 'out_loamysand_2025'
;  bestSOIL[5] = 'out_clay_1869' ; using old dates
  bestSOIL[5] = 'out_siltyclayloam_1447'
  bestSOIL[6] = 'out_siltloam_1187'
  bestSOIL[7] = 'out_clayloam_1305'
  bestSOIL[8] = 'out_sandyloam_1214'
;; after updating storm for BSG
  bestSOIL[10]='out_sandyloam_1721'
  
  ;; not sure why there is a one day offset for ihop sites but not for sev sites
  ;; (sev sites are actually 261 and 192), I think because I originally pasted an sdays array and added 1. 
  days=[29, 29, 36, 37, 37, 29, 13, 45, 45, 260, 191]+4
  realSTC=[5,5,2,4,4,7,6,6,6,2,1] ; anything higher than silt had one subtracted from it
                                ;  because silt doesn't actually exist (essentially)



  files=['ihop1', 'ihop2', 'ihop3', 'ihop4', 'ihop5', $
         'ihop6', 'ihop7', 'ihop8', 'ihop9', 'bss', 'bsg']
  fileindex=[9,10,0,1,2,3,4,5,6,7,8]
  FOR counter=2,10 DO BEGIN
     i=fileindex[counter]
     cd, files[i], current=olddir
     junk=load_cols('convoutslate', data)

     classAve=readvals(['SAND', 'LOAMYSAND', 'SANDYLOAM', $
                        'SILTLOAM', 'LOAM', $;'SILT', 'LOAM', $
                        'SANDYCLAYLOAM', 'SILTYCLAYLOAM', $
                        'CLAYLOAM', 'SANDYCLAY', 'SILTYCLAY', 'CLAY'], $
                       days[i])
     best=readvals(bestSOIL[i], days[i])
;     stop
     IF i GE 9 THEN offset=0 ELSE offset=11
     IF i GE 9 THEN measurevarcol=1 ELSE measurevarcol=23

     measured=readvals((file_search('IHOPUDS*.txt'))[0], days[i]-offset, varcol=measurevarcol)
     print, best[1], measured[1], classAve[1,realSTC[i]+1]
     measured=[[measured],[measured]]
     best=[[best],[best]]
     best[0,1]=15
     measured[0,1]=15
     best[0,0]=-5
     measured[0,0]=-5
     title=strupcase(files[i])
     IF i EQ 5 OR i EQ 6 THEN classave[1,n_elements(classave[1,*])-2]=800
     histo_flux_plot, data[varcol,*], data[1,*], othercharsize=0.5, $
                      title=title, yr=[0,700], $
                      ytitle='LH (W/m!U2!N)', $
                      true=measured, classAve=classave, best=best, $
                      highlightCol=realSTC[i], ytickinterval=200, yminor=2
     cd, olddir
  ENDFOR

  resetplot, old

  IF keyword_set(basedir) THEN cd, originaldir
end
;
; old best soils
;
;   bestSOIL[0] = 'out_sandyclayloam_835'
;   bestSOIL[1] = 'out_clay_1713'
;   bestSOIL[2] = 'out_sandyloam_1093'
;   bestSOIL[3] = 'out_sandyloam_1018'
;   bestSOIL[4] = 'out_loamysand_1720'
;   bestSOIL[5] = 'out_clay_736'
;   bestSOIL[6] = 'out_loam_2126'
;   bestSOIL[7] = 'out_sandyloam_1278'
;   bestSOIL[8] = 'out_sandyloam_1214'
;   bestSOIL[9] = 'out_loam_1691'
;   bestSOIL[10] = 'out_clayloam_1474'

; ;; after updating LH for closure...
;   bestSOIL[0] = 'out_siltloam_1677'
;   bestSOIL[1] = 'out_sandyclayloam_882'
;   bestSOIL[2] = 'out_clay_1508'
;   bestSOIL[3] = 'out_loam_1866'
;   bestSOIL[4] = 'out_loamysand_1586'
;   bestSOIL[5] = 'out_clay_1869'
;   bestSOIL[6] = 'out_siltloam_1187'
;   bestSOIL[7] = 'out_clayloam_279'
;   bestSOIL[8] = 'out_sandyloam_1214'
