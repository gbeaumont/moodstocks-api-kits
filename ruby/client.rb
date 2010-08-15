#--
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
#++

# == Dependencies
# You'll first need to install these Ruby gems:
# * HTTParty
# * REST Client (for multipart POST support)

require 'rubygems'
require 'httparty'
require 'rest-client'
require 'uri'

# HTTParty monkey patch used to clean up the user defined HTTP headers before
# the Digest Auth HEAD request is performed
module HTTParty
  class Request
    alias :orig_setup_digest_auth :setup_digest_auth
    def setup_digest_auth
      options.delete(:headers)
      orig_setup_digest_auth
    end
  end
end

# == Moodstocks API client
module Moodstocks
  class Api
    include HTTParty
    base_uri 'api.moodstocks.com'
    digest_auth 'ApIkEy', 'SeCrEtKeY'
    
    class << self
      ECHO      = '/items/echo'
      RECOGNIZE = '/items/recognize'
      
      # This method simply echoes all parameters back in the JSON response
      def echo(params = {}); get(ECHO, :query => params) end
    
      # This method performs image recognition
      #
      # * query - The image file or URL to be recognized
      # * filters - optional filter string used to narrow down the search
      #             e.g. "category = Books and price <= 120"
      def recognize(query, filters = nil)
        params = { :filters => filters }
        uri = URI.parse(query)
        case uri.scheme
        when nil
          if File.file?(query = File.expand_path(query))
            File.open(query, 'rb') do |file|
              params[:image_file] = file
              mp = RestClient::Payload::Multipart.new(params)
              post(RECOGNIZE, :body => mp.read, :headers => mp.headers)
            end
          else
            raise ArgumentError, "Invalid query image"
          end
        else
          get(RECOGNIZE, :query => params.update(:image_url => query))
        end
      end # recognize
    end # class << self
  end # Api
end # Moodstocks

# == Example requests
if __FILE__ == $0
  QUERY_URL  = 'http://static.example.com/images/1234.jpg'
  QUERY_FILE = '/path/to/local/query/image.jpg'
  
  # Check your credentials
  code = Moodstocks::Api.echo.response.code
  puts "`echo' status: #{code == '200' ? 'OK' : 'KO'}"
  
  # Recognition query from an image URL
  resp = Moodstocks::Api.recognize(QUERY_URL)

  # Get the parsed JSON response, i.e. Ruby hash, and print it
  results = resp.parsed_response
  puts results.inspect
  # => {"results"=>{"matches"=>["4acEF12", "129ab"]}, "message"=>"", "status"=>"ok"}
  
  # Now perform image recognition by POSTing a query image and specifying
  # a filter (that should be relevant with the data you've imported)
  resp = Moodstocks::Api.recognize(QUERY_FILE, "director = Woody Allen")
  puts resp.parsed_response.inspect
end
