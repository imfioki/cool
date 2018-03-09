This repository holds the following treasures:

****
./DCRecoveryLab
****
As part of some training development, I came up with the idea for a DC Recovery lab, where I used CloudFormation to spin up an EC2 environment and deployed a broken domain scenario.

The project consists of:

1) BrokenDC.json
  1a) This is the CF templater
2) Encoder.ps1
  2a) I used this small script to encode userdata during the building phase of the project, likely not needed anymore.
3) Instance1_Builder.ps1
  3a) This script is responsible for provisioning some security configurations outside of CF template, staging user accounts, disabling local firewall, installing ActiveDirectory binaries, initiating forest, gathering userdata for child-launch process, configuring scheduled tasks, and starting the daisy-chaining of the child domain controller.
4) Instance2_Destroyer.ps1
  4a) This script is reasonable for staging user accounts, disabling local firewalll, installing ActiveDirectory binaries, creating local tasks, and the fun part of destroying the domain.

This lab provided an environment for trainees to learn how to troubleshoot a broken domain, where the end solution is seizing and transferring FSMO roles.

****


****
./twitterDataMiner
****
This was part of my onboarding for the Big Data profile, where the final project was to scrap data from twitter and gather some basic statistics about the data, including:

1) Top 10 popular users
2) Top language used for scraped window
3) Top 10 hashtags.

I chose to scrap data for #cryptocurrency, and added sentiment analysis in order to provide visualization of sentiment for a given cryptocurrency.

The project consists of:

1) Twithash.py
  1a) This script utilizes tweepy, which is a public twitter library for python.
  1b) The script collects data from twitter, and concatenates sentiment obtained from AWS comprehend
  1c) Then data is then output to Kinesis firehose
 
2) SparkPhs5Project
  2a) The file contains hive queries, as well as spark code for the same analysis.
  2b) DataPipeline template is not included, but you can run manually.
  
  <The API keys for twitter are dead and can't be used>
****

****
./whitePaperArchitecture
****

As part of my ownboarding to the Big Data profile at AWS, I wrote up a simple solutions architecture utilizing the followihng services:

1) Kinesis Streams and FireHose
2) S3
3) ElasticSearch
4) DynamoDB
5) Athena

An explanation of the purpose of each component is contained within the solution's index.
****
