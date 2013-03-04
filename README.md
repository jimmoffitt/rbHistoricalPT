    Introduction
    ============

    This is a simple, headless, single-threaded Ruby script written to help illustrate the "work flow"
    of the Historical PowerTrack process.

    This version is a 100% RESTful implementation -- which significantly simplifies the HTTP parts... As streaming
    historical data becomes available (2013 Q2), this code and the HTTP object code will be extended to support
    streaming Historical data.

    To use Historical PowerTrack you will need to provide your account authentication details such as account name,
    user name, password and the 'label' assigned to your Historical PowerTrack stream.  These account details
    are specified in a configuration file formatted in YAML (http://en.wikipedia.org/wiki/YAML).  In this example code
    this file is named HistoricalPTConfig.yaml, but you can name it what you want and pass it in when creating the
    root PtHistoricalJob object.


    Historical Job Work Flow
    ========================

    This script will walk you through the process of submitting a Historical PowerTrack 'job'.

    Here are the states a Historical Job passes through:
            New
            Estimating
            Quoted
            Accepted/Rejected
            Running
            Finished

    The first step is submitting a Historical Job description. These job descriptions are formatted in JSON and
    include a title, the date range of interest, the output format, and a rules file.  This script loads these
    details from a YAML file.  For this example code the job description file is named HistoricalRequest.yaml.
    Again, you can name these job description files as you want and pass it in as the second argument when creating
    a PTHistoricalJob object.

        Note: Historical Job titles must be unique.

    The PowerTrack rules can be provided in either YAML or JSON formats.  YAML may be most appropriate when creating
    rules from scratch or converting from another source.  The JSON format is handy when you are pulling rules from
    another PowerTrack stream.

    This script encodes the Job description in JSON and posts it to your Historical PowerTrack HTTP end-point.  If the
    job is successfully submitted (description is correctly specified and your account credentials are valid), the
    job enters the estimation stage.

    The estimate can take many minutes to complete.  This script will loop, checking the estimation status every
    5 minutes until the estimate is ready.

    When the estimate is ready, a quote is provided that indicates an estimate of the number of activities that will
    be delivered, along with estimates for how long the job will take to extract and how big the data files will be.
    This information is provided as a "quote" JSON payload when hitting the job-specific end-point.  There is an
    example of this "quote" payload in the getStatus method header.

    After a job is quoted, the work flow stops until the job is accepted or rejected.

        Note: if you are test-driving Historical PowerTrack (or "trialing"), job acceptance/rejection
        will be a manual process (by Gnip staff) and can not be automated via the Historical PowerTrack API. Once
        you are in a subscription or on-demand contract, you'll be able to automate this approval process.

    If a job is accepted, the Job is launched and enters the "running" stage.  While a job is running, the actual data
    that matching the job's rules is extracted from the archives.  This process can take many hours to complete.  This
    script will loop, checking the job's progress (every 5-minutes currently) until the job is complete.

    When the job is complete, the status becomes "finished."  When a Job is finished the script will trigger the
    downloading and uncompressing of the job's data files.


    More Details
    ============

    For hopefully better and not worse, this script has a fair amount of comments.  It seems most Ruby code
    has very little comments since Ruby is so readable...  I included a lot of comments since I assume this
    example code will be reviewed by non-Ruby developers, and hopefully the extra narrative helps
    teach more about the Historical PowerTrack system.

    Classes offered here: PtHistoricalJob, JobDescription, PtREST, PtRules.
    Note: This version has the PtREST and PtRules classes included here.  These classes will soon become common classes,
    shared by multiple PowerTrack applications.

    This script currently writes to standard out fairly often with various information.  You may want to comment
    those out or redirect to a log file.  Also, be warned that this script currently has no error handling.

    A "status" setting (an OpenStruct 'object' with name/message/percent) gate-keeps the user through the workflow.
    When the script is first executed with a new job description, it will submit the job, then move on to the
    "is quotation ready?" stage, loop there, resting 5 minutes between checks.  Once the quote is ready, the job needs
    to be accepted or rejected.

    Here are the states a Historical Job passes through:
        #Possible states:
            # - new
            # - estimating --> triggers a 5-minute loop, waiting for job to be quoted.
            # - quoted
            # - accepted/rejected
            # - running   --> triggers a 5-minute loop, waiting for job to finish.
            # - finished  --> triggers code to download and uncompress files.


    There are two files passed into the 'constructor' of the PT Historical object:

        oHistPT = PtHistoricalJob.new("./MyConfig.yaml", "./jobDescriptions/MyJobDescription.yaml")

        Historical PowerTrack configuration file (MyConfig.yaml in this example) contains:

        config:
            account_name: <account_name>  #Used in URL for Historical API.
            user_name: <user_name>
            password_encoded: <EnCoDeDpAsSWoRd>
            stream_label: prod
            base_output_folder: ./output #Root folder for downloaded files.
            friendly_folder_names: true  #converts title into folder name by removing whitespace


        Job description file (MyJobDescription.yaml in this example) contains:

        job:
            #These will change from request to request.
            title: Test_4
            from_date: 201302010000
            #to_date: 201106010500
            to_date: 201302020000
            #These are 'static' values (more or less).
            service_name: gnip
            #These are optional, since they are defaults in code.
            publisher: twitter
            stream_type: track
            data_format: activity-streams

        #File with YAML-formatted rules.
        rules_file: ./rules/test.rules

    The Job Description file (MyJobDescription.yaml in this example) in turn references a YAML file containing the
    PowerTrack rules for the data retrieval.

        rules:
            - value  : (bounding_box:[-86.2 38.0 -85.743 38.35] OR bounding_box:[-85.743 38.0 -85.286 38.35] OR bounding_box:[-86.2 38.35 -85.743 38.7] OR bounding_box:[-85.743 38.35 -85.286 38.7])
            tag   : geo-louisville
            - value  : (rain OR flood OR storm OR weather)
            tag   : weather
            - value  : (rain OR precipitation OR flood) (inches OR in OR inch OR \")
            tag   : measurement
            - value  : ThisRuleWillNotMatchAndHasNoTag


    The Historical "PtHistoricalJob" object manages one Job in a single-threaded manner.  Code managing this class could
    spin up multiple objects.

    Currently, Historical PowerTrack is only for Twitter. While this code is written in anticipation of
    expanding to other Publishers, there currently are these Job defaults:
            #publisher = "twitter" #(only Historical publisher currently)
            #product = "track"  #(only Historical product currently)

