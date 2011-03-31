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

sections = help2struct(file);

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
  content = addContentByTopic(content,sections,'Example',@pre);
  content = addContentByTopic(content,sections,'See also',@inline);
  helpStr = content;
else
  helpStr = 'error';
end


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



function  sections = help2struct(file)
% struct('title','sectioname','content','descriptive text')


helpStr = helpfunc(file.sourceFile);
helpStr = regexprep( helpStr,'@(\w*)','[[$1_index.html,$1]]');
% helpStr = getHelp(file);
%
docName = file.sourceInfo.docName;
Title = regexprep(docName,'(\w*)\.(\w*)', ...
  ['$2' char(10) '   \(method of [[$1_index.html,$1]]\)' char(10) ' % ']);

helpStr = [' % ' Title  char(10)  helpStr];

sectionPattern = '%(?<title>(.*?))\n(?<content>(.*?))(?=\n %|$)';
sections = regexp(helpStr,sectionPattern,'names');
%
for k=1:numel(sections)
  sections(k).title = strtrim(sections(k).title);
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
regexpi({sections.title},topic,'start');

isTopic = ~cellfun('isempty',regexpi({sections.title},topic,'start'));
if any(isTopic)
  content = [' ' sections(isTopic).content];
  nextTopic = find(isTopic)+1;
  
  while nextTopic <= numel(isTopic) && isempty(sections(nextTopic).title)
    content =[ content char(10) '% ' char(10) sections(nextTopic).content];
    nextTopic = nextTopic+1;
  end
  
  content = regexprep(content,'^\s|\n','\n%');
else
  content = '';
end


function out = inline(in,sections)

out = regexprep([char(10) '% ' in],'\s%[ ]+','\n% ');

function out = pre(in,sections)

% description line       %%
%   function line    ->  % description line
% description line       
%                        function line
%                        
%                        %%
%                        % description line
%

out = regexprep(in, '(^%|\n%)  [ ]+','\n');
out = regexprep(out, '(^%|\n%)[ ]*','\n% ');
out = regexprep(out, '(^%|\n%)(.*?)\n(?!%)','\n%$2\n\n');
out = regexprep(out, '((^|\n)(?!%))(.*?)\n%','\n$2\n\n%%\n%');

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
% s = xmlwrite(dom);
% out = s(40:end);
% out = regexprep(out,'\r','');
% out = regexprep([char(10)  out],'\n','\n% ');


function out = preSyntax(in,sections,options)

dom = domCreateDocument('html');

div = domAddChild(dom,dom.getDocumentElement,'div',[],...
  {'width','100%','class','syntax'});


content = format(in,options);

for k=1:numel(content)
  %   row = domAddChild(dom,table,'tr');
  
  p = domAddChild(dom,div,'div');
  domAddChild(dom,p,'tt',regexprep(content(k).param,'[ ]*\|[ ]*',', '));
end

for k=1:numel(content)
  if ~isempty(content(k).comment)
    %     text = ['<tt>' content(k).param  '</tt> ' content(k).comment];
    div = domAddChild(dom,dom.getDocumentElement,'div',[],{'class','syntax','width','100%'});
    domAddChild(dom,div,'tt',content(k).param);
    
    node = dom.importNode(content(k).comment,true);
    p = node.getElementsByTagName('p');
    for l=0:numel(p)-1
      dom.renameNode(p.item(l),[],'span');
    end
    div.appendChild(node);
  end
end

out = dom2char(dom);




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


function out = dom2char(dom)

s = xmlwrite(dom);
if numel(s)>46
  out = s(40:end);
  out = regexprep(out,'<text>|</text>','');
  out = regexprep(out,'(\n( )*)*\n','\n');
  out = regexprep([char(10)  out],'\n','\n% ');
  out = [out char(10), '%' char(10)]; % save cell end
else
  out = '';
end

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

p = strfind(in,'-');
if isempty(p)
  form(end+1).param = in;
else
  lineBreak = [0 regexp(in,'\n')];
  lastLineBreak = lineBreak(lineBreak<p(1));
  lastLineBreak = lastLineBreak(end);
 
  if numel(p)>1 % allow markup -- instead of -
    a = diff(p);
    if numel(a) > 1
      n = (a(1:end-1) > 1 & a(2:end) >1);
      n = find(n,1,'first');
      if isempty(n)
        if a(end) > 1
          nextLineBreak = p(end-1);
        else
          nextLineBreak = numel(in);
        end
      else
        nextLineBreak = lineBreak(lineBreak<p(n+1));
      end
    else
      nextLineBreak = lineBreak(lineBreak<p(2));
    end
    
  else
    nextLineBreak = numel(in);
  end
  nextLineBreak = nextLineBreak(end);
  
  form(end+1).param = strtrim(in(lastLineBreak+1:p(1)-1));
  
  comment = in(p(1)+1:nextLineBreak);
  comment = regexprep(comment,'--','-');
  
  s = regexprep(['%% ' char(10) comment],'\n[ ]*','\n% ');
  fname = fullfile(options.outputDir, [options.file.sourceInfo.docName '_tmp.m']);
  save(fname,s);
  
  poptions.evalCode = false;
  poptions.format = 'xml';
  poptions.outputDir = options.outputDir;
  poptions.figureSnapMethod='print';
  poptions.useNewFigure = true;
  poptions.imageFormat= 'png';
  
  oldDir = cd; cd(options.outputDir); 
  
  o = publish(fname,poptions);
  dom = xmlread(o);
  
  cd(oldDir);
  
  recycle('off');
  delete(o);
  delete(fname);
  
  %   xml = xmlwrite(dom)
  %   t = regexp(xml,'(?<=<text>).*?(?=</text>)','match');
  text = dom.getElementsByTagName('text').item(0);
  
  form(end).comment = text; %strtrim(regexprep(in(p(1)+1:nextLineBreak),'\n',''));
  
  if strcmp(in(nextLineBreak+1:end),in)
    disp(in)
    view(options.file)
    error ('to much -')
  end
  form = format(in(nextLineBreak+1:end),options,form);
end





