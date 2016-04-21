pro resizeFile, infile, outfile, scale
  data=read_tiff(infile)
  sz=size(data)
  newData=resizeImg(data, sz[1], sz[2], sz[1]/scale, sz[2]/scale)
  write_tiff, outfile, newData, /short
end
