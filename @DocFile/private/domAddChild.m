function childNode = domAddChild(dom,parentNode,name,content,attributes)



childNode = dom.createElement(name);

if nargin > 3 && ~isempty(content)
  childNode.setTextContent(content);
end

if nargin > 4
  for k=1:2:numel(attributes)
    childNode.setAttribute(attributes{k},attributes{k+1});
  end
end

parentNode.appendChild(childNode);