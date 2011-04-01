function view(file,output)
% display the source of the DocFile


if nargin > 1
  
  list = {};
  link = {};
  files = file(1);
  for k=1:numel(file)
    docfile{k} = fullfile(output,[file(k).sourceInfo.docName '.html']);
    
    if exist(  docfile{k})
      list{end+1} = file(k).sourceInfo.name;
      link{end+1} = docfile{k};
      files(end+1) = file(k);
    end
  end
  files(1) = [];
  
  %   listdlg('ListString',docfile)
  wzrd = findall(0,'tag','docFileViewer');
  if isempty(wzrd)
    wzrd = figure('MenuBar','none',...
      'Resize','off',...
      'Name','DocFiles',... 'Resize','off',...
      'NumberTitle','off',...
      'tag','docFileViewer',...
      'Color',get(0,'defaultUicontrolBackgroundColor'),...
      'Position',[100 100 200 500]);
    
    wrzd_list = uicontrol('parent',wzrd,...
      'style','listbox',...
      'position',[0 0 200 500],...
      'backgroundcolor','white',...
      'fontsize',10,...
      'tag','docFileList');
  else
    wrzd_list = findall(wzrd,'tag','docFileList');
  end
  
  set(wrzd_list, ...
    'String',list,...
    'Callback',{@fileChanged,link},...
    'KeyPressFcn',{@keypressFnc,files},...
    'ButtonDownFcn',{@buttonDownFnc,files});
  
  
  set(wrzd_list,'Value',numel(link));
  web(link{numel(link)});
  figure(wzrd);
  
else
  edit(file.sourceFile);
end


function fileChanged(src,evt,link)

pos = get(src,'value');
web(link{pos});
figure(gcbf);

function keypressFnc(src,evt,files)

pos = get(src,'value');
switch evt.Key
  case 'return'
    source(files(pos))
end

function buttonDownFnc(src,evt,files)

pos = get(src,'value');
source(files(pos));


