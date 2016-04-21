pro printDescprint, $';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;', $';;                                                                          ', $';;  Sand Transport model for the High Plains of the US.  Based on Landsat   ', $';;      imagery, weather data, a sand coverage, and a rangeland coverage.   ', $';;                                                                          ', $';;  CALLING SEQUENCE                                                        ', $';;      HighPlainsDuneModel, inputfile, nocent=nocent, makeNDVI=makeNDVI    ', $';;                            ...other keywords                             ', $';;                                                                          ', $';;  PARAMETERS                                                              ', $';;    --inputfile has the following format                                  ', $';;      number of landsat images                                            ', $';;      list of landsat imagery (must be co-registered & have ENVI .hdr)    ', $';;      list of imagery dates (3 cols year, month, day)                     ', $';;      name of sand .shp file                                              ', $';;      name of rangeland mask file (must have ENVI .hdr) (now .shp file)   ', $';;      directory containing CENTURY                                        ', $';;           must have                                                      ', $';;           .wth files                                                     ', $';;           .key file                                                      ', $';;           CENTURY program and supporting files                           ', $';;               if nocent keyword is set .wth and CENTURY are not necessary', $';;               but CENTURY output files in .lis format are required       ', $';;      directory containing wind files                                     ', $';;           formatted as it is on the Western Weather Observations file    ', $';;      C3-C4 grasslands map for High Plains (must have ENVI .hdr)          ', $';;                                                                          ', $';;  KEYWORDS                                                                ', $';;      if nocent is set the CENTURY model will not be run (see above)      ', $';;      if makeNDVI is set the landsat imagery will be converted to NDVI    ', $';;            otherwise it is assumed to be NDVI byte 0-255 already where   ', $';;            NDVI lt 0 = 0 and NDVI eq 1 = 255                             ', $';;                                                                          ', $';;      The remaining keywords should only be set if you do not want that   ', $';;            portion of the model to be executed, you would rather take the', $';;            previous results specified in the associated file or array.   ', $';;                                                                          ', $';;          fullNDVI=fullNDVI,    must be an NDVI bsq by date (registered)  ', $';;          sandMask=sandMask,    a sandMask file w/ same ns,nl as fullNDVI ', $';;          rangeMask=rangeMask,  a rangeMask file same ns,nl as fullNDVI   ', $';;          fullMask=fullMask,    a combination of range and sand Masks     ', $';;          windFile=windFile,    a kriged windfile registered to UTM Zone14', $';;          corrFile=corrFile,    a file with cent,NDVI slope and offset    ', $';;          noPlot=noPlot,        if set prevents plotting NDVI vs Century  ', $';;          correlation=correlation, an array of correlation coefficients   ', $';;          n_Classes=n_Classes,  the number of classes in the following    ', $';;          classFile=classFile,  a classification of the fullNDVI image    ', $';;          spatCfile=spatCfile   a krigged century outputfile, BSQ by dates', $';;                                                                          ', $';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'	retallend;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	Parses the input file into a structure;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;function readInputFile, inputfile	if not file_test(inputfile) then return, {n_images:-1}	openr, un, /get, inputfile	n_images=0	readf, un, n_images;;Read all of the image file names	filenames=strarr(n_images)		for i=0, n_images-1 do begin		tmp=''		readf, un, tmp		filenames(i) = tmp	endfor	;;Read all of the image dates	dates=intarr(3,n_images)		for i=0, n_images-1 do begin		j=0		tmp=''		readf, un, tmp		tmp=strsplit(tmp, /extract)		if n_elements(tmp) lt 3 then return, {n_images:-2}		for k=0, 2 do begin			reads, tmp(k),j			dates(k,i) = j		endfor	endfor;;read in the remaining file names	sandfile=''	readf, un, sandfile		rangefile=''	readf, un, rangefile		centdir=''	readf, un, centdir		winddir=''	readf, un, winddir		c3c4file=''	readf, un, c3c4file	close, un	free_lun, un;;return the result in a simple structure	return, {n_images:n_images,filenames:filenames, dates:dates, $		sandfile:sandfile, rangefile:rangefile, centdir:centdir,$		winddir:winddir, c3c4file:c3c4file}end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	Three procedures write input meta files for makevegmap, ndvivcent, and ;;	combunequal.  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;pro writeVEGMAPcorrfile, corr, corrfile	openw, oun, /get, corrfile		for i=0, n_elements(corr(0,*))-1 do begin		printf, oun, corr(*,i)	endfor		close, oun	free_lun, ounendpro writeNDVIVCENTmeta,NvCmetafile,n_Classes,spatCfile,maskedNDVIfile,classFile	openw, oun, /get, NvCmetafile	printf, oun, n_Classes	printf, oun, spatCfile	printf, oun, maskedNDVIfile	printf, oun, classfile		close, oun	free_lun, ounendpro writeCOMBUNEQUALmeta, metafile, fnames	openw, oun, /get, metafile	printf, oun, n_elements(fnames)	for i=0, n_elements(fnames)-1 do begin		printf, oun, fnames(i)	endfor	close, oun	free_lun, oun	end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	See Main description;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;pro HighPlainsDuneModel, inputfile, nocent=nocent, makeNDVI=makeNDVI, fullNDVI=fullNDVIfile,$                         sandMask=sandMask, rangeMask=rangeMask, fullMask=fullMask, $                         windFile=windFile, vegMapFile=vegMapFile, noPlot=noPlot, $                         correlation=correlation, n_Classes=n_Classes, classFile=classFile, $                         spatCfile=spatCfile, ndviFltToByte=ndviFltToByte, nomap=nomap, $                         corrFile=corrFile, FVCmap=newVegFile, max_classes=max_classes, $                         logname=logname, scaleBY=scaleBY, daycent=daycent, withSTD=withSTD	if n_elements(inputfile) eq 0 then printDesc	if keyword_set(n_Classes) and not keyword_set(classFile) then begin		print, 'If n_Classes is specified then classFile must also but supplied'		return	endif	if not keyword_set(n_Classes) and keyword_set(classFile) then begin		print, 'If classFile is specified then n_Classes must also but supplied'		return	endif	envistart	jname='OUTPUT.log'	if keyword_set(max_classes) then jname=jname+strcompress(max_classes, /remove_all)	if keyword_set(logname) then jname=jname+logname	journal, jname		input=readInputFile(inputfile)		if input.n_images eq -1 then begin		print, 'ERROR opening input file'		journal		return	endif;	help, /files;;If makeNDVI is set we will convert the input files into NDVI images	if keyword_set(makeNDVI) then begin		outFnames = strarr(input.n_images);;Create NDVI byte scaled 0-255 (0 NDVI=0, 1.0 NDVI=255)		for i=0, input.n_images - 1 do begin			outFnames(i) = input.filenames(i)+'_ndvi'			makeNDVI,input.filenames(i), outFnames(i)		endfor		input.filenames = outFnames;		help, /files	endif;	print, input.dates		;;Combine all of the NDVI images into a single image file with ENVI header;;	ENVI .hdr needs to include the dates for	images for CENTFILE to set up;;	the meta file for SPATCENT        if not keyword_set(fullNDVIfile) then begin           combmeta='combmeta' & 	fullNDVIfile='fullNDVI'           writeCOMBUNEQUALmeta, combmeta, input.filenames           combunequal, combmeta, fullNDVIfile, ndviFltToByte=ndviFltToByte;		help, /files        endif;; the following allows us to resample the NDVI file by any factor.;; This lets you resample LANDSAT data to MODIS data, and it also;; VASTLY improves the registration of the image.          if keyword_set(scaleBY) then begin           smallNDVIfile='rs'+fullNDVIfile;           fNDVIinfo=getFileInfo(fullNDVIfile)           worked=scaleDown(fullNDVIfile, smallNDVIfile,scaleBY)           tmp=fullNDVIfile           fullNDVIfile=smallNDVIfile           smallNDVIfile=tmp        endif;;Make a mask from the sand and range .evf files	if not keyword_set(sandMask) and not keyword_set(fullMask) then begin		sandMask='sandMasktmp';		evfToMask, input.sandfile, fullNDVIfile, sandMask		shpToMask, input.sandfile, fullNDVIfile, sandMask;		help, /files	endif		if not keyword_set(rangeMask) and not keyword_set(fullMask) then begin				rangeMask='rangeMasktmp';		evfToMask, input.rangefile, fullNDVIfile, rangeMask		shpToMask, input.rangefile, fullNDVIfile, rangeMask;		help, /files	endif		;;combing the rangeland mask and the sand mask into one for the classifier	if not keyword_set(fullMask) then begin		fullMask='fullMasktmp'		combinemasks, rangemask, sandMask, fullMask;		help, /files	endif;;Create the Krigged wind map	if not keyword_set(windFile) then begin		windFile='windMap'		windstat, fullNDVIfile, input.winddir, windFile		spatwind, windFile, fullNDVIfile		windFile=windFile+'.out';		help, /files	endif;;Create the spatial century file 	if not keyword_set(spatCfile) then begin		spatCfile='spatCent'		centfiles, fullNDVIfile, input.c3c4file, input.centdir, input.centdir, $			nocent=nocent, spatCfile, input.dates, withSTD=withSTD, daycent=daycent		spatCfile=spatCfile+'.out';		help, /files	endif;; Perform an unsupervised classification of the multi-temporal NDVI image		if not keyword_set(n_Classes) and not keyword_set(classFile) then begin		classFile = 'classNDVItmp'		if keyword_set(max_classes) then $			classFile=classFile+strcompress(max_classes, /remove_all)		n_Classes = classit(fullNDVIfile, classFile, fullMask, num_classes=max_classes)                print, 'N_Classes = ', n_Classes;		help, /files	endif;;Determine the correlation between NDVI and Century output for each class	if not keyword_set(correlation) then begin		NvCmetafile = 'NDVIvsCentMeta'		if keyword_set(max_classes) then $			NvCmetafile=NvCmetafile+strcompress(max_classes, /remove_all)		if keyword_set(logname) then $			NvCmetafile=NvCmetafile+logname		writeNDVIVCENTmeta,NvCmetafile,n_Classes,spatCfile,fullNDVIfile,classFile		correlation=ndvivcent(NvCmetafile);		help, /files		if correlation(0) eq -1 then begin			print, 'ERROR no Correlation possible (too few points?)'			correlation = fltarr(3, n_Classes)			correlation(*,*)=-1;			journal;			envi_exit;			return		endif	endif;;Output nice plots of NDVI vs Century	if not keyword_set(noPlot) and mean(correlation(*,*) eq -1) lt 1 then begin		NvCoutputfile = NvCmetafile+'.out'		NvCplot = NvCmetafile+'.ps'		plotNVC, NvCoutputfile, NvCplot, nclasses=n_Classes-1, nb=input.n_images, /nodetail ;/plotboth;		help, /files	endif	if keyword_set(corrFile) then begin		cols=load_cols(corrFile, correlation);		help, /files		if cols eq -1 then begin			print, 'ERROR: correlation file, ', corrFile, 'will not load'			correlation = fltarr(3, n_Classes)			correlation(*,*)=-1;			journal;			envi_exit;			return		endif	endif	;;Create a future vegation map based on the correlation values and	if not keyword_set(vegMapfile) and not keyword_set(vegFile) and $				not keyword_set(newVegFile) then begin			corrFile = 'NvCcorrelation' & vegFile = 'FutureVegMap'		writeVEGMAPcorrfile, correlation, corrFile		result =makevegmap(classFile, corrFile, vegFile)		if result eq -1 then begin			print, 'Error making veg map, probably bad correlation file'			journal			envi_exit			return		endif		print, classFile, corrFile, vegFile, fullNDVIfile, fullMask		newVegFile = 'FutureVegMapCorrected';		help, /files		correctvegmap, classFile, corrFile, vegFile, fullNDVIfile, fullMask, newVegFile;		help, /files	endif	;;Create final sand transport map from the wind and vegetation map	if not keyword_set(nosand) then begin		sandFile = 'SandTransportMap'		if keyword_set(logname) then sandFile=sandFile+logname				sandmodel, newVegFile, windFile, sandFile;		help, /files	endif	;;Make a resized sand map that can later be added to a map of the entire HighPlains	if not keyword_set(nomap) then begin		smallMap='resizedSand'		if keyword_set(logname) then smallMap=smallMap+logname		scaleFactor=10		print, scaleDown(sandFile, smallMap, scaleFactor)		print, scaleDown(windFile, 'windrs', scaleFactor)		print, scaleDown(newVegFile, 'vegrs', scaleFactor)		print, scaleDown(fullMask, 'maskrs', scaleFactor);		help, /files	endif			journal;	envi_exit	;	help, /files	close, /all;	classfiles=findfile('classNDVI*');	if classfiles(0) ne -1 then begin;		for i=0, n_elements(classfiles) -1 do begin;			file_delete, classfiles(i);		endfor;	endif;	if n_elements(NvCoutputfile) ne 0 then $;		if file_test(NvCoutputfile) then file_delete, NvCoutputfile;	if n_elements(rangeMask) ne 0 then $;		if file_test(rangeMask) then file_delete, rangeMask;	if n_elements(sandMask) ne 0 then $;		if file_test(sandMask) then file_delete, sandMask;;	if n_elements(vegFile) ne 0 then $;		if file_test(vegFile) then file_delete, vegFile;	if n_elements(fullNDVIfile) ne 0 then $;		if file_test(fullNDVIfile) then file_delete, fullNDVIfile;	if n_elements(sandFile) ne 0 then $;		if file_test(sandFile) then file_delete, sandFileend