## Gouda newstyle script.

This is a static html generator from markdown.

Dependencies: pandoc, markdown, perl,
used perlmodules:
		use Modern::Perl;
		use autodie qw/:all/;
		use File::Slurp;
		use List::Compare;

Usage: make 3 or more .md files in a folder
Every file must start 1st line: % First line
All other important things the gouda.pl script will ask for.

It generates style.css, toc.conf (table of content)
Added mobile navigation menu with toc support.

