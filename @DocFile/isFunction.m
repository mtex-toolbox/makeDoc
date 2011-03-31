function [isFun,Syntax] = isFunction(file)
% checks whether docFile is a function or a script file
%
%% Input
% file   - a @DocFile
%
%% Output
% isFun  - |true| / |false| 
% Syntax - if a function, get the Syntax of the Function

str = read(file);
% expect the first function string to be syntax and not comment ?!

hasKeyword = strfind(str,'function ');
isFun = false;
if ~isempty(hasKeyword)
  % Syntax = regexp(str,'(?<=^function )|(?<=\n[ ]*function ))(.*?)\n','match');

  lineBreak = regexp(str,'\n');
  if hasKeyword(1) == 1
    Syntax = str(10:lineBreak(1));
  else
    lastLineBreak = lineBreak(lineBreak<hasKeyword(1));    
    lineTillFuncStr = str(lastLineBreak+1:hasKeyword(1)+7);
    
    if isempty(strfind(lineTillFuncStr,'%'))
     nextLineBreak = lineBreak(lineBreak > hasKeyword(1));
     Syntax = str(hasKeyword(1)+9:nextLineBreak(1));
    end
  end

  if exist('Syntax','var')
    Syntax = strtrim(Syntax);
    Syntax = regexprep(Syntax,'varargin','...,param,val,...');    
    isFun = true;
  end
end
