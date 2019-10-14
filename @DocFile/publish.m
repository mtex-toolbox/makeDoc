function [html_out,success] = publish( docFiles, varargin )
% publishes the docFiles
%
% Input
%  docFiles - a list of @DocFiles
%
% Options
%  outputDir  -
%  evalCode   -
%  force      -
%  publishSettings - struct like <matlab:doc('publish') publish>
%
% See also
% DocFile/makeFunctionsReference DocFile/makeHelpToc makeToolboxXML

options = parseArguments(varargin);

tempDir = options.tempDir;
if isempty(dir(tempDir)), mkdir(tempDir); end

outputDir = options.publishSettings.outputDir;
if isempty(dir(outputDir)), mkdir(outputDir); end

%% prepare files to publish
for docFile = docFiles
  
  target = fullfile(tempDir,docFile.targetTemporary);
    
  if fileIsNewer(docFile.sourceFile,target) || options.force % ||
    
    disptmp(sprintf('preparing %s\n',docFile.sourceInfo.docName));
          
    try
      if isFunction(docFile) || isClass(docFile)
        text = getFormatedRef(docFile,'outputDir',outputDir);
      else
        text = getFormatedDoc(docFile,docFiles);
      end
    catch %#ok<CTCH>
      %disptmp(newline);
      dispPerm(['  Error preparing <a href="matlab: edit(''' ...
        docFile.sourceFile ''')">',docFile.sourceInfo.docName '</a>']);
      lasterr
      disp(' ');
      continue
    end
    
    fid = fopen(target,'w');
    if fid > 0
      fwrite(fid,text);
      fclose(fid);
    end
    
    disptmp('');
  end
end

% finished script generation
dispPerm(' ');

copy(DocFile(getPublishGeneral),options.publishSettings.outputDir);

options.publishSettings.catchError = false;

% change directory
oldDir = cd; cd(tempDir);

% 
settings = getappdata(0,'mtex');

%% publish files
for docFile = docFiles
  
  % reapply settings
  setappdata(0,'mtex',settings);
  
  % final html name with script_xxx_xxx
  htmlTarget = fullfile(outputDir,[docFile.sourceInfo.docName '.html']);

  % nothing to do
  if ~fileIsNewer(docFile.sourceFile,htmlTarget) && ~options.force, continue; end
    
  disptmp([ 'publishing: ' docFile.sourceInfo.docName])
  try
          
    evalin('base','clear variables'); close all;
    
    html_out = publish(docFile.targetTemporary,options.publishSettings);
            
    movefile(html_out,htmlTarget);
      
    [~,targetName] = fileparts(html_out);
    
    if 1
      % crop all images
      pngTarget = fullfile(outputDir,targetName,'*.png');
      if ~isempty(dir(pngTarget))
        unix(['mogrify -trim ' pngTarget]);
      end
    
      attache = dir(fullfile(outputDir,[targetName '*.*']));
      for n=1:numel(attache)
        newName = regexprep(attache(n).name,targetName,docFile.sourceInfo.docName);
        movefile(fullfile(outputDir,attache(n).name),fullfile(outputDir,newName),'f');
      end
    end    
    
  catch e
    
    success = false;
    
    % remove 
    delete([outputDir filesep 'script_*']) 
    %disptmp('');
    dispPerm(['  Error publishing <a href="matlab: edit(''' ...
      docFile.sourceFile ''')">',docFile.sourceInfo.docName '</a>']);
            
    f = find(strncmp(docFile.targetTemporary,{e.stack.name},length(docFile.targetTemporary)-2));
    if ~isempty(f)
      stack = e.stack(f);
      dispPerm(['   (in file <a href="matlab: opentoline(''' ...
        docFile.sourceFile ''',' num2str(stack.line(1)) ',0)">' docFile.sourceInfo.name '</a>)']);
      fprintf('   %s\n' ,regexprep(e.message,'[\n\r]',''));
    end
    
  end

end

cd(oldDir);

end

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


if ~isfield(options,'format')
  options.format = 'html';
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


if ~isfield(options,'publishSettings')
  options.publishSettings = struct;
end

switch options.format 
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

end


