function [out,hash] = isStale(files,targets,known,options)
% which files have to be rebuilt to bring their target up to date?
%
% The one predicate behind both loops of <DocFile.publish.html publish> - the
% preparation loop asks it for the generated scripts in the temporary
% directory, the publishing loop (through <DocFile.needsPublish.html
% needsPublish>) for the html pages. A file is stale when
%
% * its target does not exist,
% * |options.force| is set or its doc name is listed in |options.forceDoc|,
% * its content differs from the content the target was built from.
%
% The last point is a comparison of hashes, not of modification times. git
% gives a file the current time whenever it writes it, including when it
% writes back exactly the content that is already published - switching to
% another branch and back, rebasing, stashing, pulling - so a timestamp says
% much more often than not that a page changed when it did not, and a full
% build is hours.
%
% Files the manifest knows nothing about - and files that could not be hashed
% at all, see <hashOf.html hashOf> - fall back to the timestamp: on the first
% run after the manifest was introduced or deleted every page is unknown, and
% falling back keeps that run from republishing the whole documentation.
% publish fills the manifest in as it goes, also for the pages it finds up to
% date, so the fallback applies once.
%
% Input
%  files   - a list of @DocFiles
%  targets - cell array of the target paths, one per file
%  known   - containers.Map of the hashes published so far, see readHashes
%  options - .force, .forceDoc
%
% Output
%  out  - logical, one entry per file
%  hash - cell array of the current source hashes, one per file
%
% See also
% DocFile/needsPublish DocFile/publish hashOf

if ~isfield(options,'force'), options.force = false; end
if ~isfield(options,'forceDoc'), options.forceDoc = {}; end

out = true(size(files));

info = [files.sourceInfo];

% in one go, and for every file - publish records the hash of every page it
% leaves behind up to date, whether it rebuilt it or not
hash = hashOf({files.sourceFile});

% A page depends on the publisher as much as on its own source, so the two
% are fingerprinted together, see <toolchainHash.html toolchainHash>.
% Without this a change to the link markup or the stylesheet reaches only
% the pages that happen to be rebuilt for some unrelated reason. Editing
% makeDoc therefore invalidates the whole documentation, which is a long
% build and is meant to be.
tool = toolchainHash();
if ~isempty(tool)
  for k = 1:numel(hash)
    if ~isempty(hash{k}), hash{k} = [hash{k} '-' tool(1:8)]; end
  end
end

for k = 1:numel(files)

  if options.force || any(strcmp(info(k).docName,options.forceDoc)) || ...
      isempty(dir(targets{k}))
    continue
  end

  if isKey(known,info(k).docName) && ~isempty(hash{k})
    out(k) = ~strcmp(known(info(k).docName),hash{k});
  else
    out(k) = fileIsNewer(files(k).sourceFile,targets{k});
  end

end

end
