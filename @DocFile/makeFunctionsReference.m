function func_cat_name = makeFunctionsReference(docFiles,mainFile,varargin)
% generates the function reference overview pages
%
% Input
% docFiles - a list of @DocFile
% mainFile - the @DocFile of a name of a DocFile where to start, this DocFile should have a *.toc
%
% Options
% outputDir   -  the folder where to put all function--pages
%
% See also
% DocFile/publish DocFile/makeHelpToc


[options,mainFile] = parseArguments(varargin,docFiles,mainFile);
options.func_cat_name = 'funcref_cat.html';
options.func_alph_name = 'funcref_alph.html';
options.docFiles = docFiles;

% by category
[dom,document] = domCreateDocument('mscript');
makeFuncCategory(dom,document,mainFile,options);

insertRefSwitch(dom,'>> Alphabetical List',options.func_alph_name);

xslt(dom,getPublishStyle('html'),fullfile(options.outputDir,options.func_cat_name));

% alphabetic
[dom,document] = domCreateDocument('mscript');
makeFuncAlphabetic(dom,document,options);

insertRefSwitch(dom,'>> Categorial List',options.func_cat_name);
  
xslt(dom,getPublishStyle('html'),fullfile(options.outputDir ,options.func_alph_name));

  

files = getPublishGeneral();
for k=1:numel(files)
  copyfile(files{k},options.outputDir);
end

end

function [options,mainFile] = parseArguments(options,docFiles,mainFile)

if ~isstruct(options)
  if mod(numel(options),2)
    error('forgotten argument of option');
  end
  options = cell2struct(options(2:2:end)',options(1:2:end)');
end

if ~isfield(options,'outputDir')
  options.outputDir = cd;
end

if ~isa(mainFile,'DocFile')
  mainFile = getFilesByName(docFiles,mainFile);
end

end

function insertRefSwitch(dom,linkename,linkpage)

text = dom.getElementsByTagName('text').item(0);
div = dom.createElement('div');
div.setAttribute('class','funcrefpage');
text.insertBefore(div,text.getFirstChild);
domAddChild(dom,div,'a',linkename,{'href',linkpage});

end

function count = makeFuncAlphabetic(dom,parentNode,options)

docFiles = options.docFiles;

% sort the files
info = [docFiles.sourceInfo];
names = {info.name};
[snames,ndx] = sort(lower(names));
docFiles = docFiles(ndx);


alph = upper(cellfun(@(x) x(1), snames));
sects = [0 find(diff(double(alph))) numel(alph)];

cell = domAddChild(dom,parentNode,'cell');
title = domAddChild(dom,cell,'steptitle','Functions - Alphabetical List');
cell.setAttribute('style','overview');
title.setAttribute('style','document');

text = domAddChild(dom,cell,'text');

kn = alph(sects(1:end-1)+1);
alphabet = 'A':'Z';
malph = ismember(alphabet,alph);
id = cumsum(malph);

for l=1:numel(alphabet)
  
  if malph(l)
    sp = domAddChild(dom,text,'span',' ');
    a = domAddChild(dom,sp,'a',alphabet(l),{'href',['#' num2str(id(l))]});
  else
    domAddChild(dom,text,'span',[' ' alphabet(l)]);
  end
end


% sects
for k=1:numel(sects)-1
  cell = domAddChild(dom,parentNode,'cell');
  
  domAddChild(dom,cell,'count',num2str(k));
  domAddChild(dom,cell,'section','0');
  domAddChild(dom,cell,'steptitle',alph(sects(k)+1));
  
  text = domAddChild(dom,cell,'text');
  
  table = domAddChild(dom,text,'table',[],{'width','95%'});
  for l=sects(k)+1:sects(k+1)
    if isFunction(docFiles(l))
            
      tr = domAddChild(dom,table,'tr');
      td = domAddChild(dom,table,'td',[],{'width','250px'});
      a = domAddChild(dom,td,'a',[],{'href',[docFiles(l).sourceInfo.docName '.html']});
      domAddChild(dom,a,'tt', docFiles(l).sourceInfo.name);
      
      docName = docFiles(l).sourceInfo.docName;
      p = strfind(docName,'.');
      if ~isempty(p)
        domAddChild(dom,td,'span',['   ('  docName(1:p-1) ')']);
      end
            
    end
  end
  
end

end

function count = makeFuncCategory(dom,parentNode,file,options,count)
% apply recursive by read from tocfile
if nargin < 5, count=0; end

count = createMscriptCell(dom,parentNode,file,options,count);


icount = count;
if hasTocFile(file)
  for tocEntry = getFilesByToc(file,options.docFiles)
    count = makeFuncCategory(dom,parentNode,tocEntry,options,count);
    icount = [icount count];
  end
end


% nasty: hack the links
if numel(icount)>1
  cellCount = dom.getElementsByTagName('count');
  
  for k = 0:cellCount.getLength-1
    currentCellCount = cellCount.item(k);
    currentCell = currentCellCount.getParentNode;
    currentPos = str2num(currentCellCount.getTextContent);
    % find the topic page
    if currentPos == icount(1)
      links = currentCell.getElementsByTagName('a');
      
      % rewrite the first links for navigation
      for l=0:numel(icount)-2
        links.item(l).setAttribute('href',['#' num2str(icount(l+1))]);
      end
    end
    
    % childs
    for l=1:numel(icount)
      if currentPos == icount(l)+1
        currentCell.getElementsByTagName('section').item(0).setTextContent(num2str(icount(1)-1));
      end
    end
  end  
end

end

%  


function count = createMscriptCell(dom,parentNode,file,options,count)

count = count+1;
% docFile
cell = domAddChild(dom,parentNode,'cell');

domAddChild(dom,cell,'count',num2str(count));
domAddChild(dom,cell,'section',num2str(count-1));

str = read(file);
titles = regexp(str,'(?<=^%%|\n%%)(.*?)(?=(\n|$))','match');

if isempty(titles)
  titles{1} = 'no title';
end
title = domAddChild(dom,cell,'steptitle',titles{1});
text = domAddChild(dom,cell,'text');
% docFile


if count == 1
  cell.setAttribute('style','overview');
  title.setAttribute('style','document');
end


% include a html navigation table
if hasTocFile(file)
  
  tocEntry = getFilesByToc(file,options.docFiles);
  a = getTableOfContent(tocEntry,'short',true);
  node = dom.importNode(a.getDocumentElement,true);
  text.appendChild(node);
  
end

% find function files and add them as table
if strfind(file.sourceInfo.name,'_index')
  nam = file.sourceInfo.name(1:end-6);
  
  info = [options.docFiles.sourceInfo];
  match = ~cellfun('isempty',regexp({info.path}, ['(' regexptranslate('escape',filesep) '|@)' nam '$']));
  %   file
  table = domAddChild(dom,text,'table',[],{'width','95%'});
  for tocFiles = options.docFiles(match)
     
    tr = domAddChild(dom,table,'tr');
    td = domAddChild(dom,table,'td',[],{'width','250px'});
    a = domAddChild(dom,td,'a',[],{'href',[tocFiles.sourceInfo.docName '.html']});
    domAddChild(dom,a,'tt', tocFiles.sourceInfo.name);
   
  end
end

domAddChild(dom,cell,'cellOutputTarget',num2str(count));


end

