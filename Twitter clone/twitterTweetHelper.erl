-module(twitterTweetHelper).
-export([createTweet/1, getTweet/1,tweetHashtag/1,tweetParser/5,tweetReceiver/0,broadcastTweet/4,getmentionedUsers/0,getTweeterhashtag/1]).

createTweet(TweetMesage)->
    try persistent_term:get("SignedInTweeterUser")
    catch 
    error:X ->
        io:format("~p~n",[X])
    end,  
    SignedInTweeterUser=persistent_term:get("SignedInTweeterUser"),
    if
        SignedInTweeterUser==true-> 
            TweeterRemoteServerId=persistent_term:get("ServerId"),
            TweeterRemoteServerId!{persistent_term:get("UserId"),TweetMesage,self(),tweet},
            receive
                {Registered}->
                    io:format("~s~n",[Registered])  
            end;
        true->
            io:format("PLEASE SIGN IN TO USE THIS FUNCTIONALITY~n")
    end. 

getTweet(UserTweetMap)->
    receive
        {UserId,TweetMesage,Pid,TweeterNodePid}->
            ListTweets=maps:find(UserId,UserTweetMap),
            if
                ListTweets==error->
                    Pid ! {"User Not present in Server Database",TweeterNodePid},
                    getTweet(UserTweetMap); 
                true ->
                    {ok,Tweets}=ListTweets,
                    io:format("~s~n",[TweetMesage]),
                    io:format("~p~n",[Tweets]),
                    TweetMessages=lists:append(Tweets,[TweetMesage]),
                    io:format("~p~n",[TweetMessages]),
                    NewUserTweetMap=maps:put(UserId,TweetMessages,UserTweetMap), 
                    Pid ! {"TweetMesage Uploaded",TweeterNodePid},  
                    ModifiedTweetList=string:split(TweetMesage," ",all),
                    io:format("~p~n",[ModifiedTweetList]),
                    tweetParser(ModifiedTweetList,1,TweetMesage,UserId,"#"),
                    tweetParser(ModifiedTweetList,1,TweetMesage,UserId,"@"),
                    subscribeToUserActor ! {UserId,self()},
                    receive
                        {Subscribers}->
                          spawn(twitterTweetHelper,broadcastTweet,[Subscribers,1,TweetMesage,UserId])
                    end,                  
                    getTweet(NewUserTweetMap)  
            end;
         {UserId}->
            NewUserTweetMap=maps:put(UserId,[],UserTweetMap),
            getTweet(NewUserTweetMap);
         {UserId,Pid,TweeterNodePid}->
            ListTweets=maps:find(UserId,UserTweetMap),
            if
                ListTweets==error->
                    Pid ! {[],TweeterNodePid};
                true ->
                    {ok,Tweets}=ListTweets,
                    Pid ! {Tweets,TweeterNodePid}
            end,
            getTweet(UserTweetMap)
    end. 

getmentionedUsers()->
    UserId="@"++persistent_term:get("UserName"),
    ServerId=persistent_term:get("ServerId"),
    ServerId!{querying,UserId,self(),tweet},
    receive
        {Tweets}->
            displayTweets(Tweets,1) 
    end.

displayTweets(Tweets,Index)->
    if
        Index>length(Tweets) ->
            ok;
        true ->
            {Tweet,UserName}=lists:nth(Index,Tweets),
            tweetMap!{UserName,Tweet},
            displayTweets(Tweets,Index+1)
    end.

getTweeterhashtag(Tag)->
  ServerId=persistent_term:get("ServerId"),
  ServerId!{querying,Tag,self(),tweet},
  receive
    {Tweets}->
      displayTweets(Tweets,1)
  end.


tweetHashtag(HashTagTweetMap)->
   receive
    {HashTag,TweetMesage,UserId,addnewhashTag}->
        io:format("~s~n",[TweetMesage]),
        ListTweets=maps:find(HashTag,HashTagTweetMap),
        if
            ListTweets==error->
                NewHashTagTweetMap=maps:put(HashTag,[{TweetMesage,UserId}],HashTagTweetMap),
                tweetHashtag(NewHashTagTweetMap); 
            true ->
                {ok,Tweets}=ListTweets,
                io:format("~p~n",[Tweets]),
                TweetMessages=lists:append(Tweets,[{TweetMesage,UserId}]),
                io:format("~p~n",[TweetMessages]),
                NewHashTagTweetMap=maps:put(HashTag,TweetMessages,HashTagTweetMap),
                % io:format("~p",NewUserTweetMap),                
                tweetHashtag(NewHashTagTweetMap)  
        end;
     {HashTag,Pid,TweeterNodePid}->
        ListTweets=maps:find(HashTag,HashTagTweetMap),
        if
            ListTweets==error->
                Pid ! {[],TweeterNodePid};
            true ->
                {ok,Tweets}=ListTweets,
                io:format("~p~n",[Tweets]),
                Pid ! {Tweets,TweeterNodePid}
        end,
        tweetHashtag(HashTagTweetMap)
    end.

tweetParser(SplitTweet,Index,TweetMesage,UserId,Tag)->
    if
        Index==length(SplitTweet)+1 ->
         ok;
        true ->
            CurrentString=string:find(lists:nth(Index,SplitTweet),Tag,trailing),
            io:format("~s~n",[CurrentString]),
            if
                CurrentString==nomatch ->
                  ok;  
                true ->
                    hashTagActor ! {CurrentString,TweetMesage,UserId,addnewhashTag}  
            end,
            tweetParser(SplitTweet,Index+1,TweetMesage,UserId,Tag)
    end.

broadcastTweet(Subscribers,Index,TweetMesage,UserId)->
 if
    Index>length(Subscribers)->
            ok;
    true->
        {Username1,_}=lists:nth(Index,Subscribers),
        userToProcessIdMapActor!{Username1,TweetMesage},
        broadcastTweet(Subscribers,Index+1,TweetMesage,UserId)
 end.       

tweetReceiver()->
    receive
     {Message,UserId}->
        CurrentMessage="New tweet for "++UserId++" : "++Message,
        io:format("~s~n",[CurrentMessage]),
        tweetReceiver()
    end.
