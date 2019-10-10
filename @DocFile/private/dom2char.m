function out = dom2char(dom)

s = xmlwrite(dom);
if numel(s)>46
  out = s(40:end);
  out = regexprep(out,'<text>|</text>','');
  out = regexprep(out,'(\n( )*)*\n','\n');
  % redo links
  out = regexprep(out,'\&lt;a href="(.*?)"\&gt;(.*?)\&lt;/a\&gt;','<a href="$1">$2</a>');
    
  %regexprep(out,'&lt;([^\ ]+)\ ([^(&gt;)]+)&gt;','<a href="$1">$2</a>'); % make links
  %   out = regexprep(['%' char(10)  out],'\n','\n% ');
  %   out = [char(10) out char(10), '%' char(10)]; % save cell end
else
  out = '';
end
