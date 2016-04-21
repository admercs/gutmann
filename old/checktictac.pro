function checkBoard

return, -1
end


pro addNode, curloc

curloc = curloc+1

board(curloc) = 1
if curloc eq ending and checkBoard() eq 1 then begin
      print, board

board(curloc) = 0
if curloc eq ending and checkBoard() eq 1 then begin
      print, board

curloc=curloc-1

end


pro checktictac
  theBoard