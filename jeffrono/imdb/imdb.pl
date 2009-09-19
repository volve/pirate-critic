#!/usr/bin/perl

use LWP::UserAgent;
use LWP::Simple;
use LWP::Simple::Cookies ( autosave => 1, file => "$ENV{'HOME'}/lwp_cookies.dat" );

# loop through this

$seedmin = 10;
$minrating = 7;
$minvotes = 750;
$startyear = 2009;
$finalyear = 1945;

#build up the html file
open(TOP, "<header.txt");
while(<TOP>) { $htmlfile .= $_; }
close(TOP);

open(TOP, "<year.txt");
while(<TOP>) { $htmlheaderyear .= $_; }
close(TOP);


for ($i=$startyear; $i>$finalyear; $i--) {
	print "getting $i...";
	
	$imdburl = 'http://www.imdb.com/List?hi-rating=10&&votes=' . $minvotes . '&&lo-rating=' . $minrating . '&&year=' . $i . '&&vid=off&&tvm=off&&ep=off&&tv=off&&noakas=on';
	$movie_list = retrieveWebpage($imdburl);
	print "ok";
		
	#http://www.imdb.com/List?hi-rating=10&&votes=400&&lo-rating=7.6&&year=2009&&vid=off&&tvm=off&&ep=off&&tv=off&&noakas=on
	
	$htmlthisyear = '<table border="0" cellpadding="5" cellspacing="0">';
	
	$filmnum = 1;
	$numverified = 0;
	while ($movie_list =~ /I><A HREF=\"([^\"]+)\">([^\(]+)\(\d+\)<\/A><SMALL>\s*(\d+\.\d+)\/10 \((\d+) votes/gi) {
		$url = 'http://www.imdb.com' . $1;
		$title2 = $2;
		$rating = $3;
		$votes = $4;
			
		# get user rating, plot, genre list, and poster url
		$movie_page = retrieveWebpage($url);
		#title
		if ($movie_page =~ /<title>([^\(]+) \(/i) { $title = $1; }
		
		print "\n> $title";
		
		# get poster from imdb
		$posterurl = 'http://i.media-imdb.com/images/SFd0ed3aeda7d77e6d9a8404cc3cd63dc6/intl/en/title_noposter.gif';
		if ($movie_page =~ /title=\"$title\" src=\"([^\"]+)\"/ig) { $posterurl = $1; }
		# or from netflix
		else {
			$netflix = get('http://www.netflix.com/Search?ff2_submit.x=0&v1=' . $title . '&ff2_submit.y=0');
			if($netflix =~ /img src=\"(http:\/\/cdn-\d\.nflximg\.com\/us\/boxshots\/small\/\d+\.jpg)\"/) {
				$posterurl = $1;
				$posterurl =~ s/\/small\//\/large\//g;
				print " (NFP) ";
			} # if
		}	#else	
		

		#genre
		$genre = "";
		if($movie_page =~ m/Genre:<\/h5>\s*(.*?)<\/div>/i) {
			$genre = $1;
			$genre =~ s/<.*?>//g;			
			}
		if($genre =~ m/Short/g) { next; } #if it is a short, skip it
		
		#tagline
		$tagline = "";
		if($movie_page =~ m/Tagline:<\/h5>\s*([^<]+)/i) { $tagline = $1; }
		
		$plot = "";
		if($movie_page =~ m/Plot:<\/h5>\s*([^<]+)/i) { $plot = $1; }
		
		$comments = "";
		if($movie_page =~ m/User Comments:<\/h5>\s*([^<]+)/i) { $comments = $1; }
		
		if($filmnum % 2 == 0) {$bgcolor = "E8EDF5"; }
		else{$bgcolor = "FFFFFF"; }
			
		# query btjunkie
		$bttitle = $title;
		$bttitle =~ s/ /+/gi;
		$searchurl = 'http://btjunkie.org/search?q=%22' . $bttitle . '%22&c=0&t=1&o=52&s=1&l=1';
		$btj = retrieveWebpage($searchurl);
		
		$filmheader = '<tr bgcolor="' . $bgcolor . '"><td width="144" rowspan="2" valign="top"><img src="' . $posterurl . '" width="144" height="208"></td>
		<td width="425" valign="top"><a href="' . $url . '" class="stylemedium">' . $title . ' - (' . $rating . ' from '. $votes . ' votes)</a> - (<a href="' . $searchurl . '">search</a>)</td>
		<td width="275" valign="top"><span class="stylesmall"><b>' . $genre . '</b></span></td></tr><tr><td align="left" valign="top" bgcolor="' . $bgcolor . '"><ul>';
		
		if($btj =~ m/0 matches/gi) { next; }
		$num = 1;
		$numbad = 1;
		$verified = 0;
		# begin loop thru 5 bit torrent files
		while($btj =~ /ref=\"([^\"]+)\" class=\"BlckUnd/gi && $num < 6 && $numbad <11) {
			$btjurl = 'http://btjunkie.org' . $1;
			$btdata = retrieveWebpage($btjurl);
			$dlurl = "";
			$size = "";
			$filename = "";
			$dlurl = "";
			
			if($btdata =~ /href=\"(http:\/\/dl.btjunkie.org[^\"]+)/g) { $dlurl = $1; }
			if($btdata =~ />(\d+)MB</g) { $size = $1; }
			if($size < 600) { next; }
			if($btdata =~ /title=\"Torrent Download: ([^\"]+)\"/i) {$filename = $1; }
			if($filename =~ m/xxx/i) { next; }
			if($filename =~ m/CAM/) { next; }
			if($filename =~ m/ cam /i) { next; }
			$btdata =~ s/<[^>]*>/ /gi;
			$btdata =~ s/,//gi;
			$btdata =~ s/\s+/ /gi;
			$btdata =~ s/\(|\)//gi;

			$good = 0;
			$fake = 0;
			$password = 0;
			$lowquality = 0;
			$virus = 0;
			if($btdata =~ /Good(\d+) Fake(\d+) Password(\d+) Low Quality(\d+) Virus(\d+)/gi) {
				$good = $1;
				$fake = $2;
				$password = $3;
				$lowquality = $4;
				$virus = $5;
				} #if
			$seeder = 0;
			$leecher = 0;
			$testdata = $btdata;
			if($testdata =~ /seeders (\d+)/gi) { $seeder= $1; }
			$btdata = $testdata;
			if($btdata =~ /leechers (\d+)/gi) { $leecher= $1; }
			#print "$seeder, $leecher // ";
			if($num == 1 && $seeder>$seedmin && ($fake+$password+$lowquality+$virus)<1) { $htmlthisyear .= $filmheader; }
			
			#list 
			if($btdata =~ m/This torrent has been verified by the community/gi && $seeder>$seedmin) {
				$htmlthisyear .= '<li class="stylesmall"><img src="http://www.endust.com/images/green-check.gif" alt="Verified!!" align="absmiddle" /><a href="' . $dlurl . '">' . $filename . '</a> - ' . $size . 'MB - S/L: ' . $seeder . '/' . $leecher . '</p></li>';
				$verified = 1;
				} # if this torrent is verified
			elsif(($fake+$password+$lowquality+$virus)<1 && $seeder>$seedmin) { # list the torrent filename, with good and number of seeder/leecher
				$htmlthisyear .= '<li class="stylesmall"><a href="' . $dlurl . '">' . $filename . '</a> - ' . $size . 'MB - S/L: ' . $seeder . '/' . $leecher . ' - <span class="stylegreen">good: ' . $good . '</span></p></li>';
			}
			else {
				$numbad++;
				next;
				}
			sleep 1;
			$num++;

		} # end while loop thru 5 bit torrent files
	
		if($num > 1) {
			print " - $filmnum, $num torrents";
			$filmnum++; #number of movies found for this year
			$numverified += $verified;
			$htmlthisyear .= '</ul>';
			#plot
			$plothtml = '<td  width="275" align="left" valign="top" bgcolor="' . $bgcolor . '"><span class="stylesmall"><b>TAG:</b> ' . $tagline . '<br><b>PLOT:</b><em> ' . $plot . '</em><br><b>Comment:</b> ' . $comments . '</span></tr>';
			$htmlthisyear .= $plothtml;
		} #if there was a torrent

	} #while loop through list of movies

$htmlthisyear  .= '</table>';

#top off year with year header
$filmnum--;
$headeryear = $htmlheaderyear;
$headeryear =~ s/YEAR/$i/;
$headeryear =~ s/MOV/$filmnum/;
$headeryear =~ s/VER/$numverified/;
$headeryear =~ s/IMDB/$imdburl/;
$headeryear =~ s/LABEL/$i/;

$htmlfile .= $headeryear;
$htmlfile .= $htmlthisyear;

print "\n>>>>>$i<<<<<<\n";

open(OUT, ">out.html");
print OUT $htmlfile;
close(OUT);

} #for loop through all years (put it all into 1 page)


####################
# retrieve webpage
#####################
sub retrieveWebpage {
	my $url =shift;
	my $ua = LWP::UserAgent->new;
	$ua->agent('Mozilla/4.5');
	$ua->timeout(100);
	$ua->env_proxy;
	my $response = $ua->get($url);
	$returnme = $response->content;
	$returnme =~ s/\&nbsp;/ /g;
	$returnme =~ s/\&quot;/\"/g;
	$returnme =~ s/\&rsquo;/\'/g;
	$returnme =~ s/\&gt;//g;
	$returnme =~ s/\&lt;//g;
	$returnme =~ s/\&\#\d{1,4};//g; # this shouldnt put spaces for apostraphes
	$returnme =~ s/\&\#\w{1,4};//g;
	$returnme =~ s/<.?b>/ /g;
	$returnme =~ s/\s+/ /g;
	$returnme =~ s/<\/??font[^>]*>//gi;
	return $returnme;
} # end sub