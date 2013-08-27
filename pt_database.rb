#=======================================================================================================================
#Database class.

'''
This class is meant to demonstrate basic code for building a "database" class for use with the
PowerTrack set of example code.  It is written in Ruby, but in its present form hopefully will
read like pseudo-code for other languages.

One option would be to use (Rails) ActiveRecord for data management, but it seems that may abstract away more than
desired.

Having said that, the database was created (and maintained/migrated) with Rails ActiveRecord.
It is just a great way to create databases.

ActiveRecord::Schema.define(:version => 20130306234839) do

  create_table "activities", :force => true do |t|
      t.integer  "native_id",   :limit => 8
      t.text     "content"
      t.text     "body"
      t.string   "rule_value"
      t.string   "rule_tag"
      t.string   "publisher"
      t.string   "job_uuid"
      t.datetime "created_at",               :null => false
      t.datetime "updated_at",               :null => false
      t.float    "latitude"
      t.float    "longitude"
      t.datetime "posted_time"
  end

end

The above table fields are a bit arbitrary.  I cherry picked some Tweet details and promoted them to be table fields.
Meanwhile the entire tweet is stored, in case other parsing is needed downstream.
'''

class PtDatabase
    require "mysql2"
    require "time"
    require "json"
    require "base64"

    attr_accessor :client, :host, :port, :user_name, :password, :database, :sql

    def initialize(host=nil, port=nil, database=nil, user_name=nil, password=nil)
        #local database for storing activity data...

        if host.nil? then
            @host = "127.0.0.1" #Local host is default.
        else
            @host = host
        end

        if port.nil? then
            @port = 3306 #MySQL post is default.
        else
            @port = port
        end

        if not user_name.nil?  #No default for this setting.
            @user_name = user_name
        end

        if not password.nil? #No default for this setting.
            @password = password
        end

        if not database.nil? #No default for this setting.
            @database = database
        end
    end

    #You can pass in a PowerTrack configuration file and load details from that.
    def config=(config_file)
        @config = config_file
        getSystemConfig(@config)
    end


    #Load in the configuration file details, setting many object attributes.
    def getSystemConfig(config)

        config = YAML.load_file(config_file)

        #Config details.
        @host = config["database"]["host"]
        @port = config["database"]["port"]

        @user_name = config["database"]["user_name"]
        @password_encoded = config["database"]["password_encoded"]

        if @password_encoded.nil? then  #User is passing in plain-text password...
            @password = config["database"]["password"]
            @password_encoded = Base64.encode64(@password)
        end

        @database = config["database"]["schema"]
    end


    def to_s
        "PowerTrack object => " + @host + ":" + @port.to_s + "@" + @user_name + " schema:" + @database
    end

    def connect
        #TODO: need support for password!
        @client = Mysql2::Client.new(:host => @host, :port => @port, :username => @user_name, :database => @database )
    end

    def disconnect
        @client.close
    end

    def SELECT(sql = nil)

        if sql.nil? then
            sql = @sql
        end

        result = @client.query(sql)

        result

    end

    def UPDATE(sql)
    end

    def REPLACE(sql)
        begin
            result = @client.query(sql)
            true
        rescue
            false
        end
    end

    #NativeID is defined as an integer.  This works for Twitter, but not for other publishers who use alphanumerics.
    #Tweet "id" field has this form: "tag:search.twitter.com,2005:198308769506136064"
    #This function parses out the numeric ID at end.
    def getNativeID(id)
        native_id = Integer(id.split(":")[-1])
    end

    #Twitter uses UTC.
    def getPostedTime(time_stamp)
        time_stamp = Time.parse(time_stamp).strftime("%Y-%m-%d %H:%M:%S")
    end

    #With Rehydration, there are no rules, just requested IDs.
    def getMatchingRules(matching_rules)
        return "rehydration", "rehydration"
    end

    '''
    Parse the activity payload and get the lat/long coordinates.
    ORDER MATTERS: Latitude, Longitude.

    #An example here we have POINT coordinates.
    "location":{
        "objectType":"place",
        "displayName":"Jefferson Southwest, KY",
        "name":"Jefferson Southwest",
        "country_code":"United States",
        "twitter_country_code":"US",
        "link":"http://api.twitter.com/1/geo/id/7a46e5213d3a1af2.json",
        "geo":{
            "type":"Polygon",
            "coordinates":[[[-85.951854,37.997244],[-85.700857,37.997244],[-85.700857,38.233633],[-85.951854,38.233633]]]}
    },
    "geo":{"type":"Point","coordinates":[38.1341,-85.8953]},
    '''

    def getGeoCoordinates(activity)

        geo = activity["geo"]
        latitude = 0
        longitude = 0

        if not geo.nil? then #We have a "root" geo entry, so go there to get Point location.
            if geo["type"] == "Point" then
                latitude = geo["coordinates"][0]
                longitude = geo["coordinates"][1]

                #We are done here, so return
                return latitude, longitude

            end
        end

        #p activity["location"]
        #p activity["location"]["geo"]
        #p activity["geo"]

        return latitude, longitude
    end

    #Replace some special characters with an _.
    #(Or, for Ruby, use ActiveRecord for all db interaction!)
    def handleSpecialCharacters(text)

        if text.include?("'") then
            text.gsub!("'","_")
        end
        if text.include?("\\") then
            text.gsub!("\\","_")
        end

        text
    end


    '''
    storeActivity
    Receives an Activity Stream data point formatted in JSON.
    Does some (hopefully) quick parsing of payload.
    Writes to an Activities table.

    t.integer  "native_id",   :limit => 8
    t.text     "content"
    t.text     "body"
    t.string   "rule_value"
    t.string   "rule_tag"
    t.string   "publisher"
    t.string   "job_uuid"  #Used for Historical PowerTrack.
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "posted_time"
    '''

    def storeActivity(activity, uuid = nil)

        data = JSON.parse(activity)

        #Handle uuid if there is not one (tweet not returned by Historical API)
        if uuid == nil then
            uuid = ""
        end

        #Parse from the activity the "atomic" elements we are inserting into db fields.

        post_time = getPostedTime(data["postedTime"])

        native_id = getNativeID(data["id"])

        body = handleSpecialCharacters(data["body"])

        content = handleSpecialCharacters(activity)

        #Parse gnip:matching_rules and extract one or more rule values/tags
        rule_values, rule_tags  = "rehydration", "rehydration" #getMatchingRules(data["gnip"]["matching_rules"])

        #Parse the activity and extract any geo available data.
        latitude, longitude = getGeoCoordinates(data)

        #Build SQL.
        sql = "REPLACE INTO activities (native_id, posted_time, content, body, rule_value, rule_tag, publisher, job_uuid, latitude, longitude, created_at, updated_at ) " +
            "VALUES (#{native_id}, '#{post_time}', '#{content}', '#{body}', '#{rule_values}','#{rule_tags}','Twitter', '#{uuid}', #{latitude}, #{longitude}, UTC_TIMESTAMP(), UTC_TIMESTAMP());"

        if not REPLACE(sql) then
            p "Activity not written to database: " + activity.to_s
        end
    end
end #PtDatabase class.
