function [html_out,success] = publish( docFiles, varargin )
% publishes the docFiles
%
% Input
%  docFiles - a list of @DocFiles
%
% Options
%  outDir  -
%  tmpDir  -
%  evalCode   -
%  force      -
%  publishSettings - struct like <matlab:doc('publish') publish>
%
% See also
% DocFile/makeHelpToc makeToolboxXML

outDir = get_option(varargin,'outDir','.');
tmpDir = get_option(varargin,'tmpDir',outDir);
if isempty(dir(tmpDir)), mkdir(tmpDir); end
if isempty(dir(outDir)), mkdir(outDir); end

% force publish
force = check_option(varargin,'force');


%% prepare files to publish
for docFile = docFiles
  
  target = fullfile(tmpDir,docFile.targetTemporary);
    
  if fileIsNewer(docFile.sourceFile,target) || force 
    
    disptmp(sprintf('preparing %s\n',docFile.sourceInfo.docName));
          
    try
      if isFunction(docFile) || isClass(docFile)
        text = getFormatedRef(docFile,'outputDir',outDir);
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

copy(DocFile(getPublishGeneral),outDir);


%% publish files

% set up publish settings
publishSettings.format = get_option(varargin,'format','html');
publishSettings.figureSnapMethod = get_option(varargin,'figureSnapMethod','print');
publishSettings.outputDir = outDir;
publishSettings.useNewFigure = get_option(varargin,'useNewFigure',true);
publishSettings.evalCode = get_option(varargin,'evalCode',true);
publishSettings.imageFormat = get_option(varargin,'imageFormat','png');
publishSettings.stylesheet = get_option(varargin,'stylesheet',getPublishStyle('html'));
publishSettings.catchError = false;
publishSettings = getClass(varargin,'struct',publishSettings);

% change directory
oldDir = cd; cd(tmpDir);

% remember settings
settings = getappdata(0,'mtex');

for docFile = docFiles
  
  % reapply settings
  setappdata(0,'mtex',settings);
  
  % final html name with script_xxx_xxx
  htmlTarget = fullfile(outDir,[docFile.sourceInfo.docName '.html']);

  % nothing to do
  if ~fileIsNewer(docFile.sourceFile,htmlTarget) && ~force, continue; end
    
  disptmp([ 'publishing: ' docFile.sourceInfo.docName])
  try
          
    evalin('base','clear variables'); close all;
    
    html_out = publish(docFile.targetTemporary, publishSettings);
            
    movefile(html_out,htmlTarget);
      
    [~,targetName] = fileparts(html_out);
    
    if 1
      % crop all images
      pngTarget = fullfile(outDir,targetName,'*.png');
      if ~isempty(dir(pngTarget))
        unix(['mogrify -trim ' pngTarget]);
      end
    
      attache = dir(fullfile(outDir,[targetName '*.*']));
      for n=1:numel(attache)
        newName = regexprep(attache(n).name,targetName,docFile.sourceInfo.docName);
        movefile(fullfile(outDir,attache(n).name),fullfile(outDir,newName),'f');
      end
    end    
    
  catch e
    
    success = false;
    
    % remove 
    delete([outDir filesep 'script_*']) 
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
