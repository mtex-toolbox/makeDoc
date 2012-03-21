function helpStr = getFormatedRef( file ,varargin)
% returns a processed string for function file
%
%% Input
% file     - current file
%
%% Output
% helpString - a string for publishing
%
%% Remarks !TODO
% 'input', 'output', 'example', 'see also', 'description', 'syntax', 'view code'
%
%% See also
% DocFile/getFormatedDoc DocFile/publish

options = parseArguments(varargin);
options.file = file;

sections = help2struct(file,options);

if ~isempty(sections)
  content = addContentByTopic('',sections,sections(1).title,@inline);
  if isempty(content)
    content = addTitle('',sections(1).title);
  end
  content = [content char(10) '%% View Code' char(10) '% '];
  content = addContentByTopic(content,sections,'Description',@inline);
  [content, isNew ]= addContentByTopic(content,sections,'Syntax',@preSyntax,options);
  [isFunc, Syntax] = isFunction(file);
  if ~isNew && isFunc
    content = [addTitle(content,'Syntax') preSyntax(Syntax,sections,options)];
  end
  content = addContentByTopic(content,sections,'Input',@preInComment,options);
  content = addContentByTopic(content,sections,'Output',@preOutComment,options);
  content = addContentByTopic(content,sections,'Remarks',@inline);
  content = addContentByTopic(content,sections,'Example',@pre);
  content = addContentByTopic(content,sections,'See also',@inline);
  helpStr = content;
else
  helpStr = 'error';
end

% helpStr


function options = parseArguments(options)

if ~isstruct(options)
  if mod(numel(options),2)
    error('forgotten argument of option');
  end
  options = cell2struct(options(2:2:end)',options(1:2:end)');
end

if ~isfield(options,'outputDir')
  options.outputDir = tempdir;
end



function  sections = help2struct(file,options)
% struct('title','sectioname','content','descriptive text')


helpStr = helpfunc(file.sourceFile);
docName = file.sourceInfo.docName;
Title = regexprep(docName,'(\w*)\.(\w*)', ...
  ['$2' char(10) '  \(method of [[$1_index.html,$1]]\)' char(10) ' % ']);

helpStr = [' % ' Title  char(10)  helpStr];

helpStr = regexprep(helpStr,'(?<=^|\n) ','%');
helpStr = globalReplacements(helpStr,options.outputDir);
m = m2struct(helpStr);


% unsafe
% sectionPattern = '%%(?<title>(.*?))\n(?<content>(.*?))(?=\n%%|$)|%%(?<title>(.*?))(?=\n%%|$)';
% sections = regexp(helpStr,sectionPattern,'names');


for k=1:numel(m)
  sections(k).title = strtrim(m(k).title);
  
  text = cellfun(@(x) ['% ' x char(10)],m(k).text,'Uniformoutput',false);
  text = [text{:}];
  sections(k).content = text;
  %   sections(k).content = regexprep(sections(k).content, '^%','');
end

function [content,isNew] = addContentByTopic(content,sections,topic,format,options)

newContent = getContentByTopic(sections,topic);
isNew = ~isempty(newContent);
if isNew
  if nargin > 4,
    newContent = feval(format,newContent,sections,options);
  elseif nargin > 3
    newContent = feval(format,newContent,sections);
  end
  
  content =  [addTitle(content,topic)  newContent];
end

function content = addTitle(content,title)

if ~isempty(content)
  c = char(10);
else
  c = '';
end

content = [content c '%% ' title];


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
     content = [content char(10) '% ' char(10)  sections(k).content];
  else
    topicFound = false;
  end
end

content = regexprep(content,'^\s|\n','\n');

% % topic
% {sections.title}
% isTopic = ~cellfun('isempty',regexpi({sections.title},topic,'start'))
% if any(isTopic)
%   content = [' ' sections(isTopic).content];
%   nextTopic = find(isTopic)+1;
%   nextTopic
%   
%   while nextTopic <= numel(isTopic) && isempty(sections(nextTopic).title)
%     content =[ content char(10) '% ' char(10) sections(nextTopic(1)).content];
%     nextTopic = nextTopic+1;
%   end
%   
%   content = regexprep(content,'^\s|\n','\n');
% else
%   content = '';
% end


function out = inline(in,sections)

out = subText(in,1,numel(in));


% out = regexprep([char(10) '% ' out],'\n%[ ]*','\n% ');
out = regexprep(out,'\n\n','\n%');


function out = pre(in,sections)

lineStart = regexp([in  '% '],'(^%|\n% )');

f = {}; % function line
c = {}; % comment line
out = '';
for k=1:numel(lineStart)-1
  if (numel(in)>lineStart(k)+4) && all(in( lineStart(k)+2:lineStart(k)+4) == ' ')
    if ~isempty(c)
      c = cellfun(@(x) [char(10) x],c,'uniformoutput',false);
      c = [c{:}];
      out = [out char(10) '%% ' c];
      
      c = {};
    end
    f{end+1} = in(lineStart(k)+5:lineStart(k+1)-1);
  else
    if ~isempty(f)
      f = cellfun(@(x) [char(10) x],f,'uniformoutput',false);
      f = [f{:}];
      
      out = [out char(10) f char(10) ];
      f = {};
    end
    c{end+1} =  in(lineStart(k)+1:lineStart(k+1)-1);
  end
  
end
c = cellfun(@(x) [char(10) x],c,'uniformoutput',false);
c = [c{:}];
out = [out char(10) '%% ' c char(10)];

out = regexprep(out,'\n( )*','\n');
out = regexprep(out,'\n(\n%( )*\n)*','\n');


% description line       %%
%   function line    ->  % description line
% description line
%                        function line
%
%                        %%
%                        % description line
%

% out = regexprep(in, '(^%|\n%)  [ ]+','\n');
% out = regexprep(out, '(^%|\n%)[ ]*','\n% ');
% out = regexprep(out, '(^%|\n%)(.*?)\n(?!%)','\n%$2\n\n');
% out = regexprep(out, '((^|\n)(?!%))(.*?)\n%','\n$2\n\n%%\n%');

function out = preOutComment(in,sections,options)

dom = domCreateDocument('html');

table = domAddChild(dom,dom.getDocumentElement,'table',[],...
  {'class','funcref','width','100%','cellpadding','4','cellspacing','0'});


content = format(in,options);
for k=1:numel(content)
  row = domAddChild(dom,table,'tr');
  td = domAddChild(dom,row,'td',[],{'width','100px'});
  domAddChild(dom,td,'tt',regexprep(content(k).param,'[ ]*\|[ ]*',', '));
  %   domAddChild(dom,row,'td',content(k).comment);
  td = domAddChild(dom,row,'td');
  if ~isempty(content(k).comment)
    node = dom.importNode(content(k).comment,true);
    td.appendChild(node);
  end
end

out = dom2char(dom);
out = regexprep([char(10) char(10) out char(10)],'\n','\n% ');
% s = xmlwrite(dom);
% out = s(40:end);
% out = regexprep(out,'\r','');
% out = regexprep([char(10)  out],'\n','\n% ');


function out = preSyntax(in,sections,options)

% if it is correctly indented then MATLAB 2012a just does the right thing
if any(strfind(in,'%   '))
  out = in;
  return
end

dom = domCreateDocument('html');

div = domAddChild(dom,dom.getDocumentElement,'div',[],...
  {'width','100%','class','syntax'});


content = format(in,options);

for k=1:numel(content)  
  p = domAddChild(dom,div,'div');
  domAddChild(dom,p,'tt',regexprep(content(k).param,'[ ]*\|[ ]*',', '));
end

for k=1:numel(content)
  if ~isempty(content(k).comment)
    div = domAddChild(dom,dom.getDocumentElement,'div',[],{'class','syntax','width','100%'});
    domAddChild(dom,div,'tt',content(k).param);
    
    node = dom.importNode(content(k).comment,true);
  
    p = node.getElementsByTagName('p');
    for l=0:p.getLength-1
      dom.renameNode(p.item(l),[],'span');
    end
    div.appendChild(node);
  end
end

out = dom2char(dom);
out = regexprep([char(10) char(10) out char(10)],'\n','\n% ');
% out = out(2:end);

function out = preInComment(in,sections,options)

dom = domCreateDocument('html');

table = domAddChild(dom,dom.getDocumentElement,'table',[],...
  {'class','funcref','width','100%','cellpadding','4','cellspacing','0'});


content = format(in,options);
for k=1:numel(content)
  row = domAddChild(dom,table,'tr');
  td = domAddChild(dom,row,'td',[],{'width','100px'});
  domAddChild(dom,td,'tt',content(k).param);
  
  if ~isempty(content(k).comment)
    
    td = domAddChild(dom,row,'td');
    node =  dom.importNode(content(k).comment,true);
    td.appendChild(node);
  end
  %     xmlwrite(node)
  %   regexprep(content(k).comment,'\n','')
end


% newContent = getContentByTopic(sections,'Flags')
syntax = regexprep(sections(1).title,'\(.*\)','');

[newContent]= getContentByTopic(sections,'Options');

if ~isempty(newContent)
  
  content = format(newContent,options);
  
  row = domAddChild(dom,table,'tr');
  td = domAddChild(dom,row,'td',[],{'width','100px'});
  domAddChild(dom,td,'tt','param,val');
  
  td = domAddChild(dom,row,'td',['Parameters and values that control ' syntax ]);
  
  paramtable =  domAddChild(dom,td,'table',[],{'class','paramval','width','100%','cellpadding','4','cellspacing','0'});
  row = domAddChild(dom,paramtable,'tr');
  td = domAddChild(dom,row,'td','Parameter',{'width','100px','class','header'});
  domAddChild(dom,row,'td','Description',{'class','header'});
  
  for k=1:numel(content)
    row = domAddChild(dom,paramtable,'tr');
    td = domAddChild(dom,row,'td',[],{'width','150px'});
    domAddChild(dom,td,'tt',['''' regexprep(content(k).param,'[ ]*\|[ ]*',''', ''') '''']);
    %     domAddChild(dom,row,'td',regexprep(content(k).comment,'\n%',''));
    
    if ~isempty(content(k).comment)
      td = domAddChild(dom,row,'td');
      
      node =  dom.importNode(content(k).comment,true);
      td.appendChild(node);
    end
  end
  
end

[newContent]= getContentByTopic(sections,'Flags');



if ~isempty(newContent)
  %   newContent
  content = format(newContent,options);
  
  row = domAddChild(dom,table,'tr');
  td = domAddChild(dom,row,'td',[],{'width','100px'});
  domAddChild(dom,td,'tt','param');
  td = domAddChild(dom,row,'td',['Options that control the ' syntax ' behavior']);
  
  paramtable =  domAddChild(dom,td,'table',[],{'class','paramval','width','100%','cellpadding','4','cellspacing','0'});
  row = domAddChild(dom,paramtable,'tr');
  td = domAddChild(dom,row,'td','Parameter',{'width','100px','class','header'});
  domAddChild(dom,row,'td','Description',{'class','header'});
  
  for k=1:numel(content)
    row = domAddChild(dom,paramtable,'tr');
    td = domAddChild(dom,row,'td',[],{'width','150px'});
    domAddChild(dom,td,'tt',['''' regexprep(content(k).param,'[ ]*\|[ ]*',''', ''') '''']);
    
    if ~isempty(content(k).comment)
      td = domAddChild(dom,row,'td');
      node =  dom.importNode(content(k).comment,true);
      td.appendChild(node);
    end
    %     domAddChild(dom,row,'td',regexprep(content(k).comment,'\n%',''));
  end
  
end

out = dom2char(dom);
out = regexprep([char(10) char(10) out char(10)],'\n','\n% ');


function form = format(in,options,form)

in = regexprep(in,'%','');
in = strtrim(in);

% in
if nargin<3
  form = struct('param',{},'comment',{});
end

%
if isempty(in)
  return
end

start = strfind(in,'-');
if isempty(start)
  form(end+1).param = in;
else
  lineBreak = [0 regexp(in,'\n')];
  lastLineBreak = max(lineBreak(lineBreak<start(1)));
  
  pn = strfind(in,'--');
  start(ismember(start,[pn pn+1])) = [];
  
  if numel(start)>1
    nextLineBreak = max(lineBreak(lineBreak<start(2)));
  else
    nextLineBreak = numel(in);
  end
  
  param = strtrim(in(lastLineBreak+1:start(1)-1));
  param = regexprep(param,'--','-');

  comment = subText(in,start(1)+2,nextLineBreak+1,true);
  comment = regexprep(comment,'--','-');
	if ~isempty(strtrim(comment))
    s = regexprep(['%% ' char(10) comment],'\n','\n% ');

    fname = fullfile(options.outputDir, ...
      [options.file.sourceInfo.docName '_tmp.m']);

    text = tmpPublish(s,fname);
  else
    text = [];
  end
  
  form(end+1).param = param;
  form(end).comment = text;
  
  if strcmp(in(nextLineBreak+1:end),in)
    disp(in)
    view(options.file)
    error ('to much -')
  end
  form = format(in(nextLineBreak+1:end),options,form);
end





