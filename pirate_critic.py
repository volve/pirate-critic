#!/usr/bin/env python
#Copyright (c) 2009, Marcelo Gosling, marcelo.gosling@gmail.com
#All rights reserved.
#
#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions are met:
#  * Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#  * Neither the name of Marcelo Gosling nor the
#    names of its contributors may be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
#THIS SOFTWARE IS PROVIDED BY Marcelo Gosling ''AS IS'' AND ANY
#EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#DISCLAIMED. IN NO EVENT SHALL Marcelo Gosling BE LIABLE FOR ANY
#DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# TODO: port BeautifulSoup dependency to lxml (due to BS 3.1 parsing intolerances)
# TODO: expand TITLEENDSWITH array to be flexible release name handler (XBMC has some robust routines for exactly this)
# TODO: Django!
# TODO: Usenet!
# TODO: IMDB!

from BeautifulSoup import BeautifulSoup
from urllib import urlopen
from pprint import pprint
import re

PIRATEBAYURL='http://thepiratebay.org/top/201'
TITLEENDSWITH = [ 'DvD', 'CAM', '[', '200', 'DVD', 'KLAXXON', '(', 'PROPER', 'SCREENER', 'WS', 'R5', 'TS', 'TC' ]
SEARCHURL = 'http://www.metacritic.com/search/process?sort=relevance&termType=all&ts=%s&ty=1&x=0&y=0'

def clean_title(title):
    for separator in TITLEENDSWITH:
        title = title.split(separator)[0]
    title = ' '.join(title.split('.'))
    title = '&'.join(title.split('&amp;'))
    return title.strip()

def get_score(title,verbose=False):
    url = SEARCHURL % '+'.join(title.split(' '))
    soup = BeautifulSoup(urlopen(url).read())
    regex = re.compile('^red$|^yellow$|^green$')
    try:
        score = int(soup.find(attrs={'class' : regex}).contents[0])
        if verbose:
            print score, title
        return score
    except:
        if verbose:
            print 'Could not get score for %s.' % title
        return 0

def get_list(verbose=False):
    if verbose:
        print "Getting Pirate Bay 100 top movie torrents...",
    soup = BeautifulSoup(urlopen(PIRATEBAYURL).read())
    if verbose:
        print "Done!"
    links = soup.findAll(attrs={'class': 'detLink'})
    torrents = [link.contents[0] for link in links]
    movies = [clean_title(title) for title in torrents]
    scores = [get_score(title, verbose) for title in movies]
    results = {}
    for i in xrange(len(movies)):
        results[movies[i]] = scores[i]
    return results

if __name__ == '__main__':
    results = get_list(True)
    for i in sorted(results, key = results.get):
        print '%2d  %s' % (results[i], i)
