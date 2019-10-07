function helpStr = getFormatedDoc( file, docFiles,out )
% returns a processed string for normal script files
%
%% Input
% file     - current file
% docFiles - array of @DocFile for lookup crossref--table
%
%% Output
% helpString - a string for publishing
%
%% See also
% DocFile/getFormatedRef DocFile/publish

helpStr = read(file);
if nargin > 2
  helpStr = globalReplacements(helpStr,out);
else
  helpStr = globalReplacements(helpStr);
end
% helpStr = regexprep(helpStr,'_','\\\_');

% if hasTocFile(file)
%   
%   tocFiles = getFilesByToc(file,docFiles);
%   
%   if numel(tocFiles)>0
%     tocContent = getTableOfContent(tocFiles,'toc');
%     
%     htmlTable = regexprep(['%% ' char([10 10]) '<html>' newline tocContent newline '</html>' newline],'\n','\n% ');   
%     
%     ipos = regexp(helpStr,'\n%%|\n$','start');
%     
%     if ~isempty(ipos)
%       helpStr = [helpStr(1:ipos) ...
%         htmlTable ...
%         helpStr(ipos:end)];
%     else
%       helpStr = [helpStr char(10) htmlTable];
%     end
%     
%   end
% end



name = file.sourceInfo.name;

if numel(name)>6 && strcmp(name(end-5:end),'_index')
  [dom, html] = domCreateDocument('html');
  table = domAddChild(dom,html,'table',[],{'width','90%'});
  
  
  f = what(name(1:end-6));
  if ~isempty(f) && ~hasTocFile(file)
    %     f(end).path
    func = helpfunc2struct(f(end).path);
    
    for k=1:numel(func)
      tr = domAddChild(dom,table,'tr');
      
      name = func(k).name;
      if func(k).isclassdir
        href = [func(k).folder '.' func(k).name '.html'];
      else
        href = [ func(k).name '.html'];
      end
      
      td = domAddChild(dom,tr,'td',[],{'width','200px'});
      a = domAddChild(dom,td,'a',[],{'href',href});
      domAddChild(dom,a,'tt',name);
      domAddChild(dom,tr,'td',func(k).description);
    end
    
    str = xmlwrite(dom);
    str = str(40:end);
    str = regexprep(str,'[ ]*\n[ ]*','');
    %     str = regexprep(str,'[ ]*</tt>\n','</tt>');
    %     str = regexprep(str,'[ ]*</a>\n','</a>');
    str = regexprep(['%% Complete Function list' char(10) char(10) str],'\n','\n% ');
    
    
    helpStr = [helpStr char(10) str];
  end
end















