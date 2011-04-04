function [html_out,success] = publish( docFiles, varargin )
% publishes the docFiles
%
%% Input
% docFiles - a list of @DocFiles
%
%% Options
% mainFile   - start for the toc,
% outputDir  -
% evalCode   -
% force      -
% viewoutput -
% format     - html / latex / xml ...
% publishSettings - struct like [[matlab:doc('publish'),publish]]
%
%% See also
% DocFile/makeFunctionsReference DocFile/makeHelpToc makeToolboxXML

options = parseArguments(varargin);

prepareFilesToPublish(docFiles,options);

switch options.format
  case 'tex'
    html_out = publishTexBook(docFiles,options);
    
  case 'html'    
    copy(DocFile(getPublishGeneral),options.publishSettings.outputDir);
    
    [html_out,success] = publishFiles(docFiles,options);
end



% viewOutput(html_out,options);


function options = parseArguments(options)

if ~isempty(options)
  if ~isstruct(options{1})
    if mod(numel(options),2)
      error('forgotten argument of option');
    end
    options = cell2struct(options(2:2:end)',options(1:2:end)');
  else
    options = options{1};
  end
end

if ~isfield(options,'force')
  options.force = false;
end

if ~isfield(options,'mainFile')
  options.mainFile = false;
end

if ~isfield(options,'format')
  options.format = 'html';
end

if ~isfield(options,'viewoutput')
  options.viewoutput = true;
end

if ~isfield(options,'force')
  options.viewoutput = false;
end

if ~isfield(options,'outputDir')
  options.outputDir = tempdir;
end

if ~isfield(options,'tempDir')
  options.tempDir = options.outputDir;
end


if ~isfield(options,'evalCode')
  options.evalCode = false;
end

if ~isfield(options,'documentClass')
  options.documentClass = 'article';
end



% if ~isfield(options,'publishSettings')

switch options.format
  case {'latex','tex'}
    format = 'xml';
    style = 'latex';
    imageFormat = 'epsc2';
  case {'html','jar','help'}
    format = 'html';
    style = 'html';
    imageFormat = 'png';
  case {'xml'}
    format = 'xml';
    imageFormat = 'png';
    style = 'html';
end

% end
options.publishSettings = struct;
options.publishSettings.useNewFigure = true;
if ~isfield(options.publishSettings,'format')
  options.publishSettings.format = format;
end

if ~isfield(options.publishSettings,'figureSnapMethod')
  options.publishSettings.figureSnapMethod = 'print';
end

if ~isfield(options.publishSettings,'outputDir')
  options.publishSettings.outputDir = options.outputDir;
end

if ~isfield(options.publishSettings,'useNewFigure')
  options.publishSettings.useNewFigure = true;
end

if ~isfield(options.publishSettings,'evalCode')
  options.publishSettings.evalCode = options.evalCode;
end

if ~isfield(options.publishSettings,'imageFormat')
  options.publishSettings.imageFormat = imageFormat;
end

if ~isfield(options.publishSettings,'stylesheet')
  options.publishSettings.stylesheet = getPublishStyle(style);
end

options = rmfield(options,{'outputDir','evalCode'});



function prepareFilesToPublish(docFiles,options)

tempDir = options.tempDir;
outputDir = options.publishSettings.outputDir;

if isempty(dir(tempDir))
  mkdir(tempDir);
end

if isempty(dir(outputDir))
  mkdir(outputDir);
end

n = numel(docFiles);
% progress(0,n,'preparing ')



for k = 1:n
  docFile = docFiles(k);
  fprintf('preparing %s\n',docFile.sourceInfo.docName);
  %   docFile
  %   docFile
  target = fullfile(tempDir,docFile.targetTemporary);
  targetTmp = fullfile(outputDir,[docFile.sourceInfo.docName '.html']);
  
  if is_newer(docFile.sourceFile,target) || options.force % ||
    %
    %    is_newer(docFile.sourceFile,targetTmp) || options.force
    %     if exist(target)
    %       delete(target)
    %     end
    
    if isFunction(docFile)
      text = getFormatedRef(docFile,'outputDir',outputDir);
    else
      text = getFormatedDoc(docFile,docFiles);
    end
    
    fid = fopen(target,'w');
    fwrite(fid,text);
    fclose(fid);
  end
  
  fprintf('%s',repmat(8,1,numel(docFile.sourceInfo.docName)+11));
end



function html_out = publishTexBook(docFiles,options)


% return


% if ~isempty(options.mainFile)
% mainDocFile = getFilesByName(docFiles,options.mainFile);
% if isempty(mainDocFile)
%   options.mainDocFile = docFiles(1);
% else
%   options.mainDocFile = mainDocFile;
% end
%   mainDocFile.targetFile = regexprep(mainDocFile.targetFile,'\.html','\.tex');
% else
%   error(['main file ''' varargin{k+1} ''' not found'])
% end

% struct(mainDocFile).targetFile

% options.publishSettings = publishSettings;


if ~hasTocFile(options.mainDocFile)
  options.documentclass = 'article';
end

dom = domCreateDocument(options.documentclass);
doc = dom.getDocumentElement;

makeTexSection(dom,doc,options.mainDocFile,docFiles,options);
% xmlwrite(dom)
xmlwrite('out.xml',dom);
stylesheet = getPublishStyle('latex');
html_out = xslt(dom,stylesheet,options.mainDocFile.targetFile);



function makeTexSection(dom,parentNode,file,docFiles,options)

node = publishXML(dom,parentNode,file,options);

% if hasTocFile(file)
%   for tocFiles = getFilesByToc(file,docFiles)
%     makeTexSection(dom,node,tocFiles,docFiles,options);
%   end
% end
if hasTocFile(file)
  for tocFiles = getFilesByToc(file,docFiles)
    makeTexSection(dom,node,tocFiles,docFiles,options);
  end
elseif strfind(file.sourceInfo.name,'_index')
  nam = file.sourceInfo.name(1:end-6);
  
  info = [docFiles.sourceInfo];
  match = ~cellfun('isempty',regexp({info.path}, [nam '$']));
  
  for tocFiles = docFiles(match)
    makeTexSection(dom,node,tocFiles,docFiles,options);
  end
end


function node = publishXML(dom,parentNode,file,options)


pOptions = options.publishSettings;

target = regexprep(file.targetTemporary,'\.m|\.tex|\.html','\.xml');


if is_newer(file.sourceFile,target)  || options.force
  if pOptions.evalCode
    oldDir = cd;
    cd(pOptions.outputDir);
  end
  
  target = publish(file.targetTemporary,pOptions);
  
  
  if pOptions.evalCode
    cd(oldDir)
  end
end
% target

domnode = xmlread(target);
if file.sourceInfo.isFunction
  node = domAddChild(dom,parentNode,'function');
else
  node = domAddChild(dom,parentNode,'section');
end
copynode = dom.importNode(domnode.getDocumentElement,true);
node.appendChild(copynode);


function [htmlTarget,success] = publishFiles(docFiles,options)

tempDir = options.tempDir;
outputDir = options.publishSettings.outputDir;
options.publishSettings.catchError = false;

oldDir = cd; cd(tempDir);
% cd

pub = {};
success = [];

for docFile = docFiles
  htmlTarget = fullfile(outputDir,[docFile.sourceInfo.docName '.html']);
  
  if options.viewoutput
    pub{end+1} = docFile;
    view([pub{:}],options,[success false]);
  end
  
  if is_newer(docFile.sourceFile,htmlTarget) || options.force
    
    
    try
      %       edit(docFile.targetTemporary)
      html_out = publish(docFile.targetTemporary,options.publishSettings);
      movefile(html_out,htmlTarget);
      
      [path,targetName]= fileparts(docFile.targetTemporary);
      attache = dir(fullfile(outputDir,[targetName '*.*']));
      
      for n=1:numel(attache)
        [p,file,ext] = fileparts(attache(n).name);
        if ~strcmp(ext,'.m')
          newName = regexprep(attache(n).name,targetName,docFile.sourceInfo.docName);
          movefile(fullfile(outputDir,attache(n).name),fullfile(outputDir,newName),'f');
        end
      end
      
      success(end+1) = true;
    catch e
      success(end+1) = false;
      
      disp(['Error occured in File: ' docFile.sourceFile ])
      f = strmatch(docFile.sourceInfo.name,{e.stack.name});
      if ~isempty(f)
        stack = e.stack(f);
        disp(['   (in file <a href="matlab: opentoline(''' ...
          docFile.sourceFile ''',' num2str(stack.line(1)) ',0)">' docFile.sourceInfo.name '</a>)']);
        fprintf('   %s\n' ,regexprep(e.message,'[\n\r]',''));
      else
        m = e.stack
        for k=1:max(numel(m)-6,1)
          disp(m(k).file)
        end
        %                 rethrow(e)
      end
    end
    
  else
    success(end+1) = true;
  end
  
  if options.viewoutput
    %       pub{end+1} = docFile;
    view([pub{:}],options,success);
  else
    disp( ['<a href="' htmlTarget '">' docFile.sourceInfo.docName '</a>']);
  end
end

cd(oldDir);


function viewOutput(html_out,options)

if options.viewoutput
  switch options.format
    case 'html'
      web(html_out)
    case {'tex','latex'}
      html_out = fullfile(regexprep(html_out,'file:///',''));
      [path] = fileparts(html_out);
      
      disp('running latex ...')
      [a,b] = system(['pdflatex -interaction=nonstopmode -output-directory=' path ' '  html_out]);
      %       disp('second run ...')
      %       [a,b] = system(['pdflatex -interaction=nonstopmode -output-directory=' path ' ' html_out]);
      %       disp('third run ...')
      %       [a,b] = system(['pdflatex -interaction=nonstopmode -output-directory=' path ' ' html_out]);
      %
      file = regexprep(html_out,'\.tex','\.pdf');
      open(file);
  end
end



function o = is_newer(f1,f2)
% is f2 newer than f1
d1 = dir(f1);
d2 = dir(f2);
if ~isempty(d1) && ~isempty(d2)
  o = (d1.datenum > d2.datenum);
else
  o = true;
end