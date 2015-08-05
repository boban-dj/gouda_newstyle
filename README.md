## Gouda newstyle script.

This is a static html generator from markdown.
`chmod 755 gouda.pl`
In folder with .md files, call like this : ./gouda.pl


Dependencies:

* pandoc 

* markdown

* perl (install with perlbrew the version you want)

* used perlmodules:

		Modern::Perl;
		IPC::System::Simple;
		File::Slurp;
		List::Compare;


To install those Perl modules:

either use a tool like cpanm, or use your OS’s package management tools.
For Example, on a Debian-based distribution, you can apt-get install those prereqs
(they are `libmodern-perl-perl` `libfile-slurp-unicode-perl` `liblist-compare-perl` `libipc-system-simple-perl`)

You’ll also need `Pandoc`. Instructions for installing `Pandoc` are on its website.
For Debian-based GNU/Linux distributions, it’s: `sudo apt-get install pandoc`

To install Gouda itself, just save the `gouda.pl` file to somewhere in your `$PATH` 
(such as `~/bin` or `/usr/local/bin`) and make sure it’s executable (chmod +x gouda.pl), or run from folder.

* Usage: make 3 or more .md files in a folder

* Every file must start with a first line like so: % First line

* Also make index.md file, first 3 lines:

`% Home`<br>
`% author_name`<br>
`% 2015-07-14`<br>
		

All other important things the gouda.pl script will ask for, if you need it.

It generates style.css, toc.conf (table of content)

***UPDATED***
- Added mobile navigation menu with toc support.
- replaced the pandoc <!DOCTYPE> declaration for html5 with perl oneliners in script gouda.pl
