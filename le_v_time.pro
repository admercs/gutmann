;; loops over all ihop directories and plots model fluxes for all (50 random) soils
;; from a soil texture class, in addition to the class average SHP, best fit SHP,
;; and measured LH.  
;;
;; ndirs      = the number of directories to process,
;; legend     = tells it to plot a legend,
;; outputfile = the output postscript file (in current directory by default)
;; basedir    = the directory containing all of the sub ihop* directories to process
;;
;; This was mostly written for the WRR papaer gutman and small (2006) thus it has a
;;   few hard coded options
;;
PRO le_v_time, outputfile, basedir=basedir, ndirs=ndirs,legend=legend,initdir=initdir
  IF NOT keyword_set(ndirs) THEN ndirs=11
  IF NOT keyword_set(basedir) THEN basedir='./'
  IF n_elements(outputfile) EQ 0 THEN outputfile="le_v_time_fig3.ps"

;; setup the post script file
  old=setupplot(filename=outputfile)
;; hard coded texture classes for each ihop directory
  textures=['sandy clay loam', 'sandy clay loam', 'sandy loam', $
            'loam', 'loam', 'clay loam', 'silty clay loam', $
            'silty clay loam', 'silty clay loam', $
            'sandy loam', 'loamy sand'] ; sevilleta textures

;; hard coded start days specifying which days to plot fluxes for
;  keydays=[30, 30, 37, 38, 38, 14, 14, 46, 46]
;  sdays=[28, 28, 36, 36, 36, 13, 13, 44, 44, 260, 260]
  keydays=[30, 30, 37, 38, 38, 30, 14, 46, 46,261,192]+0.1
  sdays=[28, 28, 36, 37, 37, 29, 13, 45, 45, 260, 191]
  edays=sdays+5

;; hard coded "best fit" soils
  bestSOIL=strarr(11)
  bestSOIL[0] = 'out_sandyclayloam_835'
  bestSOIL[1] = 'out_clay_1713'
  bestSOIL[2] = 'out_sandyloam_1093'
  bestSOIL[3] = 'out_sandyloam_1018'
  bestSOIL[4] = 'out_loamysand_1720'
  bestSOIL[5] = 'out_clay_736'
  bestSOIL[6] = 'out_loam_2126'
  bestSOIL[7] = 'out_sandyloam_1278'
  bestSOIL[8] = 'out_sandyloam_1214'
  bestSOIL[9] = 'out_loam_1691'
  bestSOIL[10] = 'out_clayloam_1474'

;; after updating albedos (and closure??)  
  bestSOIL[0] = 'out_siltloam_1846'
  bestSOIL[1] = 'out_loam_1840'
  bestSOIL[2] = 'out_sandyloam_1392'
  bestSOIL[3] = 'out_siltyclayloam_1444'
  bestSOIL[4] = 'out_loamysand_2025'
  bestSOIL[5] = 'out_clay_1869'
  bestSOIL[6] = 'out_siltloam_1187'
  bestSOIL[7] = 'out_clayloam_1305'
  bestSOIL[8] = 'out_sandyloam_1214'

;; minor update
  bestSOIL[5]='out_siltyclayloam_1447'
;; after updating storm for BSG
  bestSOIL[10]='out_sandyloam_1721'

  sevtitles=['BSS', 'BSG']

;; set the number of plots to fit on a page
IF ndirs GT 5 THEN !p.multi=[0,2,ceil((ndirs+0.1)/2.0)] ELSE !p.multi=[0,1,ndirs+1]
  
  cd, current=initialdir, basedir
  IF NOT keyword_set(initdir) THEN initdir=0
;; loop through all directories and run noah_plot_flux texture
;  FOR i=initdir,ndirs DO BEGIN
  fileindex=[9,10,0,1,2,3,4,5,6,7,8] ; re-arrange order so that sev sites come first
  FOR counter=initdir,initdir+ndirs-1 DO BEGIN
     i=fileindex[counter]+1
     cd, current=startdir, 'ihop'+strcompress(i,/remove_all)

;; find the measured data file for the current directory
     measured=file_search('IHOPUDS*.txt')
;; specify the title for the current output plot, (Sitename-sitetexture)
     title='IHOP'+strcompress(i)+' - '+textures[i-1]

;; special handling for the sevilleta sites
     IF i GT 9 THEN title=sevtitles[i-10]+' - '+textures[i-1]
     sev=(i GT 9)
     IF sev THEN keyoffset=0 ELSE keyoffset=119

;; this does all of the hard work see noah_plot_flux_texture.pro for details
     noah_plot_flux_texture, /nosetup, textures[i-1], /skipn, $
       startday=sdays[i-1], endday=edays[i-1], var=[7], $
       classmeans=strupcase(strcompress(textures[i-1], /remove_all)), $
       measuredLE=measured, $ ;'IHOPUDS'+strcompress(i,/remove_all)+'.txt', $
       title=title, bestSHP=bestSOIL[i-1], sev=sev, keyday=keydays[i-1]+keyoffset;, rainday=sdays[i-1]
     
     cd, startdir
  ENDFOR
  cd, initialdir

;; plot a simple legend
  IF keyword_set(legend) THEN BEGIN 
     plot, xs=5, ys=5, xr=[0,1], yr=[0,1], $
           [0,0.2],[.1,.1], l=2
     oplot, [0,0.2],[.35,.35], color=1, thick=3
     oplot, [0,0.2],[.6,.6], color=201, thick=3
     oplot, [0,0.2],[0.85,0.85], color=2, thick=3

     cs=0.5
     xyouts, 0.25,.05, 'Modeled (50 SHPs from texture class)', charsize=cs
     xyouts, 0.25,.3, 'Modeled (class average SHP)', charsize=cs
     xyouts, 0.25,.55, 'Modeled (Best Fit SHP)', charsize=cs
     xyouts, 0.25,.8, 'Observed', charsize=cs
  ENDIF

;; close the post script plot
  resetplot, old
END

