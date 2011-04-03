function [text,intend] = subText(text,start,stop,skip)
% extracts subtext from to

if nargin < 4
  skip = false;
end


lineBreak = regexp(text,'\n');

firstLineBreak = max(lineBreak(lineBreak < start));
lastLineBreak = min(lineBreak(stop < lineBreak));


if isempty(firstLineBreak)
  text = [char(10) text];
  firstLineBreak = 1;
  start = start+1;
  stop = stop+1;
end

if isempty(lastLineBreak)
  text = [text char(10)];
  lastLineBreak = numel(text);
end

if skip
  beforeText = text(1:min(start,numel(text)));
  
  lastLineBreak = max(regexp(beforeText,'\n'));
  if isempty(lastLineBreak)
    lastLineBreak = 0;
  end
  beforeText = beforeText(lastLineBreak+1:end);
  mark = min(regexp(beforeText,'\w'));
  
  if ~isempty(mark)
    intend = mark(1)+3;
  else
    intend = 0;
  end
  text = text(start:stop);
else
  intend =  start-firstLineBreak-1;
  text = text(firstLineBreak:lastLineBreak);
end


lineBreak = regexp(text,'\n');

for l = numel(lineBreak):-1:1
  currentLineBreak = lineBreak(l);
  nextLineBreak = min(lineBreak(currentLineBreak< lineBreak));
  
  if ~isempty(nextLineBreak)
    if nextLineBreak-currentLineBreak < intend
      text(currentLineBreak+1:nextLineBreak-1) = [];
    else
      text(currentLineBreak+1:currentLineBreak+intend) = [];
    end
  end
end

if ~skip
  text = text(2:end);
end