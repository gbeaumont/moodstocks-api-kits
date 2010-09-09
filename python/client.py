#!/usr/bin/env python

# Copyright (c) 2010 Moodstocks SAS
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# This is a basic client for Moodstocks API (api.moodstocks.com)

import MultipartPostHandler, urllib, urllib2
from sys import argv, exit
from urlparse import urlparse
import json

class MoodstocksAPI:

  def __init__(self, key, secret):
    """
    Usage: m_api = MoodstocksAPI( my_key, my_secret )
    See http://api.moodstocks.com/en/documentation.
    """
    pass_manager = urllib2.HTTPPasswordMgrWithDefaultRealm()
    pass_manager.add_password(None, "http://api.moodstocks.com", key, secret)
    self.auth_handler = urllib2.HTTPDigestAuthHandler(pass_manager)
    self.opener = urllib2.build_opener( self.auth_handler )
    self.multipart_opener = urllib2.build_opener( self.auth_handler,
     MultipartPostHandler.MultipartPostHandler )

  def __get_request(self, ep, params):
    return self.opener.open( "%s?%s" % (ep, urllib.urlencode(params)) )

  def __results(self, ans):
    return json.loads(ans.read())["results"]

  def echo(self, params):
    """
    Usage: m_api.echo(hash_of_strings)
    It should return the same hash.
    """
    ep = "http://api.moodstocks.com/items/echo"
    return self.__results(self.__get_request(ep, params))

  def recognize(self, query, filters=None):
    """
    Usage: m_api.request(query)
    If `query` is a URL a GET request will be performed.
    If query is a local filename a POST request will be performed.
    Returns a list of matches.
    """
    ep = "http://api.moodstocks.com/items/recognize"
    data = { "filters": filters } if filters else {}
    if len(urlparse(query).scheme): # query is an URL
      data["image_url"] = query
      ans = self.__get_request(ep, data)
    else: # query is a local image
      data["image_file"] = open(query, "rb")
      ans = self.multipart_opener.open(ep, data)
    return self.__results(ans)["matches"]

if __name__=="__main__":
  # This is an example of how to use this client library to recognize an image.
  if len(argv) != 4:
    print "USAGE: " + argv[0] + " key secret [file|url]"
    print len(argv)
    exit(1)
  api = MoodstocksAPI( argv[1], argv[2] )
  for i in api.recognize(argv[3]): print i
