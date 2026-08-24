function helpStr = generateScript( docFile,options)
% returns a processed string for function file
%
% Input
%  file - current file
%
% Output
%  helpString - a string for publishing
%
% Remarks !TODO
% 'input', 'output', 'example', 'see also', 'description', 'syntax', 'view code'
%
% See also
% DocFile/getFormatedDoc DocFile/publish

keyWords = {'Description','Syntax','Input','Output','Options','Flags',...
  'Class Properties','Dependent Class Properties','Derived Classes',...
  'See also','Example', 'References','Authors'};

% split function file docu into sections according to the above key words
sections = doc2sections(docFile, keyWords,options);

% first section is title
helpStr = addContentByTopic('',sections,sections(1).title,@inline);
if isempty(helpStr), helpStr = addTitle('',sections(1).title); end

% include a marker that will be replaced by a link to view the code
helpStr = [helpStr newline '%% View Code' newline '% '];

% add description
helpStr = addContentByTopic(helpStr,sections,'Description',@inline);

% add syntax
[helpStr, isNew ]= addContentByTopic(helpStr,sections,'Syntax',@preSyntax);
[isFunc, Syntax] = isFunction(docFile);

% if no explicit syntax was given we may generate one automatically
if ~isNew && isFunc
  helpStr = [addTitle(helpStr,'Syntax') newline preSyntax(Syntax,sections)];
end

% add all other sections 
for top = keyWords(3:9)
  helpStr = addContentByTopic(helpStr,sections,top{1},@preVarComment);
end
  
helpStr = addContentByTopic(helpStr,sections,'Remarks',@inline);
helpStr = addContentByTopic(helpStr,sections,'Example',@preExample);
helpStr = addContentByTopic(helpStr,sections,'Authors',@inline);
helpStr = addContentByTopic(helpStr,sections,'References',@inline);
helpStr = addContentByTopic(helpStr,sections,'See also',@seeAlso);

function in = preSyntax(in,varargin)

  % if it is correctly indented then MATLAB 2012a just does the right thing
  if ~any(strfind(in,'%   '))
    dispPerm(['  wrong syntax identation! <a href="matlab: edit(''' ...
      docFile.sourceFile ''')">',docFile.sourceInfo.docName '</a>']);
  end
end

function out = preVarComment(str,varargin)
% translate variable name / comment pairs into a table
%
% The description of a variable may be wrapped over several lines
%
%   Length   - fixed length of the scale bar, if not given a nice round
%              length close to 10% of the map width is used
%   Location - corner of the map the bar is drawn in:
%              'sw' (default), 'se', 'nw', 'ne'
%
% Such a follow up line continues the description of the preceding variable
% and must not become a table row of its own. It is recognized by starting
% behind the '-' of that variable, or by containing no '-' at all - the
% second criterion is needed since a wrapped line may well contain a dash,
% as the first one above does.

dom = domCreateDocument('html');

table = domAddChild(dom,dom.getDocumentElement,'table',[],...
  {'class','funcref','width','100%','cellpadding','4','cellspacing','0'});

% remove the comment character starting each line - in contrast to removing
% every '%' this keeps percent signs inside the text alive
lines = regexp(regexprep(str,'^[ \t]*%','','lineanchors'),newline,'split');

% the number of leading blanks and the position of the '-' separating
% variable name and description, 0 if the line does not start with a name
indent = cellfun(@(l) numel(regexp(l,'^[ \t]*','match','once')),lines);
dashPos = cellfun(@(l) numel(regexp(l,'^[ \t]*[^-\s][^-]*(?=-)','match','once')),lines);
dashPos(dashPos > 0) = dashPos(dashPos > 0) + 1;

% a variable name may start behind the '-' of the preceding variable if it
% belongs to a nested list, e.g. to the fields of an output struct - those
% come in groups sharing the indentation and the column of the '-'
isNested = [dashPos(1:end-1) > 0 & dashPos(1:end-1) == dashPos(2:end) & ...
  indent(1:end-1) == indent(2:end), false];

% split the section into rows of variable name and description
varComment = cell(0,2);
isText = false(0,1); % row without any variable name - spans the full width
descCol = 0;         % the '-' of the description we are allowed to continue

for k = 1:numel(lines)

  line = strtrim(lines{k});

  if isempty(line) % a blank line ends the description

    descCol = 0;

  elseif dashPos(k) > 0 && (~descCol || indent(k) < descCol || isNested(k))

    % a new variable
    varComment(end+1,:) = {lines{k}(1:dashPos(k)-1), ...
      lines{k}(dashPos(k)+1:end)}; %#ok<AGROW>
    isText(end+1) = false; %#ok<AGROW>
    descCol = dashPos(k);

  elseif descCol && line(1) == '-'

    % an alternative description for the same variable - leave the name
    % column empty so that it stays aligned with the row above
    varComment(end+1,:) = {'',line(2:end)}; %#ok<AGROW>
    isText(end+1) = false; %#ok<AGROW>

  elseif descCol

    % a wrapped line continues the description of the preceding variable
    varComment{end,2} = [strtrim(varComment{end,2}) ' ' line];

  else

    % plain text within the section - give it the full width
    varComment(end+1,:) = {'',line}; %#ok<AGROW>
    isText(end+1) = true; %#ok<AGROW>
    descCol = inf; % it may be continued, but any variable ends it

  end
end

for k = 1:size(varComment,1)

  try
    row = domAddChild(dom,table,'tr');

    if isText(k)
      td = domAddChild(dom,row,'td',[],{'colspan','2'});
    else
      td = domAddChild(dom,row,'td',[],{'width','100px'});
      domAddChild(dom,td,'tt',makeLinks(varComment{k,1}));

      td = domAddChild(dom,row,'td');
    end
    domAddChild(dom,td,'tt',makeLinks(varComment{k,2}));
  catch
    dispPerm(['  Error preparing <a href="matlab: edit(''' ...
      docFile.sourceFile ''')">',docFile.sourceInfo.docName '</a>']);
    varComment(k,:) %#ok<NOPRT>
  end
end

out = dom2char(dom);
out = regexprep([newline newline out newline],'\n','\n% ');

end



end

function sections = doc2sections(docFile,keyWords,options)

% extract help string from function or class file
%helpStr = helpfunc(file.sourceFile);
%process = helpUtils.helpProcess(1, 1, {docFile.sourceFile});
process = matlab.internal.help.helpProcess(1, 1, {docFile.sourceFile});
process.getHelpText;
helpStr = process.helpStr;

if isempty(helpStr)
  %process = helpUtils.helpProcess(0,1, {docFile.sourceFile});
  process = matlab.internal.help.helpProcess(0, 1, {docFile.sourceFile});
  process.getHelpText;
  helpStr = process.helpStr;  
end

% insert title
docName = docFile.sourceInfo.docName;
%Title = regexprep(docName,'(\w*)\.(\w*)', ...
%  ['$2' newline '  \(method of <$1_index.html $1>\)' newline ' % ']);
% Title = regexprep(docName,'(\w*)\.(\w*)', ['$2' newline '% ']);

helpStr = ['%% ' docName newline '%%' newline '% ' strtrim(helpStr)];

% add a '%' to each line
helpStr = regexprep(helpStr,'(?<=^|\n) ','%');

% add a '%' in front of each keyword to turn it into a section
for i = 1:numel(keyWords)
  helpStr = regexprep(helpStr,['\n\%\s*' keyWords{i}],['\n\%\% ' keyWords{i}]);
end

helpStr = globalReplacements(helpStr,options);

% this is an internal matlab function to generate a stuct for each section
sections = m2struct(helpStr);

% polish the output
for k=1:numel(sections)
  sections(k).title = strtrim(sections(k).title);
  
  % joint text
  text = cellfun(@(x) ['% ' x newline],sections(k).text,'Uniformoutput',false);
  sections(k).text = [text{:}];  
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

function content = getContentByTopic(sections,topic)

%topic = regexptranslate('escape',topic);
% regexpi({sections.title},topic,'start');

topicFound = false;
content = '';
for k=1:numel(sections)
  if strncmpi(sections(k).title,topic,numel(topic))
    content = [' ' sections(k).text];
    topicFound = true;
  elseif topicFound && isempty(sections(k).title)
     content = [content newline '% ' newline  sections(k).text]; %#ok<AGROW>
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

function out = seeAlso(in,varargin)
out = regexprep(inline(in),'/','.');

% Replace each entry from the back, so the earlier positions stay valid.
% A loop rather than a dynamic ${seeAlsoLink($0)} expression in regexprep:
% those are evaluated in a context that cannot see a local function, and
% fail with "Undefined function 'seeAlsoLink'".
[tok,tokStart,tokEnd] = regexp(out,'[\w\.]+','match','start','end');
for k = numel(tok):-1:1
  out = [out(1:tokStart(k)-1) seeAlsoLink(tok{k}) out(tokEnd(k)+1:end)];
end

out = regexprep(out,'\n\n','\n%');
% ensure we have exactly one white space after %
out = regexprep(out, '^[ \t]*%[ \t]+', '% ', 'lineanchors');
end

function out = seeAlsoLink(name)
% the link a single See also entry should become
%
% A class living in an @Name folder publishes as Name.Name.html while
% anything else publishes as basename.html, so emitting Name.html for every
% entry alike left every class named in a See also pointing nowhere - 221
% dead links across the published help, 71 distinct classes.

out = ['<' name '.html ' name '>'];

if contains(name,'.'), return; end

file = which(name);

% Nothing of that name in sight. It may still be a documentation page,
% which is not on the MATLAB path, so link it and let the link check
% decide.
if isempty(file), return; end

% MATLAB's own, not ours: unique, ndgrid, colormap and the colour map
% names all appear in See also blocks and none of them has a page here, so
% linking them only produces a dead link. Leave the name as plain text.
if ~contains(file,'mtex')
  out = name;
  return
end

% Anything inside an @Class folder publishes under that class. Naming a
% method on its own - Euler, deformationTensor, calcDistortion - is common
% in See also and used to link to name.html, which is never where the page
% is: it is Class.name.html, and Class.Class.html for the classdef itself.
parts = regexp(fileparts(file),filesep,'split');
cls = parts(startsWith(parts,'@'));

if ~isempty(cls)
  cls = cls{end}(2:end);
  out = ['<' cls '.' name '.html ' name '>'];
end

end


function out = preExample(in,varargin)

% remove first new line
if in(1)==newline, in(1) = []; end

% remove leading empty lines
out = regexprep(in, '^(?:[ \t]*%[ \t]*(?:\r?\n|$))+', '');

% remove trailing empty lines
out = regexprep(out, '(?:\r?\n[ \t]*%[ \t]*(?:\r?\n|$))+$', '');

out = regexprep(out, '^[ \t]*%[ \t]*$', '%  %%', 'lineanchors');

%out = strrep(in,'%   ','');
out = regexprep(out,'^\s*%\s*','', 'lineanchors');
%out = regexprep(in, '^[ \t]*%[ \t]*', '', 'lineanchors');

% an example section is code and is therefore executed while publishing, which
% must not happen for openExample: it copies a MATLAB example into a working
% folder and cds there. Those lines are not ours - a class method without its
% own help comment inherits MATLAB's built-in documentation (S1FunHandle.numel
% gets the one of numel, SO3TangentVector.unique the one of unique) and that
% documentation refers to its examples this way. Commenting them out keeps the
% reference visible without running it.
out = regexprep(out,'^[ \t]*openExample\(.*$','% $0','lineanchors','dotexceptnewline');

out = [newline out];
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

function out = makeLinks(in)
out = strtrim(regexprep(in,'<([^\ ]+)\ ([^>]+)>','<a href="$1">$2</a>'));
%out = strtrim(in);
end

