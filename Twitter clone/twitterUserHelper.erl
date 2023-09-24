-module(twitterUserHelper).
-export([signupTwitterUser/2, signinTwitterUser/2, getTwitterUsersList/0, signoutTwitterUser/0, subscribeToTwitterUser/1, authenticateUser/1,updateTwitterUserSubscriber/1,twitterUserProcessIdMapper/1]).
-import(string,[concat/2]).

signupTwitterUser(UserId, Password)->
    {ok, Hostname} = inet:gethostname(),
    Server = concat("server@", Hostname),
    TweeterServerConnectionId=spawn(list_to_atom(Server),twitterServer,signinActor,[]),
    TweeterServerConnectionId ! {UserId,Password,self(),register},
    receive
        {Registered}->
            io:format("~s~n",[Registered])    
    end.

signinTwitterUser(UserId, Password)->
    {ok, Hostname} = inet:gethostname(),
    Server = concat("server@", Hostname),
    TweeterServerConnectionId=spawn(list_to_atom(Server),twitterServer,signinActor,[]),
    persistent_term:put("ServerId", TweeterServerConnectionId),
    register(tweetReceiver,spawn(twitterTweetHelper,tweetReceiver,[])),

    TweeterServerConnectionId!{UserId,[Password,whereis(tweetReceiver)],self()},   
    receive
        {Registered}->
            if
                Registered=="Tweeter User Logged in"->
                    persistent_term:put("UserId",UserId),
                    persistent_term:put("SignedInTweeterUser",true);
                true->
                    persistent_term:put("SignedInTweeterUser",false)      
            end,
            io:format("~s~n",[Registered])  
    end.

getTwitterUsersList()->
    SignedInTweeterUser=persistent_term:get("SignedInTweeterUser"),
    if
        SignedInTweeterUser==true-> 
            TweeterRemoteServerId=persistent_term:get("ServerId"),
            TweeterRemoteServerId!{self()},   
            receive
                {TweeterUserList}->
                    printTwitterUserList(TweeterUserList,1)
            end;
        true->
            io:format("PLEASE SIGN IN TO USE THIS FUNCTIONALITY~n")
    end.

signoutTwitterUser()->
    SignedInTweeterUser=persistent_term:get("SignedInTweeterUser"),
    if
        SignedInTweeterUser==true-> 
            TweeterRemoteServerId=persistent_term:get("ServerId"),
            TweeterRemoteServerId!{[persistent_term:get("UserId"),self()],signOut},
            receive
                {Registered}->
                    persistent_term:erase("UserId"),
                    io:format("~s~n",[Registered])  
            end;
        true->
            io:format("PLEASE SIGN IN TO USE THIS FUNCTIONALITY~n")
    end.        

subscribeToTwitterUser(UserId)->
    SignedInTweeterUser=persistent_term:get("SignedInTweeterUser"),
    if
        SignedInTweeterUser==true-> 
            TweeterRemoteServerId=persistent_term:get("ServerId"),
            TweeterRemoteServerId!{UserId,persistent_term:get("UserId"),self(),whereis(tweetReceiver)},   
            receive
                {Registered}->
                    io:format("~p~n",[Registered])  
            end;
        true->
            io:format("PLEASE SIGN IN TO USE THIS FUNCTIONALITY~n")
    end.

authenticateUser(UserPasswordMap)->
    receive
        %Sign Up
        {UserId,PassWord,Pid,TweeterNodePid, register}->
            TweeterUser=maps:find(UserId,UserPasswordMap),
            if
                TweeterUser==error->
                    ActiveUserDatastore=maps:put(UserId,PassWord,UserPasswordMap), 
                    receiveTweetActor ! {UserId},
                    Pid ! {"Tweeter User registered",TweeterNodePid},
                    authenticateUser(ActiveUserDatastore);
                true ->
                    Pid ! {"User is already registered.",TweeterNodePid},
                    authenticateUser(UserPasswordMap) 
            end;

        %SignIn
        {UserId,PasswordAndProcess,Pid,TweeterNodePid, signin}->
            {ok, UserPassword}=maps:find(UserId,UserPasswordMap),
            [Pass,Process]=PasswordAndProcess,
            if
                UserPassword==Pass->
                   userToProcessIdMapActor!{UserId,Process, signIn   },
                   Pid ! {"Tweeter User Logged in",TweeterNodePid};
                true ->
                    Pid ! {"Incorrect UserId or Password.",TweeterNodePid}
            end,
            authenticateUser(UserPasswordMap)
    end.





updateTwitterUserSubscriber(TweeterUserSubscriberMap)->
    receive
    
    {UserId,Pid}->
        ListSubscribers=maps:find(UserId,TweeterUserSubscriberMap),
        if
            ListSubscribers==error->
                Pid !{[]};
            true->
                {ok,Subscribers}=ListSubscribers,
                Pid ! {Subscribers}     
        end,         
        updateTwitterUserSubscriber(TweeterUserSubscriberMap); 
    {UserId,CurrentUserName,CurrentTweeterUserPid,Pid,TweeterNodePid}->
        ListSubscribers=maps:find(UserId,TweeterUserSubscriberMap),
        if
            ListSubscribers==error->
                TweeterUsersSubscribersMap=maps:put(UserId,[{CurrentUserName,CurrentTweeterUserPid}],TweeterUserSubscriberMap),
                Pid ! {"TweeterUserSubscribed",TweeterNodePid},
                updateTwitterUserSubscriber(TweeterUsersSubscribersMap); 
            true ->
                {ok,Subscribers}=ListSubscribers,
                io:format("~p~n",[Subscribers]),
                Subscribers1=lists:append(Subscribers,[{CurrentUserName,CurrentTweeterUserPid}]),
                io:format("UserId ~p ~p~n",[UserId,Subscribers1]),
                TweeterUsersSubscribersMap=maps:put(UserId,Subscribers1,TweeterUserSubscriberMap),
                Pid ! {"TweeterUserSubscribed",TweeterNodePid},                
                updateTwitterUserSubscriber(TweeterUsersSubscribersMap)  
        end
    end.   

printTwitterUserList(TweeterUserList,Index)->
    if
        Index>length(TweeterUserList)->
            ok;
        true->
            {UserId,_}=lists:nth(Index,TweeterUserList),
            io:format("~s~n",[UserId]),
            printTwitterUserList(TweeterUserList,Index+1)
    end.


twitterUserProcessIdMapper(UserProcessIdMap)->
    receive
    {UserId,CurrentTweeterUserPid, signIn}->
        TweeterUserProcessMap=maps:put(UserId,CurrentTweeterUserPid,UserProcessIdMap),  
        twitterUserProcessIdMapper(TweeterUserProcessMap);

    {UserId,TweetMesage}->
        ListSubscribers=maps:find(UserId,UserProcessIdMap),
        if
            ListSubscribers==error->
                ok;
            true->
                {ok,ProcessId}=ListSubscribers,
                ProcessId ! {TweetMesage,UserId}   
        end,         
        twitterUserProcessIdMapper(UserProcessIdMap);

    {UserId,TweeterNodePid,Pid,signOutUser}->
        ListSubscribers=maps:find(UserId,UserProcessIdMap),
        if
            ListSubscribers==error->
                Pid ! {"",TweeterNodePid},
                twitterUserProcessIdMapper(UserProcessIdMap); 
            true ->
                TweeterUserProcessMap=maps:remove(UserId,UserProcessIdMap),  
                Pid ! {"User signed out",TweeterNodePid},
                twitterUserProcessIdMapper(TweeterUserProcessMap)     
        end
    end.









