function outstr = globalReplacements(instr,options)


% instr = regexp(instr,'@(\w*)(?@numel(regexp(which(''$1''),''$1''))>1)','[[$1_index.html,$1]]');

%outstr = regexprep(instr,'@(\w*)','<$1.$1.html $1>' );
outstr = makeClassLinks(instr);
outstr = makeTable(outstr);
outstr = makeBox(outstr);

% translate latex to mathJax
%regexprep(outstr,'\$(.+?)\$','<html>x$1x</html>')
if strcmpi(options.LaTex,'mathJax')
  outstr = regexprep(outstr,'(?<!\$)\$(?!\$)(.+?)\$','\\($1\\)');
  outstr = regexprep(outstr,'\$\$(.+?)\$\$','\\[$1\\]');
end


function str = makeClassLinks(str)

[start, stop] = regexp(str,'@(\w*)');
 
for k=numel(start):-1:1
  fhandle = str(start(k)+1:stop(k));
  if numel(regexp(which(fhandle),fhandle))>1
    str =  [str(1:start(k)-1) '<' fhandle '.' fhandle '.html ' fhandle '>' str(stop(k)+1:end)];
  end
end

function outstr = makeTable(instr)
lineBreak = regexp(instr,'\n');

[dom,doc] = domCreateDocument('html');
table = domAddChild(dom,doc,'table',[],{'class','usertable'});

tableMarker = regexp(instr,' \|\|\s')+1;
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
        text = tmpPublish(  ['%% ' newline '% ' text],tempdir);
        
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
      newTable = regexprep([imark newline newTable newline ],'\n',['\n' imark]);
      
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



function outstr = makeBox(instr)

boxBegin = '(?<=(\n|\n%)[ ]*)#(\w+)';
boxEnd = '(.*?)(?=(\n%[ ]*#|\n[ ]*(?!%)|%%|$))';

[boxFirstMark,boxLastMark] = regexp(instr,[boxBegin boxEnd]);

for k=numel(boxFirstMark):-1:1
  [boxText,intend] = subText(instr,boxFirstMark(k),boxLastMark(k),false);
  
  lineBreak = regexp(boxText,'\n');
  
  firstLineBreak = min(lineBreak);
  
  title = boxText(2:firstLineBreak);
  text = regexprep(['% ' boxText(firstLineBreak+1:end)],'\n','\n% ');
  
  text = tmpPublish(['%% ' newline text],tempdir);
  
  [dom,doc] = domCreateDocument('html');
  div = domAddChild(dom,doc,'div',[],{'class','note'});
  domAddChild(dom,div,'b',title);
  node = dom.importNode(text,true);
  div.appendChild(node);
  
  text = dom2char(dom);
  
  imark =  ['%' repmat(' ' ,1,intend-1)];
  
  box = regexprep([imark newline text newline ],'\n',['\n' imark]);
  
  lineBreak = regexp(instr,'\n');
  lastLineBreak = min(lineBreak(boxLastMark(k)+1<lineBreak));
  
  instr = [instr(1:boxFirstMark(k)-1)  newline box instr(lastLineBreak:end)];
end

outstr = instr;




