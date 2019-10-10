function [tocEntries,tocLabel] = readTocFile(file)
% read the *.toc of a docFile
%
% Input
%  file
%
% Output
%  tocEntries  - a cell--array of char with toc--Entries
%  tocLabel    - 
%

tocEntries = {};
tocLabel = {};
[hasToc,tocLocation] = hasTocFile(file);

if ~hasToc, return; end
  
text = file2cell(tocLocation);
if isempty(text)
  dispPerm(['No toc items in ' tocLocation])
  return;
end
    
for k=1:numel(text)
  line = text{k};
  pos = regexp(line,'\w*','end');
  if ~isempty(pos)
    tocEntries{k} = strtrim(line(1:pos(1)));
    tocLabel{k} = strtrim(line(pos(1)+2:end));
  end
end

end