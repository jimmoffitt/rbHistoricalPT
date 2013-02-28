rbHistoricalPT
==============

A Ruby script for submitting, monitoring and retrieving Historical PowerTrack jobs...

This is a simple, headless, single-threaded Ruby script written to help illustrate the "work flow"
    of the Historical PowerTrack process.

    Currently this script does not stream the Historical data, but instead relies solely on the
    "flat-file" method of data delivery.

    For hopefully better and not worse, this script has a fair amount of comments.  It seems most Ruby code
    has very little comments since Ruby is so readable...  I included a lot of comments since I assume this
    example code will be reviewed by non-Ruby developers, and hopefully the extra narrative helps
    teach more about the Historical PowerTrack system.

    This script currently writes out to standard out fairly often with various information.  You may want to comment
    those out or redirect to a log file.  Also, be warned that this script currently has no error handling.

    A "status" setting gate-keeps the user through the workflow.  When the script is first executed with a new job
    description, it will submit the job, then move on to the "is quotation ready?" stage, loop there, resting 5
    minutes between checks.  Once the quote is ready, the job needs to be accepted or rejected.

        [Important Note: if you are test-driving Historical PowerTrack (or "trialing"), job acceptance/rejection
        will be a manual process (by Gnip staff) and can not be automated via the Historical PowerTrack API. Once
        you are in a subscription or on-demand contract, you'll be able to automate this approval process]

    Accepted quotes are launched, and then the job status is rechecked until the job is complete.  Historical jobs
    commonly take hours to complete, so this script checks the job status every five minutes until it is finished.

    Once finished, the script uses basic curl and linux commands to download and uncompress the files.
    Note: Windows users will likely need to override the downloadData and uncompressData methods.

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

    Classes offered here: PtHistoricalJob, JobDescription, PtREST, PtRules.
    Note: This version has the PtREST and PtRules classes included here.  These classes will soon become common classes,
    shared by multiple PowerTrack applications.

    Currently, Historical PowerTrack is only for Twitter. While this code is written in anticipation of
    expanding to other Publishers, there currently are these Job defaults:
            #publisher = "twitter" #(only Historical publisher currently)
            #product = "track"  #(only Historical product currently)
