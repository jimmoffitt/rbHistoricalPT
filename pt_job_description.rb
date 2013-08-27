#=======================================================================================================================
#Historical PowerTrack Job Description.
#Simple helper class for reading in and handling job descriptions.
#Has methods for loading in a YAML job description file and returning as JSON.

class JobDescription

    attr_accessor :title, :to_date, :from_date, :rules_file, :rules, :service_name,
                  :publisher, :stream_type, :data_format

    def initialize
        #Defaults.
        @publisher = "twitter"
        @stream_type = "track"
        @data_format = "activity-streams"
    end

    def getConfig(config_file)

        config = YAML.load_file(config_file)

        #Job details.
        @title = config["job"]["title"]
        @to_date = config["job"]["to_date"]
        @from_date = config["job"]["from_date"]
        @service_name  = config["job"]["service_name"]
        @publisher  = config["job"]["publisher"]
        @stream_type = config["job"]["stream_type"]
        @data_format = config["job"]["data_format"]

        #Rules file in a YAML sequence format or it's a JSON file.
        @rules_file = config["rules_file"]
    end

    def getJobDescription

        #Create Rules object .
        oRules = PtRules.new
        #Create rules for this Job. Load rules from "rules_file" and add to job description.

        #if it is a .rules file then it is YAML...
        if @rules_file.split(".").last == "rules" then
            oRules.loadRulesYAML(@rules_file)
        else
            oRules.loadRulesJSON(@rules_file)
        end

        #Syntax for adding one rule at a time.
        #oRules.addRule("bounding_box[ ]", "geo")

        #Add Rules to Job description.
        @rules = oRules.getHash
        #p oJob.getJSON
        getJSON
    end


    #Returns job description in JSON.
    def getJSON
        job = {:title => @title, :publisher => @publisher, :toDate => @to_date.to_s, :fromDate => @from_date.to_s, :streamType => @stream_type,
               :dataFormat => @data_format, :serviceUsername => @service_name, :rules => @rules }
        job.to_json
    end

end #Job Description class.

