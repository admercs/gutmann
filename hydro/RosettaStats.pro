PRO RosettaStats, infile, outfile
  print, load_cols(infile, data)
  s=data[3,*]
  si=data[4,*]
  c=data[5,*]
  n=data[11,*]

  Sand=where(s-c/5.0 GT 88)
  LoamySand=where(s LT 90 AND s-c GT 70)
  SandyLoam=where(s-c LT 70 AND c lt 20 AND (s GT 52 OR (c LT 7 AND si LT 50)))
  SiltLoam=where(c LT 28 AND si GT 50 AND (si LT 20 OR c GT 12))
  Loam=where(s LT 52 AND si LT 50 AND si GT 28 AND c GT 7 AND c LT 28)
  SandyClayLoam=where(s GT 45 AND c GT 20 AND c LT 35 AND si LT 18)
  SiltyClayLoam=where(s LT 20 AND c GT 28 AND c LT 40)
  ClayLoam=where(s LT 46 AND s GT 20 AND c LT 40 AND c GT 28)
  SandyClay=where(s GT 45 AND c GT 35)
  SiltyClay=where(c GT 40 AND si GT 40)
  Clay=where(s LT 45 AND c GT 40 AND si LT 40)

;; translation from Lenhard
  b=1.0/(n-1.0) * 1.0/(1-0.5^(n/(n-1)))
  
  openw, un, /get, outfile

  values=[0.05, 0.25, 0.5, 0.75, 0.95]
;;;;;;;;;  SAND 
  sanddata=b[sand]
  ave=mean(sanddata)
  std=stdev(sanddata)
  printf, un, [percentiles(value=values,sanddata), n_elements(sand)];, ave-std, ave, ave+std, max(sanddata)
;;;;;;;;;  LOAMYSAND 
  loamysanddata=b[loamysand]
  ave=mean(loamysanddata)
  std=stdev(loamysanddata)
  printf, un, [percentiles(value=values,loamysanddata), n_elements(loamysand)];, ave-std, ave, ave+std,  max(loamysanddata)
;;;;;;;;;  SANDYLOAM 
  SandyLoamdata=b[SandyLoam]
  ave=mean(SandyLoamdata)
  std=stdev(SandyLoamdata)
  printf, un, [percentiles(value=values,SandyLoamdata), n_elements(SandyLoam)];, ave-std, ave, ave+std,  max(SandyLoamdata)
;;;;;;;;;  SILTLOAM 
  SiltLoamdata=b[SiltLoam]
  ave=mean(SiltLoamdata)
  std=stdev(SiltLoamdata)
  printf, un, [percentiles(value=values,SiltLoamdata), n_elements(SiltLoam)];, ave-std, ave, ave+std,  max(SiltLoamdata)
;;;;;;;;;  LOAM 
  Loamdata=b[Loam]
  ave=mean(Loamdata)
  std=stdev(Loamdata)
  printf, un, [percentiles(value=values,Loamdata), n_elements(Loam)];, ave-std, ave, ave+std,  max(Loamdata)
;;;;;;;;;  SANDYCLAYLOAM 
  SandyClayLoamdata=b[SandyClayLoam]
  ave=mean(SandyClayLoamdata)
  std=stdev(SandyClayLoamdata)
  printf, un, [percentiles(value=values,SandyClayLoamdata), n_elements(SandyClayLoam)];, ave-std, ave, ave+std,  max(SandyClayLoamdata)
;;;;;;;;;  SILTYCLAYLOAM 
  SiltyClayLoamdata=b[SiltyClayLoam]
  ave=mean(SiltyClayLoamdata)
  std=stdev(SiltyClayLoamdata)
  printf, un, [percentiles(value=values,SiltyClayLoamdata), n_elements(SiltyClayLoam)];, ave-std, ave, ave+std,  max(SiltyClayLoamdata)
;;;;;;;;;  CLAYLOAM 
  ClayLoamdata=b[ClayLoam]
  ave=mean(ClayLoamdata)
  std=stdev(ClayLoamdata)
  printf, un, [percentiles(value=values,ClayLoamdata), n_elements(ClayLoam)];, ave-std, ave, ave+std,  max(ClayLoamdata)
;;;;;;;;;  SANDYCLAY 
  SandyClaydata=b[SandyClay]
  ave=mean(SandyClaydata)
  std=stdev(SandyClaydata)
  printf, un, [percentiles(value=values,SandyClaydata), n_elements(SandyClay)];, ave-std, ave, ave+std,  max(SandyClaydata)
;;;;;;;;;  SILTYCLAY 
  SiltyClaydata=b[SiltyClay]
  ave=mean(SiltyClaydata)
  std=stdev(SiltyClaydata)
  printf, un, [percentiles(value=values,SiltyClaydata), n_elements(SiltyClay)];, ave-std, ave, ave+std,  max(SiltyClaydata)
;;;;;;;;;  CLAY 
  Claydata=b[Clay]
  ave=mean(Claydata)
  std=stdev(Claydata)
  printf, un, [percentiles(value=values,Claydata), n_elements(Clay)];, ave-std, ave, ave+std,  max(Claydata)

  close, un
  free_lun, un

end
