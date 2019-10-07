function out = fileIsNewer(file1,file2)

% is f2 newer than f1
d1 = dir(file1);
d2 = dir(file2);
if ~isempty(d1) && ~isempty(d2)
  out = (d1.datenum > d2.datenum);
else
  out = true;
end

end