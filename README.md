## Gouda newstyle script.

This is a static html generator from markdown.
`chmod 755 gouda.pl`
In folder with .md files, call like this : ./gouda.pl


Dependencies:

* pandoc 

* markdown

* perl

* used perlmodules:
		use Modern::Perl;
		use autodie qw/:all/;
		use File::Slurp;
		use List::Compare;

Usage: make 3 or more .md files in a folder

Every file must start with a first line like so: % First line
All other important things the gouda.pl script will ask for, if you need it.

It generates style.css, toc.conf (table of content)

- Added mobile navigation menu with toc support.
- replaced the pandoc <!DOCTYPE> declaration for html5 with perl oneliners in script gouda.pl

