pro warpFile, refFile, warpFile

  UTM13toUTM14, pattern=warpFile, out=w
  imcorrSetup, refFile, "w"+warpFile 
  openw, oun, /get, warpFile+"comb"
  printf, oun, 2
  printf, oun, "w"+warpfile
  printf, oun, refFile
  close, oun & free_lun, oun
  combunequal, warpFile+"comb", "combined"
  make_gcp_file, "w"+warpFile+"_imcorr.out", warpFile+"_imcorr.pts", 9, 1

end
