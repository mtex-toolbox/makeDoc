function [html_out,success] = publish( docFiles, options)
% publishes the docFiles
%
% Syntax
%   publish(docFiles, options)
%
% Input
%  docFiles - a list of @DocFiles
%  options.outDir  -
%  options.tmpDir  -
%  options.force      -
%  options.forceDoc   - cell array of doc names to republish regardless of
%                     timestamps, in addition to whatever force selects
%  options.publishSettings - struct like <matlab:doc('publish') publish>
%  options.xmlDom
%  options.LaTex   - 'Matlab', 'mathJax'
%  options.logFile - path to a persistent log file recording which file is
%                     being processed and any errors (default:
%                     <outDir>/publish_log.txt). Written to disk
%                     immediately so the log survives a MATLAB crash.
%  options.pauseFile - path to a file that suspends the run while it exists
%                     (default: <outDir>/publish_pause). Create it from
%                     anywhere - a shell, a second MATLAB, a file browser -
%                     and publishing halts after the file it is working on;
%                     delete it and the run continues where it left off.
%
% See also
% DocFile/makeHelpToc makeToolboxXML

if isempty(dir(options.tmpDir)), mkdir(options.tmpDir); end
if isempty(dir(options.outDir)), mkdir(options.outDir); end
options = setDefault(options,'imageDir',options.outDir);
options = setDefault(options,'force',false);
options = setDefault(options,'forceDoc',{});
options = setDefault(options,'logFile',fullfile(options.outDir,'publish_log.txt'));
options = setDefault(options,'pauseFile',fullfile(options.outDir,'publish_pause'));

% the figures have to stay visible while publishing
%
% There used to be a showFigures option switching DefaultFigureVisible off for
% the length of a build, on the assumption that print does not need a figure on
% screen. print does not - but publish never gets that far: captureFigures
% (toolbox/matlab/codetools/+internal/+matlab/+publish/captureFigures.m) drops
% every figure whose Visible is 'off' from the list it compares before and
% after each code chunk, so nothing is ever handed to print and the pages come
% out without a single image. Hiding the figures of a running build is not
% possible from here - it needs a MATLAB that has no display to begin with
% (-noFigureWindows, or a virtual X server).

logFile = options.logFile;
pauseFile = options.pauseFile;
nErrors = 0;
writeLog(logFile,sprintf('==== publish run started: %d file(s) ====',numel(docFiles)));

% a run takes hours - say how it can be halted without losing it
dispPerm(['  pause the run with:  touch ' pauseFile]);

%% prepare files to publish

% which files have to be prepared - collected before the loop so that the
% progress display can name the total, not only the file at hand
toPrepare = false(size(docFiles));
for k = 1:length(docFiles)
  target = fullfile(options.tmpDir,docFiles(k).targetTemporary);
  toPrepare(k) = fileIsNewer(docFiles(k).sourceFile,target) || options.force || ...
    any(strcmp(docFiles(k).sourceInfo.docName,options.forceDoc));
end
nPrepare = nnz(toPrepare); iPrepare = 0;

for k = reshape(find(toPrepare),1,[])

  waitWhilePaused(pauseFile,logFile);

  target = fullfile(options.tmpDir,docFiles(k).targetTemporary);

  iPrepare = iPrepare + 1;
  disptmp(sprintf('preparing %s (%d/%d)\n', ...
    docFiles(k).sourceInfo.docName,iPrepare,nPrepare));
  writeLog(logFile,sprintf('START prepare  %s  (%d/%d)  (%s)', ...
    docFiles(k).sourceInfo.docName,iPrepare,nPrepare,docFiles(k).sourceFile));

  try
    if isFunction(docFiles(k)) || isClass(docFiles(k))
      text = generateScript(docFiles(k),options);
    else
      text = read(docFiles(k).sourceFile);

      % extract author
      %
      % A long author line wraps onto continuation lines, so the block runs
      % on over every following '% ...' line and ends at the empty comment
      % line that closes it (or at the next cell, or at code). Matching only
      % up to the first line break cut such an author in half and left the
      % rest of it in the source, where it became the introduction paragraph
      % of the page - and hence its description in the search index.
      [startIndex,endIndex] = regexp(text,'% Author: .*?\n(%[ \t]+\S.*?\n)*');
      author = text(startIndex+10:endIndex);
      docFiles(k).sourceInfo.author = strtrim(regexprep(author,'\n%[ \t]+',' '));
      text(startIndex:endIndex) = [];

      % globally replace formulas, tables, etc.
      text = globalReplacements(text,options);
    end

  catch err
    %disptmp(newline);
    system(['touch ' docFiles(k).sourceFile]);
    dispPerm(['  Error preparing <a href="matlab: edit(''' ...
      docFiles(k).sourceFile ''')">',docFiles(k).sourceInfo.docName '</a>']);
    disp(err.message);
    disp(' ');
    writeLog(logFile,sprintf('ERROR prepare  %s  (%s)\n%s', ...
      docFiles(k).sourceInfo.docName,docFiles(k).sourceFile, ...
      getReport(err,'extended','hyperlinks','off')));
    nErrors = nErrors + 1;
    continue
  end

  fid = fopen(target,'w');
  if fid > 0
    fwrite(fid,text);
    fclose(fid);
  end

  writeLog(logFile,sprintf('OK prepare  %s',docFiles(k).sourceInfo.docName));

  disptmp('');
end

% finished script generation
dispPerm(' ');

copy(DocFile(getPublishGeneral),options.outDir);


%% publish files

% set up publish settings
pubSettings = options.publishSettings;
pubSettings = setDefault(pubSettings,'format','html');
pubSettings = setDefault(pubSettings,'figureSnapMethod','print');
pubSettings = setDefault(pubSettings,'useNewFigure',true);
pubSettings = setDefault(pubSettings,'evalCode',true);
pubSettings = setDefault(pubSettings,'imageFormat','png');
pubSettings = setDefault(pubSettings,'stylesheet',getPublishStyle('html'));
pubSettings.catchError = false;
pubSettings.outputDir = options.outDir;

% change directory
oldDir = cd; cd(options.tmpDir);

% remember settings
settings = getappdata(0,'mtex');

% which pages are actually rebuilt - the same condition publish used to test
% inside the loop, evaluated up front so every message can say how far the
% run has come. Determined after the preparation phase, since a file that
% failed to prepare gets touched and thereby joins the list.
toPublish = needsPublish(docFiles,options);
nPublish = nnz(toPublish); iPublish = 0;

for docFile = docFiles(toPublish)

  waitWhilePaused(pauseFile,logFile);

  % reapply settings
  setappdata(0,'mtex',settings);

  % publishing runs from tmpDir and hands publish() a bare script name, so the
  % current directory has to be tmpDir for every single file - not just when
  % the loop is entered. The code of a published page may well change it:
  % openExample copies its example into a working folder and cds there. One
  % such page used to take the whole rest of the run with it, every following
  % file failing with 'Unable to find script_....m'.
  cd(options.tmpDir);

  % final html name with script_xxx_xxx
  htmlTarget = fullfile(options.outDir,[docFile.sourceInfo.docName '.html']);

  iPublish = iPublish + 1;
  disptmp(sprintf('publishing: %s (%d/%d)', ...
    docFile.sourceInfo.docName,iPublish,nPublish))
  writeLog(logFile,sprintf('START publish  %s  (%d/%d)  (%s)', ...
    docFile.sourceInfo.docName,iPublish,nPublish,docFile.sourceFile));

  % update xml file
  stylePath = fileparts(pubSettings.stylesheet);

  try
          
    evalin('base','clear variables'); close all;
    evalin('base','format short');

    % reset the frame state, not only the convention: a page may have made
    % another frame the session default (specimenFrame.rolling.makeDefault)
    % or mutated a registered frame's convention (plotx2north) - resetting
    % only the convention would corrupt the registered frame for every
    % following page
    evalin('base','referenceFrame.reset')
    
    rng(2,"twister"); % ensure we always have the same random numbers
    
    % update xml file
    if isfield(options,'xml')      
      str = strrep(docFile.sourceFile,mtex_path,'');
      options.xml.toolbox.pageSource.Text = strrep(str,'../examples/','');
      options.xml.toolbox.htmlTarget = [docFile.sourceInfo.docName '.html'];

      % the author is a property of the page, so it has to be written for
      % every one of them, empty ones included: options survives the loop,
      % so leaving the field untouched for a page without an author gave it
      % the author of the last page that had one - a handful of '% Author:'
      % lines in ../examples ended up under every example published after
      % them
      options.xml.toolbox.author.Text = docFile.sourceInfo.author;
      struct2xml(options.xml,fullfile(stylePath,'toolbox.xml'));      
    end
    
    html_out = publish(docFile.targetTemporary, pubSettings);
            
    movefile(html_out,htmlTarget);
      
    [~,targetName] = fileparts(html_out);
    
    if 1
      % remove overview png
      pngFile = fullfile(options.outDir,[targetName '.png']);
      if exist(pngFile,'file'), delete(pngFile); end      
      
      % crop all images
      %
      % -strip together with excluding the date and time chunks keeps
      % ImageMagick from stamping a fresh timestamp into every file, which
      % would make even an unchanged figure differ byte-wise from the stored
      % one on every run
      pngTarget = fullfile(options.outDir,[targetName '*.png']);
      if ~isempty(dir(pngTarget))
        unix(['mogrify -trim -strip -define png:exclude-chunk=date,time ' pngTarget]);
      end

      % move image files to new directory
      %
      % the new image always replaces the stored one - deciding whether a
      % re-render is a real change is left to the web repository, see
      % tools/revert-unchanged-images.py there
      attache = dir(fullfile(options.outDir,[targetName '*.*']));
      for n=1:numel(attache)
        newFile = fullfile(options.outDir,attache(n).name);
        oldFile = fullfile(options.imageDir,regexprep(attache(n).name,targetName,docFile.sourceInfo.docName));

        movefile(newFile,oldFile,'f');
      end
    end

    writeLog(logFile,sprintf('OK publish  %s',docFile.sourceInfo.docName));

  catch e

    success = false;

    % remove
    delete([options.outDir filesep 'script_*'])
    %disptmp('');
    system(['touch ' docFile.sourceFile]);
    dispPerm(['  Error publishing <a href="matlab: edit(''' ...
      docFile.sourceFile ''')">',docFile.sourceInfo.docName '</a>']);

    f = find(strncmp(docFile.targetTemporary,{e.stack.name},length(docFile.targetTemporary)-2));
    errLoc = '';
    if ~isempty(f)
      stack = e.stack(f);
      dispPerm(['   (in file <a href="matlab: opentoline(''' ...
        docFile.sourceFile ''',' num2str(stack.line(1)) ',0)">' docFile.sourceInfo.name '</a>)']);
      fprintf('   %s\n' ,regexprep(e.message,'[\n\r]',''));
      errLoc = sprintf(' at line %d',stack.line(1));
    end

    writeLog(logFile,sprintf('ERROR publish  %s  (%s)%s\n%s', ...
      docFile.sourceInfo.docName,docFile.sourceFile,errLoc, ...
      getReport(e,'extended','hyperlinks','off')));
    nErrors = nErrors + 1;
    
  end
  
end

if isfield(options,'xmlDom'), mytoolbox.removeChild(node); end
cd(oldDir);

writeLog(logFile,sprintf('==== publish run finished: %d error(s) ====',nErrors));

end

function opt = setDefault(opt,field,value)

if ~isfield(opt,field), opt.(field) = value; end

end

function waitWhilePaused(pauseFile,logFile)
% halt between two files as long as the pause file exists
%
% A full run takes hours and there is no way to suspend it from the command
% window: MATLAB executes typed commands and hyperlink clicks only when it
% is idle, and Ctrl+C aborts the run rather than pausing it. The one signal
% that does reach a busy loop is the file system - create the pause file
% (touch it from a shell, from a second MATLAB, from a file browser) and the
% run stops after the file it is currently working on, keeping the whole
% MATLAB state; delete the file and it carries on where it left off.
%
% dir() rather than exist() on purpose: exist consults the cached path,
% which a file created behind MATLAB's back does not update.

if isempty(dir(pauseFile)), return; end

dispPerm(['  paused - delete ' pauseFile ' to continue']);
writeLog(logFile,sprintf('PAUSED  (waiting for %s to be removed)',pauseFile));

while ~isempty(dir(pauseFile)), pause(1); end

dispPerm('  continuing');
writeLog(logFile,'RESUMED');

end

function writeLog(logFile,msg)
% append a timestamped message to the publish log
%
% opens, writes and closes the file for every call (rather than keeping a
% handle open) so entries are flushed to disk immediately - this way the
% log survives even if MATLAB crashes mid-run, instead of only living in
% the command window

fid = fopen(logFile,'a');
if fid > 0
  fprintf(fid,'[%s] %s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'),msg);
  fclose(fid);
end

end