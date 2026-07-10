# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`makeDoc` (toolbox name `DocHelp`) is a MATLAB toolbox that generates the HTML
documentation for the MTEX toolbox (this directory lives at `mtex/makeDoc`,
alongside the rest of the MTEX source tree). It converts specially-formatted
`%` comment headers in `.m` files into MATLAB's `publish`-compatible scripts,
runs MATLAB's `publish`, and assembles the result plus a table-of-contents
into a MATLAB help toolbox (`helptoc.xml`, `help.jar`, `helpsearch` DB).

There is no non-MATLAB build system, no package manager, and no automated
test suite — everything here is `.m` code executed from within MATLAB.

## Running / building the docs

Everything is driven from MATLAB (not the shell). Typical workflow, taken
from `examples/BuildDocHelp.m`:

```matlab
DocHelpInstall               % one-time: adds makeDoc/, examples/, tools/ to the MATLAB path

makeToolboxXML                % writes resources/style/toolbox.xml (toolbox name/version/icon)

f = [getFiles(docHelpPath,'*.m') ...
     getFiles(fullfile(docHelpPath,'@DocFile'),'*.m') ...
     getFiles(fullfile(docHelpPath,'tools'),'*.m') ...
     getFiles(fullfile(docHelpPath,'help','docGuide'),'*.m',true)];
docFiles = DocFile(f);        % wrap source files as @DocFile objects

makeHelpToc(docFiles,'docGuide', 'FunctionMainFile','FunctionReference', ...
            'outputDir',outputDir);

publish(docFiles, 'mainFile','docGuide', 'format','html', ...
        'outputDir',outputDir, 'tempDir',tmpDir, 'force',true, 'evalCode',true);
```

- `docHelpPath` resolves to this directory's root (parent of `tools/`).
- `DocFile(path)` recursively collects `.m` files under `path` (skipping
  `private/` dirs); `DocFile({...})` wraps an explicit file list.
- `publish(docFiles, options)` (the `@DocFile/publish.m` method, not
  MATLAB's built-in `publish`) does the actual work per file: only
  re-publishes when the source is newer than the target (`fileIsNewer`) or
  `options.force` is set.
- Output artifacts (`help/html`, `help/tmp`, `help/helpsearch`, `help/help.jar`,
  `help/helptoc.xml`, `examples/html`, `examples/demos.xml`) are all
  generated/ignored (see `.hgignore`) — never hand-edit them.
- There is no `matlab -batch`/CI entry point in this repo; documentation is
  built interactively by running `examples/BuildDocHelp.m` inside MATLAB
  (typically from within the wider MTEX project, since `docFiles` is meant to
  cover MTEX's own `.m` files, not just this toolbox's).

## Architecture

### `@DocFile` — the core class

A MATLAB classdef-free (constructor-style, `class(struct,'DocFile')`) object
representing one source file to be documented. Key fields: `sourceFile`
(full path), `sourceInfo` (`docName`, `isFunction`, `Syntax`, `name`, `ext`,
`path`), `targetTemporary` (the sanitized temp filename used for
`publish`, since MATLAB can't publish filenames containing `.` — hence
`ClassName.methodName` becomes `script_ClassName__methodName.m`).

Method files (`@DocFile/*.m`) — think of these as the class's public API:

- `DocFile.m` — constructor; classifies each input as function/class file
  (`.m` under an `@ClassName` dir → `docName = 'ClassName.methodName'`) vs.
  a plain doc page.
- `publish.m` — the main pipeline (see below).
- `generateScript.m` — turns a function/class `.m` file's help comment into
  a `publish`-ready script by splitting it into sections keyed on words like
  `Description`, `Syntax`, `Input`, `Output`, `Options`, `Class Properties`,
  `See also`, `Example`, `References`, `Authors`, etc. (see the `keyWords`
  list at the top of the file), then reformatting each section
  (`preSyntax`, `preVarComment` → HTML table, `preExample`, `seeAlso` →
  cross-links).
- `isFunction.m` / `isClass.m` — sniff the source text (`function `,
  `classdef`) to decide how to treat a file.
- `makeHelpToc.m` — recursively builds `helptoc.xml` by walking `.toc` files
  (see `readTocFile.m`/`hasTocFile.m`) or, for `*_index.m` files, by
  matching sibling files in the same `@ClassName` directory.
- `deadlink.m` — scans generated HTML for `href="...html"` links that don't
  resolve to an existing output file (documentation link checker).
- `exclude.m` — filters a `DocFile` array by substring match on `sourceFile`.
- `copy.m` — copies underlying source files (non-`.m` assets) to a target dir.
- `private/` — internal helpers not part of the public method API:
  - `globalReplacements.m` — toolbox-wide text substitutions applied to
    every doc string: LaTeX passthrough vs. MathJax translation
    (`options.LaTex`), `@ClassName`/`@functionName` → cross-link HTML,
    custom `||...||...||` table markup → `<table>`, and `#boxname ... `
    marker syntax → `<div class="note">` boxes (both of the latter two work
    by recursively re-invoking MATLAB's `publish` on extracted snippets via
    `tmpPublish.m`).
  - `tmpPublish.m` — writes a snippet to a scratch `.m` file, runs MATLAB's
    `publish` in XML mode, parses out the `<text>` node — used to
    HTML-render small embedded pieces (table cells, box contents).
  - `dom2char.m`, `domAddChild.m`, `domCreateDocument.m` — thin wrappers
    around Java's `com.mathworks.xml.XMLUtils`/DOM API for building HTML/XML
    fragments programmatically.
  - `subText.m` — extracts a line-aligned substring range from `%`-commented
    text, stripping/normalizing comment-marker indentation.
  - `file2cell.m`, `fileIsNewer.m`, `read.m`, `save.m` — small file-system
    utilities (line-split a file, mtime comparison, slurp a file, write a
    script with `publish`-required blank-line framing).

### `tools/` — path/config helpers used across the toolbox

`docHelpPath.m` (root dir), `getFiles.m` (regex-pattern recursive file
listing, skips dot-dirs and `private/`), `getPublishGeneral.m` (CSS/JS/GIF
assets to copy alongside output), `getPublishStyle.m` (selects the XSL
stylesheet: `publish.xsl`, `tempxml.xsl`, `latex.xsl`/`mxdom2latex.xsl` from
`resources/style/`), `getToolboxXML.m`/`makeToolboxXML.m` (read/write
`resources/style/toolbox.xml`, the toolbox name/version/icon metadata
embedded into every published page's header/footer).

### `resources/` — static assets

`resources/general/` — CSS, JS, icons copied verbatim into every doc build.
`resources/style/` — XSL stylesheets driving MATLAB's `publish` XML→HTML/LaTeX
transform, plus the generated `toolbox.xml` (gitignored).

### `help/docGuide/` — this toolbox's own documentation source

Uses the same `%%`/`%` comment-based authoring convention it implements for
MTEX itself (see `help/docGuide/UsersGuide/WritingDocumentation.m`), with
`.toc` files controlling nesting (read by `readTocFile.m`).

### The `publish.m` pipeline (per `DocFile` array)

1. For each doc file whose source is newer than its temp target (or
   `force`): build the `publish`-ready script text — via
   `generateScript.m` for functions/classes, or via a direct
   read + author-line extraction + `globalReplacements.m` for plain doc
   pages — and write it to `options.tmpDir`.
2. Copy general assets (CSS/JS/icons) into `options.outDir`.
3. For each doc file whose source is newer than its HTML target (or
   `force`): reset MATLAB app state/plotting convention/RNG seed for
   reproducibility, optionally update `resources/style/toolbox.xml` with
   per-page source/author metadata, call MATLAB's built-in `publish` on the
   temp script, move the resulting HTML to `docName.html`, then
   diff-and-crop generated PNGs against previously published ones (pixel/FFT
   comparison) so unchanged figures aren't needlessly overwritten (keeps git
   diffs small across doc rebuilds).
4. Errors during either phase are caught per-file, logged with a
   `matlab:`-scheme clickable link to the offending source line, and the
   source file's mtime is `touch`ed so it's retried next run — the whole
   batch does not abort.

## Authoring conventions for documented `.m` files (what the code parses)

- Function/class doc comments are split on the keyword section headers
  listed in `generateScript.m`'s `keyWords` (`Description`, `Syntax`,
  `Input`, `Output`, `Options`, `Flags`, `Class Properties`,
  `Dependent Class Properties`, `Derived Classes`, `See also`, `Example`,
  `References`, `Authors`). `Input`/`Output`/etc. lines of the form
  `varname - comment` are rendered as a two-column table.
  `% Author: ...` lines are extracted (for plain doc pages) rather than
  rendered as body text.
- `@ClassName` / `@functionName` tokens in text are auto-linked when the
  target resolves via MATLAB's `which` and lives under `mtex`.
- `|| cell || cell || cell ||` on comment lines builds an HTML table.
- `#label ... ` (terminated by a blank line, `%%`, or EOF) builds a
  highlighted note box titled `label`.
- `$...$` / `$$...$$` are LaTeX math; rendered via MathJax only when
  `options.LaTex` is `'mathJax'`, otherwise passed through with
  MATLAB-unsupported macros (`\mathbb`, `\binom`, etc.) rewritten/stripped
  since MATLAB's own LaTeX renderer doesn't include `amsmath`.
- Directories named `@ClassName` are treated as MATLAB classdef folders;
  a `.m` file inside becomes `ClassName.methodName` in the docs.
