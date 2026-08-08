function out = needsPublish(files,options)
% which of the files would publish actually rebuild?
%
% Exactly the condition <DocFile.publish.html publish> applies per file: a
% page is rebuilt when its source is newer than the published html, when
% |options.force| is set, or when its doc name is listed in
% |options.forceDoc|. Split out so that a build can be announced before it
% starts - a full run takes hours, and the number of pages it is about to
% touch is the one number that tells whether the options were meant that way.
%
% Syntax
%   out = needsPublish(docFiles,options)
%   n = nnz(needsPublish(docFiles,options))
%
% Input
%  files            - a list of @DocFiles
%  options.outDir   - where the html pages are written to
%  options.force    - rebuild everything
%  options.forceDoc - cell array of doc names to rebuild in any case
%
% Output
%  out - logical, one entry per file
%
% See also
% DocFile/publish

out = true(size(files));

if isfield(options,'force') && options.force, return; end
if ~isfield(options,'forceDoc'), options.forceDoc = {}; end

info = [files.sourceInfo];

for k = 1:numel(files)

  htmlTarget = fullfile(options.outDir,[info(k).docName '.html']);

  out(k) = fileIsNewer(files(k).sourceFile,htmlTarget) || ...
    any(strcmp(info(k).docName,options.forceDoc));

end
