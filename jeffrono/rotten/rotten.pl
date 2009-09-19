#!/usr/bin/perl

use LWP::UserAgent;
use LWP::Simple;

$seedmin = 10;
for ($i=1995; $i>1948; $i--) {
	$htmlfile = "";
	$rtm = retrieveWebpage('http://www.rottentomatoes.com/top/bestofrt_year.php?year=' . $i);
	
	#build up the html file
	open(TOP, "<header.htm");
	while(<TOP>) { $htmlfile .= $_; }
	
	$htmlfile .= '<table border="0" cellpadding="5" cellspacing="0">';
	
	$filmnum = 1;
	while ($rtm =~ />(\d+)\%<\/td><td><a href=\"([^\"]+)\">([^<]+)</gi) {
		$tmeter = $1;
		$turl = $2;
		$title = $3;
		$rturl = 'http://www.rottentomatoes.com' . $turl;

		if($filmnum % 2 == 0) {$bgcolor = "E8EDF5"; }
		else{$bgcolor = "FFFFFF"; }
		# query btjunkie
		$bttitle = $title;
		$bttitle =~ s/ /+/gi;
		$searchurl = 'http://btjunkie.org/search?q=%22' . $bttitle . '%22&c=0&t=1&o=52&s=1&l=1';
		$btj = retrieveWebpage($searchurl);
		if($btj =~ m/0 matches/gi) { next; }
		$num = 1;
		$numbad = 1;
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
			if($num == 1 && $seeder>$seedmin && ($fake+$password+$lowquality+$virus)<1) { $htmlfile .= getRTheader($rturl, $title, $bgcolor, $searchurl, $tmeter, $turl); }
			
			#list 
			if($btdata =~ m/This torrent has been verified by the community/gi && $seeder>$seedmin) {
				$htmlfile .= '<li class="style79"><img src="verified.jpg" alt="Verified!!" width="20" height="20" align="absmiddle" /><a href="' . $dlurl . '">' . $filename . '</a> - ' . $size . 'MB - S/L: ' . $seeder . '/' . $leecher . '</p></li>';
				} # if this torrent is verified
			elsif(($fake+$password+$lowquality+$virus)<1 && $seeder>$seedmin) { # list the torrent filename, with good and number of seeder/leecher
				$htmlfile .= '<li class="style79"><a href="' . $dlurl . '">' . $filename . '</a> - ' . $size . 'MB - S/L: ' . $seeder . '/' . $leecher . ' - <span class="style2">good: ' . $good . '</span></p></li>';
				#,<span class="style3"> ' . $fake . ', ' . $password . '</span>
			}
			else {
				$numbad++;
				next;
				}
			sleep 1;
			$num++;

		} # end while loop thru 5 bit torrent files
	
		print "$filmnum - $title - $num\n";	
		if($num > 1) {
			$filmnum++;
			$htmlfile .= '</ul>';
			#plot
			$htmlfile .= getplot($rturl, $bgcolor);
		} #if there was a torrent
	} #while loop through list of film titles
	
	#search and replace option for $i year
	$htmlfile .= '</table>';
	$htmlfile =~ s/value=\"$i.html\">/value=\"$i.html\" selected>/;
	$nextp = $i +1;
	$prevp = $i -1;
	$htmlfile =~ s/previous\">\&lt\;\&lt\; previous/$prevp.html\">\&lt\;\&lt\; previous/;
	$htmlfile =~ s/next\">next >>/$nextp.html\">next >>/;
	open(OUT, ">$i.html");
	print OUT $htmlfile;
	close(OUT);
	
	if($i == 2008) {
		open(OUT, ">index.html");
		print OUT $htmlfile;
		close(OUT);
	}
	
	print ">>>>>$i<<<<<<<<<\n";
} # for loop, through all years

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


####################
# replace all crappy html characters with real ones
#####################

sub replaceChars {
	my $text=shift;
	$text =~ s/\r|\n|\t/ /g;
	$text =~ s/script>[^<]+<\/script>/>/gi;
	$text =~ s/<[^>]+>/ /g;
	$text =~ s/\s+/ /g;
	return $text;
}


####################
# get the genre for a rt film
#####################

sub getRTheader {
	my $url = $_[0];
	my $title = $_[1];
	my $bgcolor = $_[2];
	my $btj = $_[3];
	my $tmeter = $_[4];
	my $turl = $_[5];
	my $page = retrieveWebpage($url);
	
	my $genre = "";
	my $jpgurl = "";
	
	$page =~ s/<span class=\"content\">//gi;
	
	#Genre:</span> <span class="content"><a href="/movie/browser.php?genre=200006">Musical & Performing Arts<
	if($page =~ /Genre:<\/span> <a href=\"\/movie\/browser.php\?genre=\d+\">([^<]+)</gi) { $genre = $1; }
	
	#<a href="/m/10009538-happy-go-lucky/"><img src="http://images.rottentomatoes.com/images/movie/custom/38/10009538.jpg"
	if($page =~ /$turl\"><img src=\"([^\"]+)\"/i) { $jpgurl = $1; }
	#print "$jpgurl\n";
	my $header = '<tr bgcolor="' . $bgcolor . '"><td width="144" rowspan="2" valign="top"><img src="' . $jpgurl . '" width="144" height="208"></td>
		<td width="300" valign="top"><a href="' . $url . '" class="style78">' . $title . ' - (' . $tmeter . '%)</a> - (<a href="' . $btj . '">search</a>)</td>
		<td width="400" valign="top"><span class="style79"><b>' . $genre . '</b></span></td></tr><tr><td align="left" valign="top" bgcolor="' . $bgcolor . '"><ul>';
	return $header;
} #rt header


####################
# get plot for rt film
#####################

sub getplot {
	my $url = $_[0];
	my $bgcolor = $_[1];
	my $page = retrieveWebpage($url);
	$page =~ s/<\/?i>//g;
	#print $page;
	if($page =~ /movie_synopsis_all\" style=\"display: none\;\">([^<]+)</gi) { $plot = $1; }
	#movie_synopsis_all" style="display: none;">Delbert </span> <a 
	
	my $plothtml = '<td  width="400" align="left" valign="top" bgcolor="' . $bgcolor . '"><span class="style79"><em>' . substr($plot, 0, 750) . '</em></span></tr>';
	return $plothtml;
} #rt header