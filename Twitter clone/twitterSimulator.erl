-module(twitterSimulator).
-export([startSimulator/0, signupSimulator/2]).
-import(twitterServer,[signupHandler/0]).

signupSimulator(0, _) ->
    ok;

signupSimulator(NumberOfUser, Subscriber) ->
    twitterServer:signupHandler(),
    UserList =  twitterServer:getTwitterUsers(),
    twitterServer:subscribeToUserHandler(UserList,Subscriber),
    signupSimulator(NumberOfUser-1, Subscriber+1).

startSimulator() ->
    {ok, NumberOfUser} =  io:read("Number of users : "),
    io:format("Number OfUser = ~p\n",[NumberOfUser]),
    twitterSimulator:signupSimulator(NumberOfUser, 0).