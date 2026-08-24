function hash = toolchainHash()
% fingerprint the publisher itself
%
% <isStale.html isStale> decides that a page is up to date by comparing the
% hash of its *source* with the hash the page was built from. That misses
% every change to the publisher: a page whose source has not moved is
% considered current no matter what the code that renders it now does.
%
% This is not hypothetical. Three fixes to the link markup in
% <DocFile.generateScript.html generateScript> and
% <globalReplacements.html globalReplacements> - classes resolving to
% Class.Class.html, MATLAB's own names no longer linked, bare method names
% resolved to their class - changed nothing at all on two successive builds,
% because no source file had changed. They only reached the 2334 pages that
% needed them when something unrelated forced a rebuild.
%
% Mixing this fingerprint into every page's hash makes a change here
% invalidate the whole documentation, which is the honest answer: a
% publisher that renders differently produces different pages.
%
% It is the file contents rather than the git commit, so that an
% uncommitted change during development invalidates too - which is when it
% matters most.
%
% Output
%  hash - hex string, empty when the sources cannot be hashed
%
% See also
% isStale hashOf DocFile/publish

persistent cached

if ~isempty(cached), hash = cached; return; end

% the makeDoc root: this file is <root>/@DocFile/private/toolchainHash.m
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));

files = dir(fullfile(root,'**','*.m'));
files = fullfile({files.folder},{files.name});

% one sha1sum over the lot, then a hash of the hashes
parts = hashOf(files);
parts = parts(~cellfun('isempty',parts));

if isempty(parts)
  cached = '';
else
  tmp = [tempname '.txt'];
  fid = fopen(tmp,'w');
  fprintf(fid,'%s\n',parts{:});
  fclose(fid);
  h = hashOf({tmp});
  delete(tmp)
  cached = h{1};
end

hash = cached;

end
