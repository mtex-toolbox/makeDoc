function helpStr = getFormatedRef( docFile ,varargin)
% returns a processed string for function file
%
% Input
% file     - current file
%
% Output
% helpString - a string for publishing
%
% Remarks !TODO
% 'input', 'output', 'example', 'see also', 'description', 'syntax', 'view code'
%
% See also
% DocFile/getFormatedDoc DocFile/publish

sections = help2struct(docFile);

if ~isempty(sections)
  content = addContentByTopic('',sections,sections(1).title,@inline);
  if isempty(content)
    content = addTitle('',sections(1).title);
  end
  content = [content newline '%% View Code' newline '% '];
  content = addContentByTopic(content,sections,'Description',@inline);
  [content, isNew ]= addContentByTopic(content,sections,'Syntax',@preSyntax);
  [isFunc, Syntax] = isFunction(docFile);
  if ~isNew && isFunc
    content = [addTitle(content,'Syntax') newline preSyntax(Syntax,sections)];
  end
  content = addContentByTopic(content,sections,'Input',@preVarComment);
  content = addContentByTopic(content,sections,'Options',@preVarComment);
  content = addContentByTopic(content,sections,'Flags',@preVarComment);
  content = addContentByTopic(content,sections,'Output',@preVarComment);
  content = addContentByTopic(content,sections,'Remarks',@inline);
  content = addContentByTopic(content,sections,'Example',@pre);
  content = addContentByTopic(content,sections,'See also',@inline);
  helpStr = content;
else
  helpStr = 'error';
end


% helpStr



function  sections = help2struct(file)
% struct('title','sectioname','content','descriptive text')

%helpStr = helpfunc(file.sourceFile);
process = helpUtils.helpProcess(1, 1, {file.sourceFile});
process.getHelpText;
helpStr = process.helpStr;

if isempty(helpStr)
  process = helpUtils.helpProcess(0,1, {file.sourceFile});

  process.getHelpText;
  
  helpStr = process.helpStr;
  
end

docName = file.sourceInfo.docName;
Title = regexprep(docName,'(\w*)\.(\w*)', ...
  ['$2' newline '  \(method of <$1_index.html $1>\)' newline ' % ']);

helpStr = [' % ' Title  newline  helpStr];

helpStr = regexprep(helpStr,'(?<=^|\n) ','%');

keyWords = {'Input','Output','Syntax','Options','Flags','See also','Description','Example'};
for i = 1:numel(keyWords)
  helpStr =  regexprep(helpStr,['\n\%\s*' keyWords{i}],['\n\%\% ' keyWords{i}]);
end

helpStr = globalReplacements(helpStr);
m = m2struct(helpStr);


% unsafe
% sectionPattern = '%%(?<title>(.*?))\n(?<content>(.*?))(?=\n%%|$)|%%(?<title>(.*?))(?=\n%%|$)';
% sections = regexp(helpStr,sectionPattern,'names');

for k=1:numel(m)
  sections(k).title = strtrim(m(k).title);
  
  text = cellfun(@(x) ['% ' x newline],m(k).text,'Uniformoutput',false);
  text = [text{:}];
  sections(k).content = text;
  %   sections(k).content = regexprep(sections(k).content, '^%','');
end

end

function [content,isNew] = addContentByTopic(content,sections,topic,format)

newContent = getContentByTopic(sections,topic);
isNew = ~isempty(newContent);
if isNew
  
  newContent = feval(format,newContent,sections);
  content =  [addTitle(content,topic)  newContent];
end

end

function content = addTitle(content,title)

if ~isempty(content)
  c = newline;
else
  c = '';
end

content = [content c '%% ' title];

end

% -----------------------------------------------------------
function content = getContentByTopic(sections,topic,format)

topic = regexptranslate('escape',topic);
% regexpi({sections.title},topic,'start');
topicFound = false;
content = '';
for k=1:numel(sections)
  if strncmp(lower(sections(k).title),lower(topic),numel(topic))
    content = [' ' sections(k).content];
    topicFound = true;
  elseif topicFound && isempty(sections(k).title)
     content = [content newline '% ' newline  sections(k).content];
  else
    topicFound = false;
  end
end

content = regexprep(content,'^\s|\n','\n');

end


% ------------------------------------------------------------
function out = inline(in,varargin)

out = subText(in,1,numel(in));

% out = regexprep([newline '% ' out],'\n%[ ]*','\n% ');
out = regexprep(out,'\n\n','\n%');

end

function out = pre(in,varargin)

lineStart = regexp([in  '% '],'(^%|\n% )');

f = {}; % function line
c = {}; % comment line
out = '';
for k=1:numel(lineStart)-1
  if (numel(in)>lineStart(k)+4) && all(in( lineStart(k)+2:lineStart(k)+4) == ' ')
    if ~isempty(c)
      c = cellfun(@(x) [newline x],c,'uniformoutput',false);
      c = [c{:}];
      out = [out newline '%% ' c];
      
      c = {};
    end
    f{end+1} = in(lineStart(k)+5:lineStart(k+1)-1);
  else
    if ~isempty(f)
      f = cellfun(@(x) [newline x],f,'uniformoutput',false);
      f = [f{:}];
      
      out = [out newline f newline ];
      f = {};
    end
    c{end+1} =  in(lineStart(k)+1:lineStart(k+1)-1);
  end
  
end
c = cellfun(@(x) [newline x],c,'uniformoutput',false);
c = [c{:}];
out = [out newline '%% ' c newline];

out = regexprep(out,'\n( )*','\n');
out = regexprep(out,'\n(\n%( )*\n)*','\n');

end

function out = preVarComment(str,varargin)
% translate variable name / comment pairs into a table

dom = domCreateDocument('html');

table = domAddChild(dom,dom.getDocumentElement,'table',[],...
  {'class','funcref','width','100%','cellpadding','4','cellspacing','0'});

str = regexprep(str,'%','');
str = regexp(str,newline,'split');
varComment = regexp(str,'-','split','once');

for k=1:numel(varComment)
  if isempty(varComment{k}) || isempty(strtrim(varComment{k}{1}))
    continue
  end
  
  try
    row = domAddChild(dom,table,'tr');
    td = domAddChild(dom,row,'td',[],{'width','100px'});
    domAddChild(dom,td,'tt',strtrim(varComment{k}{1}));
  
    td = domAddChild(dom,row,'td');
    domAddChild(dom,td,'tt',makeLinks(varComment{k}{2}));
  catch
    dispPerm(['  Error preparing <a href="matlab: edit(''' ...
      docFile.sourceFile ''')">',docFile.sourceInfo.docName '</a>']);
    varComment{k}
  end
end

out = dom2char(dom);
out = regexprep([newline newline out newline],'\n','\n% ');

end


function in = preSyntax(in,varargin)

% if it is correctly indented then MATLAB 2012a just does the right thing
if ~any(strfind(in,'%   '))
  dispPerm(['  wrong syntax identation! <a href="matlab: edit(''' ...
    docFile.sourceFile ''')">',docFile.sourceInfo.docName '</a>']);
end

end

function out = makeLinks(in)
out = strtrim(regexprep(in,'<([^\ ]+)\ ([^>]+)>','<a href="$1">$2</a>'));
end

end