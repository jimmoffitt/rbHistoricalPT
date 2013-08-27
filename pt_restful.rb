#=======================================================================================================================
# A simple RESTful HTTP class put together to be a "common" class.
# Knows a bunch about HTTP, and a little about the PowerTrack family of products.
#
# This code evolved as it toured several PowerTrack products:
# Historical
# Rehydration.
# TODO: Search
#
# To be common to all PowerTrack ruby (RESTful) clients: Historical, Rehydration, Search.
# Stateless.
# A RESTful set of HTTP methods.
#
#Current PowerTrack products this object works with:
#  * Historical
#  * Rehydration
#  * Search

require "net/https"     #HTTP gem.
require "uri"           #HTTP gem.
require "open-uri"      #Used in downloadFiles method.

class PtRESTful

    attr_accessor :url, :user_name, :password_encoded, :headers, :data, :data_agent

    def initialize(url=nil, user_name=nil, password_encoded=nil, headers=nil)
        if not url.nil?
            @url = url
        end

        if not user_name.nil?
            @user_name = user_name
        end

        if not password_encoded.nil?
            @password_encoded = password_encoded
            @password = Base64.decode64(@password_encoded)
        end

        if not headers.nil?
            @headers = headers
        end
    end

    def url=(value)
        @url = value
        @uri = URI.parse(@url)
    end

    def password_encoded=(value)
        @password_encoded=value
        if not @password_encoded.nil? then
            @password = Base64.decode64(@password_encoded)
        end
    end

    #Helper functions for building URLs

    def getHistoricalURL(account_name=nil)
        @url = "https://historical.gnip.com:443/accounts/" #Root url for Historical PowerTrack API.

        if account_name.nil? then #using object account_name attribute.
            if @account_name.nil?
                p "No account name set.  Can not set url."
            else
                @url = @url + @account_name + "/jobs.json"
            end
        else #account_name passed in, so use that...
            @url = @url + account_name + "/jobs.json"
        end
    end

    def getRehydrationURL(account_name=nil)
        @url = "https://rehydration.gnip.com:443/accounts/"  #Root url for Rehydration PowerTrack.

        if account_name.nil? then #using object account_name attribute.
            if @account_name.nil?
                p "No account name set.  Can not set url."
            else
                @url = @url + @account_name + "/publishers/twitter/rehydration/activities.json?ids="
            end
        else #account_name passed in, so use that...
            @url = @url + account_name + "/publishers/twitter/rehydration/activities.json?ids="
        end
    end

    #Fundamental REST API methods
    def POST(data=nil)

        if not data.nil? #if request data passed in, use it.
            @data = data
        end

        uri = URI(@url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri.path)
        request.body = @data
        request.basic_auth(@user_name, @password)
        response = http.request(request)
        return response
    end

    def PUT(data=nil)

        if not data.nil? #if request data passed in, use it.
            @data = data
        end

        uri = URI(@url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Put.new(uri.path)
        request.body = @data
        request.basic_auth(@user_name, @password)
        response = http.request(request)
        return response
    end

    def GET(params=nil)
        uri = URI(@url)

        #params are passed in as a hash.
        #Example: params["max"] = 100, params["since_date"] = 20130321000000
        if not params.nil?
            uri.query = URI.encode_www_form(params)
        end


        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri.request_uri)
        request.basic_auth(@user_name, @password)

        response = http.request(request)
        return response
    end

    def DELETE(data=nil)
        if not data.nil?
            @data = data
        end

        uri = URI(@url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Delete.new(uri.path)
        request.body = @data
        request.basic_auth(@user_name, @password)
        response = http.request(request)
        return response
    end
end
