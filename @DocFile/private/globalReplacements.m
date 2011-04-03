function outstr = globalReplacements(instr,outputDir)


% instr = regexp(instr,'@(\w*)(?@numel(regexp(which(''$1''),''$1''))>1)','[[$1_index.html,$1]]');

if nargin < 2
  outputDir = tempdir;
end

% instr
% instr = regexprep( instr,'@(\w*)','[[$1_index.html,$1]]');
outstr = makeClassLinks(instr);
outstr = makeTable(outstr,outputDir);
outstr = makeBox(outstr,outputDir);


function outstr = makeClassLinks(instr)


[start stop] = regexp(instr,'@(\w*)');

for k=numel(start):-1:1
  fhandle = instr(start(k)+1:stop(k));
  if numel(regexp(which(fhandle),fhandle))>1
    instr =  [instr(1:start(k)-1) '[[' fhandle '_index.html,' fhandle ']]' instr(stop(k)+1:end)];
  else
    %     foo = which(fhandle);
    %     if ~isempty(foo)
    %
    %       %    instr =  [instr(1:start(k)) '[[' fhandle '.html,' fhandle ']]' instr(stop(k)+1:end)];
    %     end
  end
end
% instr
outstr = instr;

function outstr = makeTable(instr,outputDir)
lineBreak = regexp(instr,'\n');


[dom,doc] = domCreateDocument('html');
table = domAddChild(dom,doc,'table',[],{'class','usertable'});


tableMarker = regexp(instr,'\|\|');
oldRowBreak = [];
while ~isempty(tableMarker)
  beforeLineBreak = max(lineBreak(lineBreak<tableMarker(1)));
  afterLineBreak = min(lineBreak(lineBreak>tableMarker(1)));
  
  
  if isempty(oldRowBreak)
    oldRowBreak = beforeLineBreak;
  end
  
  intend = tableMarker(1)-beforeLineBreak-2;
  
  isCommentLine = any(strfind(instr(beforeLineBreak:tableMarker(1)),'%'));
  
  if isCommentLine
    markerInLine = beforeLineBreak < tableMarker & tableMarker < afterLineBreak;
    row = tableMarker(markerInLine);
    
    if numel(row) > 1
      tr = domAddChild(dom,table,'tr');
      for col=1:numel(row)-1
        text = strtrim(instr(row(col)+2:row(col+1)-1));
        text = tmpPublish(  ['%% ' char(10) '% ' text],outputDir);
        
        td = domAddChild(dom,tr,'td');
        newNode = dom.importNode(text,true);
        td.appendChild(newNode);
      end
    end
    
    tableMarker(markerInLine) = [];
    
    if ~isempty(tableMarker)
      newRowBreak = max(lineBreak(tableMarker(1) > lineBreak));
    else
      newRowBreak = afterLineBreak+1;
    end
    
    if newRowBreak  > afterLineBreak || isempty(tableMarker)
      newTable = dom2char(dom);
      imark =  ['%' repmat(' ' ,1,intend)];
      newTable = regexprep([imark char(10) newTable char(10) ],'\n',['\n' imark]);
      
      instr =  [instr(1:oldRowBreak)  newTable instr(afterLineBreak:end)];
      
      oldRowBreak = [];
      
      tableMarker = regexp(instr,'\|\|');
      lineBreak = regexp(instr,'\n');
      
      [dom,doc] = domCreateDocument('html');
      table = domAddChild(dom,doc,'table',[],{'class','usertable'});
    end
  else
    tableMarker(1) = [];
  end
  
end









% while ~isempty(tableMarker) %%&& k < numel(tableMarker)
%   beforeLineBreak = max(lineBreak(tableMarker(1) > lineBreak));
%   intend = tableMarker(1)-beforeLineBreak-1;
%   
%   if isempty(oldRowBreak)
%     oldRowBreak = beforeLineBreak;
%   end
%   
%   afterLineBreak = min(lineBreak(tableMarker(1) < lineBreak));
%   
%   
%   row = tableMarker(marksInLine);
%   
%   
%   
%   
%   tableMarker(marksInLine) = [];
%   
%   
% end

outstr = instr;



function outstr = makeBox(instr,outputDir)

boxBegin = '(?<=(\n|\n%)[ ]*)#(\w+)';
boxEnd = '(.*?)(?=(\n%[ ]*#|\n[ ]*(?!%)|%%|$))';

[boxFirstMark,boxLastMark] = regexp(instr,[boxBegin boxEnd]);

for k=numel(boxFirstMark):-1:1
  [boxText,intend] = subText(instr,boxFirstMark(k),boxLastMark(k),false);
  
  lineBreak = regexp(boxText,'\n');
  
  firstLineBreak = min(lineBreak);
  
  title = boxText(2:firstLineBreak);
  text = regexprep(['% ' boxText(firstLineBreak+1:end)],'\n','\n% ');
  
  text = tmpPublish(['%% ' char(10) text],outputDir);
  
  [dom,doc] = domCreateDocument('html');
  div = domAddChild(dom,doc,'div',[],{'class','note'});
  domAddChild(dom,div,'b',title);
  node = dom.importNode(text,true);
  div.appendChild(node);
  
  text = dom2char(dom);
  
  imark =  ['%' repmat(' ' ,1,intend-1)];
  
  box = regexprep([imark char(10) text char(10) ],'\n',['\n' imark]);
  
  lineBreak = regexp(instr,'\n');
  lastLineBreak = min(lineBreak(boxLastMark(k)+1<lineBreak));
  
  instr = [instr(1:boxFirstMark(k)-1)  char(10) box instr(lastLineBreak:end)];
end

outstr = instr;




