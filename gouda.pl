#!/usr/bin/env perl

# Gouda -- a particularly easy-to-use documentation processing tool.
#
# Copyright 2011, 2012, 2013, John M. Gabriele <jmg3000@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use Modern::Perl;
use autodie qw/:all/;
use File::Slurp;
use List::Compare;

my $VERSION = "2013-03-01";

######################################################################
say "========== Gouda version $VERSION ==========";

if (@ARGV) {
    say <<'EOT';
** No need to pass any args to this program. Just run it in
** a directory containing some docs. Exiting.
EOT
    exit;
}

if (! -d '/tmp') {
    say <<'EOT';
** Oof! Inexplicably, it looks like your OS doesn't have a /tmp
** directory, and this script needs to write some temporary files
** there. Hm. Rather unsettling, if you ask me. Exiting.
EOT
    exit;
}

if (! -e 'index.md') {
    say <<'EOT';
** Hm. There's no index.md file here. You've gotta have one of
** these, as it will serve as the main front page of your docs.
** Please create one and then run gouda again. Exiting.
EOT
    exit;
}

my @md_chapters_here = glob '*.md';
@md_chapters_here = grep { $_ !~ m/readme\.md/i } @md_chapters_here;
@md_chapters_here = grep { $_ !~ m/index\.md/ } @md_chapters_here;
@md_chapters_here = sort @md_chapters_here;

for (@md_chapters_here) {
    if ($_ !~ m/^[\w\.-]+$/) {
        say "** Please use filenames consisting of only letters,";
        say "** numbers, dashes, underscores, and dots. Gouda does";
        say "** not like the looks of:\n**     $_";
        say "** Exiting.";
        exit;
    }
}

if (@md_chapters_here < 2) {
    say <<'EOT';
** In addition to the index.md file, Gouda prefers to have at least
** two more files in order to produce something that looks nice.
** Please write some more docs then run gouda again. Exiting.
EOT
    exit;
}

if (! -e 'toc.conf') {
    say q{Didn't find a toc.conf file, so creating one...};
    create_new_toc_file();
}

my @toc_lines = read_file('toc.conf', {chomp => 1});
@toc_lines = grep {$_ !~ m/^\s*$/} @toc_lines;
for (@toc_lines) {
    s/\s+$//;
    s/^\s+//;
}

check_toc_file();

my $styles_css_content = <<'EOT';
/**
* Reset some basic elements
*/
body, h1, h2, h3, h4, h5, h6,
p, blockquote, pre, hr,
dl, dd, ol, ul, figure {
margin: 0;
padding: 0; }

/**
* Basic styling
*/
body {
font-family: "Lucida Console", Monaco, monospace, Verdana, Trebuchet, Georgia, Helvetica, Arial, sans-serif;
font-size: 16px;
line-height: 1.5;
font-weight: 300;
color: #111;
background-color: #fdfdfd;
-webkit-text-size-adjust: 100%; }

/**
* Set `margin-bottom` to maintain vertical rhythm
*/
h1, h2, h3, h4, h5, h6,
p, blockquote, pre,
ul, ol, dl, figure,
.highlight {
margin-bottom: 15px; }

/**
* Images
*/
img {
max-width: 100%;
vertical-align: middle; }

/**
* Figures
*/
figure > img {
display: block; }

figcaption {
font-size: 14px; }

/**
* Lists
*/
ul, ol {
margin-left: 30px; }

li > ul,
li > ol {
margin-bottom: 0; }

/**
* Headings
*/
h1, h2, h3, h4, h5, h6 {
font-weight: 300; }

/**
* Links
*/
a {
color: #2a7ae2;
text-decoration: none; }
a:visited {
color: #1756a9; }
a:hover {
color: #111;
text-decoration: underline; }

/**
* Blockquotes
*/
blockquote {
color: #828282;
border-left: 4px solid #e8e8e8;
padding-left: 15px;
font-size: 18px;
letter-spacing: -1px;
font-style: italic; }
blockquote > :last-child {
margin-bottom: 0; }

/**
* Code formatting
*/
pre,
code {
font-size: 15px;
border: 1px solid #e8e8e8;
border-radius: 3px;
background-color: #eef; }

code {
padding: 1px 5px; }

pre {
padding: 8px 12px;
overflow-x: scroll; }
pre > code {
border: 0;
padding-right: 0;
padding-left: 0; }



/**
* Wrapper
*/
.wrapper {
max-width: 80em;
margin-right: auto;
margin-left: auto;
padding-right: 30px;
padding-left: 30px; }
@media screen and (max-width: 800px) {
.wrapper {
max-width: 80em;
padding-right: 15px;
padding-left: 15px; } }
@media screen and (max-width: 800px) {
.wrapper .side {
visibility: hidden;
display: none;
max-width: 0px; } }
@media screen and (min-width: 800px) {
.wrapper .mobile-menu {
visibility: hidden;
display: none;
max-width: 0px; } }

/**
* Clearfix
*/
.wrapper:after, .footer-col-wrapper:after {
content: "";
display: table;
clear: both; }

/**
* Icons
*/
.icon > svg {
display: inline-block;
width: 16px;
height: 16px;
vertical-align: middle; }
.icon > svg path {
fill: #828282; }

.note {
display: inline-block;
background: rgba(0, 0, 0, 0.05);
padding: 20px;
border-radius: 3px;
border: 1px solid rgba(0, 0, 0, 0.2);
margin: 20px 0; }
/**
* Site header
*/
.site-header {
border-top: 5px solid #0E1FDC;
border-bottom: 1px solid #DC660E;
min-height: 56px;
position: relative;
}
.site-title {
font-size: 26px;
line-height: 56px;
letter-spacing: -1px;
margin-bottom: 0;
float: left; 
}
.site-title, .site-title:visited {
color: #424242;
}
.site-nav {
float: right;
line-height: 56px;
}
.site-nav .menu-icon {
display: none;
}
.site-nav .page-link {
color: #111;
line-height: 1.5;
}
.site-nav .page-link:not(:first-child) {
margin-left: 20px;
}

@media screen and (max-width: 800px) {
.site-nav {
position: absolute;
top: 9px;
right: 30px;
background-color: #fdfdfd;
border: 1px solid #e8e8e8;
border-radius: 5px;
text-align: right; 
}
.site-nav .menu-icon {
display: block;
float: right;
width: 36px;
height: 26px;
line-height: 0;
padding-top: 10px;
text-align: center; 
}
.site-nav .menu-icon > svg {
width: 18px;
height: 15px; 
}
.site-nav .menu-icon > svg path {
fill: #424242;
}
.site-nav .trigger {
clear: both;
display: none;
}
.site-nav:hover .trigger {
display: block;
padding-bottom: 5px;
}
.site-nav .page-link {
display: block;
padding: 5px 10px;
} 
}
@media screen and (max-width: 800px) {
.site-nav .side {
visibility: hidden;
display: none;
max-width: 0px; 
} 
}
@media screen and (min-width: 800px) {
.site-nav .mobile-menu {
visibility: hidden;
display: none;
max-width: 0px;
}
}
/** Site footer **/
.site-footer {
border-top: 1px solid #e8e8e8;
padding: 30px 0; }

.footer-heading {
font-size: 18px;
margin-bottom: 15px; }

.contact-list,
.social-media-list {
list-style: none;
margin-left: 0; }

.footer-col-wrapper {
font-size: 15px;
color: #828282;
margin-left: -15px; }

.footer-col {
float: left;
margin-bottom: 15px;
padding-left: 15px; }

.footer-col-1 {
width: -webkit-calc(35% - (30px / 2));
width: calc(35% - (30px / 2)); }

.footer-col-2 {
width: -webkit-calc(20% - (30px / 2));
width: calc(20% - (30px / 2)); }

.footer-col-3 {
width: -webkit-calc(45% - (30px / 2));
width: calc(45% - (30px / 2)); }

@media screen and (max-width: 800px) {
.footer-col-1,
.footer-col-2 {
width: -webkit-calc(50% - (30px / 2));
width: calc(50% - (30px / 2)); }

.footer-col-3 {
width: -webkit-calc(100% - (30px / 2));
width: calc(100% - (30px / 2)); } }
@media screen and (max-width: 800px) {
.side {
visibility: hidden;
display: none;
max-width: 0px; } }
@media screen and (min-width: 800px) {
.mobile-menu {
visibility: hidden;
display: none;
max-width: 0px; } }
@media screen and (max-width: 600px) {
.footer-col {
float: none;
width: -webkit-calc(100% - (30px / 2));
width: calc(100% - (30px / 2)); } }
@media screen and (max-width: 800px) {
.side {
visibility: hidden;
display: none;
max-width: 0px; } }
@media screen and (min-width: 800px) {
.mobile-menu {
visibility: hidden;
display: none;
max-width: 0px; } }
/**
* Page content
*/
.post {
width: 100%;
max-width: calc(100% - 260px);
float: right; }
@media screen and (max-width: 800px) {
.post {
max-width: calc(100% - 30px); } }
@media screen and (max-width: 800px) {
.post .side {
visibility: hidden;
display: none;
max-width: 0px; } }
@media screen and (min-width: 800px) {
.post .mobile-menu {
visibility: hidden;
display: none;
max-width: 0px; } }

.page-content {
padding: 30px 0; }

.page-heading {
font-size: 20px; }

.post-list {
margin-left: 0;
list-style: none; }
.post-list > li {
margin-bottom: 15px; }

.post-meta {
font-size: 14px;
color: #828282; }

.post-link {
display: block;
font-size: 14px; }

/**
* Posts
*/
.post-header {
margin-bottom: 30px; }

.post-title {
font-size: 42px;
letter-spacing: -1px;
line-height: 1; }
@media screen and (max-width: 800px) {
.post-title {
font-size: 36px; } }
@media screen and (max-width: 800px) {
.post-title .side {
visibility: hidden;
display: none;
max-width: 0px; } }
@media screen and (min-width: 800px) {
.post-title .mobile-menu {
visibility: hidden;
display: none;
max-width: 0px; } }

.post-content {
margin-bottom: 30px; }
.post-content h2 {
font-size: 32px; }
@media screen and (max-width: 800px) {
.post-content h2 {
font-size: 28px; } }
@media screen and (max-width: 800px) {
.post-content h2 .side {
visibility: hidden;
display: none;
max-width: 0px; } }
@media screen and (min-width: 800px) {
.post-content h2 .mobile-menu {
visibility: hidden;
display: none;
max-width: 0px; } }
.post-content h3 {
font-size: 26px; }
@media screen and (max-width: 800px) {
.post-content h3 {
font-size: 22px; } }
@media screen and (max-width: 800px) {
.post-content h3 .side {
visibility: hidden;
display: none;
max-width: 0px; } }
@media screen and (min-width: 800px) {
.post-content h3 .mobile-menu {
visibility: hidden;
display: none;
max-width: 0px; } }
.post-content h4 {
font-size: 20px; }
@media screen and (max-width: 800px) {
.post-content h4 {
font-size: 18px; } }
@media screen and (max-width: 800px) {
.post-content h4 .side {
visibility: hidden;
display: none;
max-width: 0px; } }
@media screen and (min-width: 800px) {
.post-content h4 .mobile-menu {
visibility: hidden;
display: none;
max-width: 0px; } }


nav.side {
float: left;
width: 100%;
max-width: 240px;
margin-right: 20px; }
nav.side img {
margin: 20px 0;
border-radius: 2px; }
nav.side h4 {
color: #222;
font-weight: bold;
line-height: 32px;
margin: 0;
margin-top: 10px; }
nav.side li {
list-style: none;
font-size: 13px; }
nav.side li nav {
display: none; }
nav.side a.active {
color: pink !important; }
nav.side li a.active ~ nav {
display: block; }
nav.side li a.active ~ nav li {
margin: 0;
padding: 0; }
nav.side li a.active ~ nav li:before {
content: '-';
display: inline-block;
padding: 0 5px; }


/*van gouda css*/

/* Pandoc automatically puts these in the page. */
#header .author {display: none;}
#header .date   {display: none;}
#header .title   {display: none;}

/* tweaks */

nav ul,nav ol {
  margin-left: 0px;
}

nav.side li {
list-style: none;
font-size: 16px; }



EOT

if (! -e 'styles.css') {
    say "No styles.css file here. Creating one...";
    create_styles_file();
}
else {
    say "Using the styles.css file here.";
}

# ----------------------------------------------------------------------
# Alright. Everything looks ok. Set up some other variables we'll need.

my %chapter_name_for;
for my $md_filename (@md_chapters_here) {
    $chapter_name_for{$md_filename} = get_doc_title_from($md_filename);
}

my $project_name = get_doc_title_from('index.md');
my $copyright_info = '&nbsp;';
if (-e '_copyright') {
    $copyright_info = read_file('_copyright');
}


my $before_body_html_tmpl = <<"EOT";

<!--START FIRST BLOCK-->

<header class="site-header">

<div class="wrapper">

<a class="site-title" href="index.html">$project_name</a>

<nav class="site-nav">

<a href="#" class="menu-icon">
<svg viewBox="0 0 18 15">
<path fill="#424242" d="M18,1.484c0,0.82-0.665,1.484-1.484,1.484H1.484C0.665,2.969,0,2.304,0,1.484l0,0C0,0.665,0.665,0,1.484,0 h15.031C17.335,0,18,0.665,18,1.484L18,1.484z"></path>
<path fill="#424242" d="M18,7.516C18,8.335,17.335,9,16.516,9H1.484C0.665,9,0,8.335,0,7.516l0,0c0-0.82,0.665-1.484,1.484-1.484 h15.031C17.335,6.031,18,6.696,18,7.516L18,7.516z"></path>
<path fill="#424242" d="M18,13.516C18,14.335,17.335,15,16.516,15H1.484C0.665,15,0,14.335,0,13.516l0,0 c0-0.82,0.665-1.484,1.484-1.484h15.031C17.335,12.031,18,12.696,18,13.516L18,13.516z"></path>
</svg>
</a>

<div class="trigger">
<!--main links top right-->
<a class="page-link" href="#">Home</a>
<a class="page-link" href="#">About</a>
<a class="page-link" href="#">Info</a>    


<div class="mobile-menu">
{{list of all mobilechapters}}
</div><!--mobile-menu-->

</div><!--trigger-->
</nav>
<!--end mobile-menu-->

</div><!--wrapper-->
</header>

<!--END FIRST BLOCK-->

	
<div class="page-content">
<div class="wrapper">

<nav class="side">

<!--main nav start -->

<!--<h4>Title block</h4>-->

{{list of all chapters}}

</nav>
<!--end main nav-->

<div id="content" class="post">


EOT



my $after_body_html_tmpl = <<"EOT";
</div> <!--class post-->
</div> <!--wrapper-->
</div> <!--page-content-->
<!--footer-->
<footer class="site-footer">
<div class="wrapper">
<h2 class="footer-heading">Footer title</h2>
<div class="footer-col-wrapper">
	<div class="footer-col  footer-col-1">footer content 1</div>
	<div class="footer-col  footer-col-2">footer content 2</div>
	<div class="footer-col  footer-col-3">footer content 3</div>
</div><!--footer-col-wrapper-->
</div><!--wrapper-->
</footer>
<!--end footer-->

EOT




# Any generated html files should be more recently modified
# than the toc.conf file. If the toc is more recent than any
# of the html files, we'll need to regenerate all html files.
my $toc_has_been_touched = 0;
my $toc_last_modified = (stat 'toc.conf')[9];
for ('index.md', @md_chapters_here) {
    my $ht = $_;
    $ht =~ s/\.md$/.html/;
    if ( -e $ht and $toc_last_modified > (stat $ht)[9] ) {
        $toc_has_been_touched = 1;
    }
}

if ($toc_has_been_touched) {
    say <<'EOT';
Your toc.conf has been modified recently. In honor of
the occasion, we'll go ahead and re-generate all html
files. Wheee!
EOT
}

# Go!
process_files();


######################################################################
######################################################################
sub create_new_toc_file {
    open my $toc_file, '>', 'toc.conf';
    for my $f (@md_chapters_here) {
        print {$toc_file} "$f\n";
    }
    close $toc_file;
}

sub check_toc_file {
    # First, check for dups in the toc. Could happen.
    my %count_of;
    $count_of{$_}++ for @toc_lines;
    my @dups = grep { $count_of{$_} > 1 } keys(%count_of);
    if (@dups) {
        say "** Found duplicate entries in your toc.conf:";
        say "**     @dups";
        say "** Please correct it and try again. Exiting.";
        exit;
    }

    my $problem = 0;
    my $lc = List::Compare->new(\@toc_lines, \@md_chapters_here);
    my @only_in_toc   = $lc->get_Lonly();
    my @only_in_found = $lc->get_Ronly();

    if (@only_in_toc) {
        say "** One or more docs are listed in the toc.conf but aren't here:";
        say "**     $_" for @only_in_toc;
        $problem = 1;
    }
    if (@only_in_found) {
        say "** One or more files are here but not listed in the toc.conf:";
        say "**     $_" for @only_in_found;
        $problem = 1;
    }
    if ($problem) {
        say "** Please straighten this out and try again. Exiting.";
        exit;
    }
}

sub create_styles_file {
    open my $styles_file, '>', 'styles.css';
    print {$styles_file} $styles_css_content;
    close $styles_file;
}

sub process_files {
    my $any_done_at_all = 0;
    for my $md_filename (@md_chapters_here) {
        my $html_filename = $md_filename;
        $html_filename =~ s/\.md$/.html/;
#bob: I changed the pandocs command: -/- pandoc -s -S --toc --mathjax --css=styles.css
        if ($toc_has_been_touched or
              ! -e $html_filename or
              (stat $md_filename)[9] > (stat $html_filename)[9]) {
            my $before_body_html = generate_before_body_html($md_filename);
            my $after_body_html  = generate_after_body_html($md_filename);
            my $pandoc_command = "pandoc -s -S --mathjax --css=styles.css " .
              "-B /tmp/before.html -A /tmp/after.html -o $html_filename $md_filename";
            say "Processing $md_filename --> $html_filename ...";
            system $pandoc_command;
            $any_done_at_all = 1;
        }
    }

    # And finally, process index.md as well (no toc for this one).
    if ($toc_has_been_touched or
          ! -e 'index.html' or
          (stat 'index.md')[9] > (stat 'index.html')[9]) {
        my $before_body_html = generate_before_body_html($project_name);
        my $after_body_html  = generate_after_body_html('index.md');
        my $pandoc_command = "pandoc -s -S --mathjax --css=styles.css " .
          "-B /tmp/before.html -A /tmp/after.html -o index.html index.md";
        say "Processing index.md --> index.html ...";
        system $pandoc_command;
        $any_done_at_all = 1;
    }

    if (! $any_done_at_all) {
        say "No files needed processing.";
    }
}

sub generate_before_body_html {
    my ($this_md_filename) = @_;

    my $chapter_list_html = "<ul>\n";

    for my $md_filename (@toc_lines) {
        my $html_filename = $md_filename;
        $html_filename =~ s/\.md$/.html/;
        my $chapter_name = $chapter_name_for{$md_filename};

        if ($md_filename eq $this_md_filename) {
            $chapter_list_html .= "<li><b>$chapter_name</b></li>\n";
        }
        else {
            $chapter_list_html .= '<li><a href="' . $html_filename .
              '">' . $chapter_name . "</a></li>\n";
        }
    }
    $chapter_list_html .= "</ul>\n";

    my $html = $before_body_html_tmpl;
    $html =~ s/\{\{list of all chapters\}\}/$chapter_list_html/;
    $html =~ s/\{\{list of all mobilechapters\}\}/$chapter_list_html/;
    open my $tmp_file, '>', '/tmp/before.html';
    print {$tmp_file} $html;
    close $tmp_file;
}



sub generate_after_body_html {
    my ($md_filename) = @_;
    my $html = $after_body_html_tmpl;
    $html =~ s/\{\{this page as text\}\}/$md_filename/;
    open my $tmp_file, '>', '/tmp/after.html';
    print {$tmp_file} $html;
    close $tmp_file;
}

sub get_doc_title_from {
    my ($doc_name) = @_;
    my @lines = read_file($doc_name, {chomp => 1});
    unless (@lines) {
        say "** $doc_name appears to be empty. Get writin'!.";
        exit;
    }
    my $title = $lines[0];
    if ($title !~ m/^% /) {
        say "** The first line of $doc_name should look something like";
        say "** this: \"% The Title\" (a percent sign, space, and the title).";
        say "** That is, it should constitute a Pandoc title block.";
        say "** Please fix. Exiting.";
        exit;
    }
    $title =~ s/^%\s+//;
    $title =~ s/\s+$//;
    return $title;
}


system( q( perl -0777 -pi -le 's/<!DOC[^>]+>/<!DOCTYPE html>/g' *.html ) );
system( q( perl -0777 -pi -le 's/<html xmlns[^>]+>//g' *.html ) );
system( q( perl -0777 -pi -le 's/<meta http-equiv="Content-Style-Type"[^>]+>//g' *.html ) );
say "** Cleaned pandoc <!DOCTYPE> Excellent!";













