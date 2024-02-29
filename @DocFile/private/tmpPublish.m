function text = tmpPublish(text,tmpName)
% intermediat publish for reformating text to html


if nargin < 2
  tmpName = fullfile(tempdir, [sprintf('%.10d',fix(rand(1)*10^9))  '_tmp.m']);
elseif isdir(tmpName);
  tmpName = fullfile(tmpName, [sprintf('%.10d',fix(rand(1)*10^9))  '_tmp.m']);
end

pname = fileparts(tmpName);
save(tmpName,text);

poptions.evalCode = false;
poptions.format =  'xml';
poptions.outputDir = pname;
poptions.stylesheet = getPublishStyle('xml');
poptions.figureSnapMethod='print';
poptions.useNewFigure = true;
poptions.imageFormat= 'png';

oldDir = cd; cd(tempdir);

o = publish(tmpName,poptions);
% edit(tmpName)
% edit (o)
dom = xmlread(o);

cd(oldDir);

state= recycle;
recycle('off');
delete(o);
delete(tmpName);
recycle(state);

%   xml = xmlwrite(dom)
%   t = regexp(xml,'(?<=<text>).*?(?=</text>)','match');
text = dom.getElementsByTagName('text').item(0);
%text = dom.getDocumentElement;
