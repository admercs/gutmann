;; a sequence of useful commandspro finishthumbs	home	cd, 'Public'	cd, 'Drop Box';	cd, 'PERU'	cd, 'day3'	cd, 'larger'	list=findfile('*.jpg')	up	if list(0) eq -1 then begin		makeReasonable, newsize=1000	endif else begin		makeReasonable, start=n_elements(list), newdir='larger', newsize=1000	endelseend	;;simple directory aliases'pro mlib	cd, 'BigusDiskus:Applications (Mac OS 9):RSI:ENVI 3.4:IDL_5.4:my_idl_lib:sand:'endpro dd	cd, 'Mystic:Documents:'endpro home	cd, 'Mystic:Users:gutmann:'endpro we	sm	cd, 'centruns'endpro misr	cd, 'BigusDiskus:TAwork:4093-5093:TexLabs:BRDFlab:MISRdata:'endpro mr;	cd, 'Mystic:'	cd, 'BigusDiskus:'	up	cd, 'SandModel'	cd, 'ModelRuns'endpro taw;	cd, 'Mystic:'	cd, 'BigusDiskus:'	up	cd, 'TAwork'endpro sm;	cd, 'Mystic:'	cd, 'BigusDiskus:'	up	cd, 'SandModel'endpro cdcd	cd, 'Mystic:Volumes:'	i=findfile('CSES*')	if n_elements(i) eq 1 and i(0) ne '' then begin		cd, i(0)+':'	endif else begin		print, 'Unsuccesful, Volume name(s)=', i		filename = ''		read, 'enter one of the above', filename		if file_test(filename, /directory) then begin			print, 'Changeing directory'			cd, filename		endif	endelseendpro pwd	cd, current=current	print, currentend;; executes equivilant to unix ls commandpro ls, pat	cd, current=current	print, current	print, '-----------'	if n_elements(pat) eq 0 then pat='*'	i= findfile(pat)	for j=0, n_elements(i)-1, 2 do begin		if j+1 ne n_elements(i) then begin			print, i(j), '                 ', i(j+1)		endif else	 print, i(j)	endfor	if n_elements(i) eq 0 then print, i	print, n_elements(i)end;;change directoried to key* where key is a prefix to a directorypro mcd, key	if n_elements(key) eq 0 then key=''	if file_test(key, /directory) then begin		cd, key	endif else begin			key=key+'*'		i=findfile(key)		if n_elements(i) eq 1 then begin			j=strlen(i(0))			if strmid(i(0), j-1, j) ne ':' then print, i(0), ' is not a directory' $			else cd, strmid(i(0), 0, j-1)		endif else print, i	endelse	end;;spawn but search the bin directorypro bs, app	if n_elements(app) eq 0 then return	app = 'Mystic:Applications (Mac OS 9):Bin:*'+app+'*'	name=findfile(app)	if n_elements(name) eq 1 and name(0) ne -1 then begin		spawn, name(0)	endif else print, nameend;; nolonger needed since alpha backups have been turned off (under config->preferences->backups);pro tld;	names=findfile('*~');	if names(0) eq '' then begin;		print, 'No files matching that pattern';		return;	endif;	;	for i=0, n_elements(names)-1 do begin ;		print, names(i);		file_delete, names(i);	endfor;endpro clearidl widget_control, /reset & close, /all & heap_gc & retallendpro up	cd, '::'endpro dispbsq, fname, ns, nl, nb, type=type	openr, un, /get, fname	img = make_array(ns, nl, type=type)	for i=0, nb-1 do begin;		window, i+1;		wset, i+1		if ns lt 400 and nl lt 300 then begin			for i=i, (800/ns + 600/nl)<nb-1 do begin				readu, un, img				tvscl, img, i			endfor		endif else begin			readu, un, img			tvscl, img		endelse	endfor	close, un	free_lun, unendpro head, fname, comp=comp, n=n	if not keyword_set(n) then n=10	if not keyword_set(comp) then begin		name=findfile(fname+'*')		if n_elements(name) lt 2 then begin			fname=name(0)		endif else begin print, name & return &endelse	endif	openr, un, /get, fname		for i=0,n-1 do begin		if not eof(un) then begin			s=''			readf, un, s			print, s		endif	endforendpro more, fname, comp=comp	if not keyword_set(comp) then begin		name=findfile(fname+'*')		if n_elements(name) lt 2 then begin			fname=name(0)		endif else begin print, name & return &endelse	endif		if not file_test(fname) then return		openr, un, /get, fname		while not eof(un) do begin		s=''		readf, un, s		print, s	endwhileend