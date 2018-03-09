#Import libraries
from tweepy.streaming import StreamListener
from tweepy import OAuthHandler
from tweepy import Stream
import time
import sys
import boto3
import json

# Create comprehend
compClient = boto3.client('comprehend')
hoseClient = boto3.client('firehose')

FIREHOSE_STREAM = "BotoDemo"

# Create a streamer object
class StdOutListener(StreamListener):

    # Define a function that calls comprehend and returns sentiment
    def comprehend(self, text):
        response = compClient.batch_detect_sentiment(TextList=[text], LanguageCode='en')
        sentiment = response["ResultList"][0]["Sentiment"]
        #print(text)
        return sentiment

    # Define a function that is initialized when the miner is called
    def __init__(self, api = None):
        # That sets the api
        self.api = api

    # When a tweet appears
    def on_status(self, status):

        # If the tweet is not a retweet
        if not 'RT @' in status.text:
            # Try to
            try:
                # Create output objects for firehose PUT
                output = (str(status.user.screen_name) + ", " +
                            str(status.user.location) + ", " +
                            str(status.place) + ", " +
                            str(status.user.lang) + ", " +
                            str(status.user.statuses_count) + ", " +
                            str(status.user.followers_count) + ", " +
                            str(status.user.friends_count)
                 )

                #print('Payload before hashtags: %s' %output)

                hashtags = status.entities.get('hashtags')
                #print('Hashtags %s' % hashtags)

                hts = []

                if hashtags:
                    for ht in hashtags :
                        #print ht["text"]
                        hts.append(ht["text"])
                else:
                    hts.append('None')

                currSentiment = self.comprehend(status.text)
                list = output,hts,currSentiment
                #print('Printing payload: %s' %list)

                finalDict = {"tweet_data" : {'screen_name': str(status.user.screen_name),
                                             'user_location': str(status.user.location),
                                             'user_place': str(status.place),
                                             'user_lang': str(status.user.lang),
                                             'user_statuses_count': int(status.user.statuses_count),
                                             'user_followers_count': int(status.user.followers_count),
                                             'user_friends_count': int(status.user.friends_count)},
                             "hashtags": hts,
                             "sentiment": currSentiment}
                jsonBlob = json.dumps(finalDict)
                print(jsonBlob)
                response = hoseClient.put_record(
                        DeliveryStreamName=FIREHOSE_STREAM,
                        Record={
                        'Data': jsonBlob + '\n'
                                            })
                #print('Printing response %s' %response)

            # If some error occurs
            except Exception as e:
                # Print the error
                print(e)
                # and continue
                pass

        # Return nothing
        return

    # When an error occurs
    def on_error(self, status_code):
        # Print the error code
        print('Encountered error with status code:', status_code)

        # If the error code is 401, which is the error for bad credentials
        if status_code == 401:
            # End the stream
            return False
        # If the error code is 420, kill stream
        if status_code == 420:
            print("I can't believe I'm still getting rated limited :(")
            return False

    # When a deleted tweet appears
    def on_delete(self, status_id, user_id):

        # Print message
        print("Delete notice")

        # Return nothing
        return

    # When reach the rate limit
    def on_limit(self, track):

        # Print rate limiting error
        print("Rate limited, continuing")

        # Continue mining tweets
        return True

    # When timed out
    def on_timeout(self):

        # Print timeout message
        print(sys.stderr, 'Timeout...')

        # Wait 10 seconds
        time.sleep(10)

        # Return nothing
        return

# Create a mining function
def start_mining(queries):
    '''
    Inputs list of strings. Returns tweets containing those strings.
    '''

    #Variables that contains the user credentials to access Twitter API
    #consumer_key = "MO4BSxt20kDv8PfpqTLZa3iuj"
    #consumer_secret = "iumw4lekPXFHfu4WYhXRon0RcmTWFdF5XnAJj7fJcTJ5fBoS5d"
    #access_token = "4198448473-UauDhjoQRUoP6Z90B5gVsSLUBjg3DTLUtOGxU2i"
    #access_token_secret = "nTBxhz7InUoTXrapMsvF1roMEXsTQeBEQETn2v1cuIetG"

    consumer_key = "iSv8NWGNR9Ti5liCML7AXZ37Z"
    consumer_secret = "Ug9EBy6gzRzdnVAnx74YJoQYJ9wzV6KdqD8VL0ivT0JVlzyxLj"
    access_token = "4198448473-3jKjsqU1SicOfhAG9jYnzPTiqGlFVkFJqaibWeg"
    access_token_secret = "hqzIEsmsoX8F9sHIGCHKlSRHEUNiY4e8X7VuPHEKfW30k"


    # Create a listener
    l = StdOutListener()

    # Create authorization info
    auth = OAuthHandler(consumer_key, consumer_secret)
    auth.set_access_token(access_token, access_token_secret)

    # Create a stream object with listener and authorization
    stream = Stream(auth, l)

    # Run the stream object using the user defined queries
    stream.filter(track=queries)

# Start the miner
start_mining(['cryptocurrency', '#cryptocurrency'])
