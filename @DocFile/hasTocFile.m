function [hasToc, tocLocation] = hasTocFile(file)
% checks whether a Toc file is available

tocLocation = fullfile(file.sourceInfo.path,[file.sourceInfo.name  '.toc']);

hasToc = logical(exist(tocLocation,'file'));
if ~hasToc
  tocLocation = '';
end


