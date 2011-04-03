function out = dom2char(dom)

s = xmlwrite(dom);
if numel(s)>46
  out = s(40:end);
  out = regexprep(out,'<text>|</text>','');
  out = regexprep(out,'(\n( )*)*\n','\n');
%   out = regexprep(['%' char(10)  out],'\n','\n% ');
%   out = [char(10) out char(10), '%' char(10)]; % save cell end
else
  out = '';
end
