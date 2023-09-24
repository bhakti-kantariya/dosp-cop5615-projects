-module(twitterServer).
-export([startTwitterServer/0, signinHandler/2, signupHandler/2, signoutHandler/0, subscribeHandler/1, sendTweetHandler/1, signinActor/0, getTwitterUsers/0, subscribeToUserHandler/2,getmentionedUsers/0,getTweeterhashtag/1]).
-import(string,[concat/2]).


% Sign in function
signinHandler(UserId, Password) ->
    twitterUserHelper:signinTwitterUser(UserId, Password).

% Sign up function
signupHandler(UserId, Password)->
    twitterUserHelper:signupTwitterUser(UserId, Password).

% Sign out function
signoutHandler()->
    twitterUserHelper:signoutTwitterUser().

getmentionedUsers()->
    tweetspassing:getmentionedUsers().

getTweeterhashtag(Hashtag)->
    tweetspassing:getTweeterhashtag(Hashtag).

% Subscribe function
subscribeHandler(UserId)->
    twitterUserHelper:subscribeToTwitterUser(UserId).

% Zipf Simulation subscriber handler
subscribeToUserHandler(UserName, SubscriberCount)->
    io:format("NumberOfUser = ~p\n",[SubscriberCount]),
    twitterUserHelper:subscribeToTwitterUser(UserName).

% Send TweetMesage function
sendTweetHandler(TweetMessage)->
    try twitterTweetHelper:createTweet(TweetMessage)
    catch 
    error:_ -> 
      io:format("PLEASE SIGN IN TO USE THIS FUNCTIONALITY~n") 
    end.

signinActor()->
    receive
        %SignIn
        {UserId,PasswordAndProcess,Pid}->
            signupActor ! {UserId,PasswordAndProcess,self(),Pid, signin};
        %Registeration    
        {UserId,PassWord,Pid,register}->
            signupActor ! {UserId,PassWord,self(),Pid, register};
        {UserId,TweetMesage,Pid,tweet}->
            receiveTweetActor !{UserId,TweetMesage,self(),Pid};
        {UserId,Pid}->
            if 
                Pid==signOut->
                    [UserIdInput,TweeterNodePid]=UserId,
                    userToProcessIdMapActor!{UserIdInput,TweeterNodePid,self(),signOutUser};
                true->
                 receiveTweetActor !{UserId,self(),Pid}
            end;     
        {UserId,CurrrentUserName,Pid,PidOfReceive}->
            subscribeToUserActor ! {UserId,CurrrentUserName,PidOfReceive,self(),Pid}
    end,
    receive
        {Message,Pid1}->
            Pid1 ! {Message},
            signinActor()        
    end.

getTwitterUsers()->
    spawn(twitterUserHelper,getTwitterUsersList,[]).

startTwitterServer()->
    {ok, ServerHostName} = inet:gethostname(),
    Server = concat("server@", ServerHostName),
    Mapper = [#{"" => ""}],
    register(signupActor,spawn(list_to_atom(Server),twitterUserHelper,authenticateUser,Mapper)),
    register(subscribeToUserActor,spawn(list_to_atom(Server),twitterUserHelper,updateTwitterUserSubscriber,Mapper)),
    register(userToProcessIdMapActor,spawn(list_to_atom(Server),twitterUserHelper,twitterUserProcessIdMapper,Mapper)),
    register(receiveTweetActor,spawn(list_to_atom(Server),twitterTweetHelper,getTweet,Mapper)),
    register(hashTagActor,spawn(list_to_atom(Server),twitterTweetHelper,tweetHashtag,Mapper)).


