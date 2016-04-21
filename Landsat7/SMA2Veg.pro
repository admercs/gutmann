;; parses an index file for filenames and relavant information
FUNCTION readIndex, file
  openr, un, /get, file
  line=''

;; read and parse the first line
  readf, un, line
  dex=strsplit(line, /extract)
;  info={name:'../SMA/'+dex[0]+'.sma', base:dex[0], $
  info={name:dex[0], base:dex[0], $
        reverse:fix(dex[1]), band:fix(dex[3])}

;; read and parse all remaining lines
  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     dex=strsplit(line, /extract)
;     info=[info,{name:'../SMA/'+dex[0]+'.sma', base:dex[0], $
     info=[info,{name:dex[0], base:dex[0], $
                 reverse:fix(dex[1]), band:fix(dex[3])}]
  ENDWHILE

;; cleanup and return
  close, un
  free_lun, un
  return, info
END

PRO findNpercent, img, percent=ipcent, top=top, bot=bot
  nbins=10000
  pcent=ipcent/100.
  mx=max(img)
  mn=min(img)
;  print, mx, mn
  hist=histogram(fix((img-mn)*(10000./(mx-mn))));, nbins=nbins)

  curP = 0
  curPix=0
  i=0
  npix=float(n_elements(img))
  print, npix

;; find the bottom pcent pixels
  WHILE (curP LT pcent) AND (i LT nbins-1) DO begin
     curPix=curPix+hist[i]
     curP=curPix/npix
     i=i+1
  ENDWHILE
  print, i, curP, curPix
  bot=(i-1)*((mx-mn)/10000.)+mn

;; find the top pcent pixels
  i=nbins-1
  curP=0
  curPix=0
  WHILE (curP LT pcent) AND (i GT 0) DO BEGIN
     curPix=curPix+hist[i]
     curP=curPix/npix
     i=i-1
  ENDWHILE
  print, i, curP, curPix
  top=(i+1)*((mx-mn)/10000.)+mn
END


PRO sma2veg, indexFile, percent=percent
  envistart
  IF NOT keyword_set(percent) THEN percent=1

  fileDex=readIndex(indexFile)
  print, 'NAME                    Gain       offset      top %'
  FOR i=0,n_elements(fileDex)-1 DO BEGIN
     info=getFileInfo(fileDex[i].name)
     openr, un, /get, fileDex[i].name
     
     data=make_array(info.ns, info.nl, type=info.type)
     point_lun, un, info.ns*info.nl*info.type*fileDex[i].band
     readu, un, data
     close, un
     free_lun, un

;; modify the data to be vegetation from 0 to 1
     IF fileDex[i].reverse EQ -1 THEN data=temporary(data)*(-1)
     findNpercent, data, percent=percent, top=top, bot=bot
     gain = (top-bot)/10000.
     offset = float(bot)

     print, fileDex[i].name,'     ', gain*10000, offset, top
;     print, min(data), bot, max(data), top, fileDex[i].reverse
     data=FIX((temporary(data)-offset) /gain)

;; make sure all values are reasonable
     index=where(data GT 10000, count)
     IF count GT 0 THEN data[index]=10000
     index=where(data LT 0, count)
     IF count GT 0 THEN data[index]=0
  
;; write the output file with an ENVI hdr   
     outname=fileDex[i].base+'.veg'
     openw, oun, /get, outname
     writeu, oun, data
     info.nb=1
     info.type=2
     setENVIhdr, info, outname
     close, oun
     free_lun, oun
  ENDFOR

END
  
