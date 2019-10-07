function [tocEntries,tocLabel] = readTocFile(file)
% read the *.toc of a docFile
%
% Output
% tocEntries  - a cell--array of char with toc--Entries
% tocLabel    - 

[hasToc,tocLocation] = hasTocFile(file);

if hasToc
  
  text = file2cell(tocLocation);
  for k=1:numel(text)
    line = text{k};
    pos = regexp(line,'\w*','end');
    if ~isempty(pos)
      tocEntries{k} = strtrim(line(1:pos(1)));
      tocLabel{k} = strtrim(line(pos(1)+2:end));
    end
  end
  
else
  
  tocEntries = {};
  
end