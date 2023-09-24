-module(ws_h).

-export([init/2]).
-export([websocket_init/1]).
-export([websocket_handle/2]).
-export([websocket_info/2]).

init(Req, Opts) ->
	{cowboy_websocket, Req, Opts}.

websocket_init(State) ->
	erlang:start_timer(1000, self(), <<"Hello, welcome to Twitter Clone!">>),
	{[], State}.

websocket_handle({text, Msg}, State) ->
	Tokens = string:tokens(binary_to_list(Msg), ">>>>"),
	Condition = lists:nth(1, Tokens),
	io:fwrite("Condition ~p",[Condition]),
	io:fwrite("Msg ~p",[Msg]),
	case Condition of 
		"SignIn" -> 
			Uname = list_to_binary(lists:nth(2, Tokens)),
			UserId = list_to_atom(lists:nth(2, Tokens)),
			Response = twitterServer:signinHandler(UserId,lists:nth(3, Tokens)),
			Key = lists:nth(1, Response),
			if
				Key == "Success" ->
					{[{text, << "Login successful for ",Uname/binary>>}], State};
				true ->
					{[{text,<<"Incorrect username/password. Try logging in again.">>}], State}
			end;
		"SignUp" -> 
			Uname = list_to_binary(lists:nth(2, Tokens)),
			UserId = list_to_atom(lists:nth(2, Tokens)),
			Response = twitterServer:signupHandler(UserId,lists:nth(3, Tokens)),
			Key = lists:nth(1, Response),
			if
				Key == "Success" ->
					{[{text, << "Registered username: ",Uname/binary>>}], State};
				true ->
					{[{text, << Uname/binary, " already registered, try logging in.">>}], State}
			end;
		"FollowUser" ->
			UserToFollow = list_to_atom(lists:nth(3, Tokens)),
			Response = list_to_binary(twitterServer:subscribeHandler(UserToFollow)),
			{[{text,<<Response/binary>>}], State};
		"SendTweet" ->
			Message = lists:nth(3, Tokens),
			Response = list_to_binary(twitterServer:sendTweetHandler(Message)),
			{[{text,<<Response/binary>>}], State};
		"ViewMessages" ->
			Username = list_to_atom(lists:nth(2, Tokens)),
			Response = twitterServer:fetchTweets(Username),
			Tweets = lists:flatten(io_lib:format("~p", [Response])),
			TweetsBinary = list_to_binary(Tweets),
			{[{text,<<TweetsBinary/binary>>}], State};
		"SearchHashtag" ->
			Message = lists:nth(2, Tokens),
			Response = twitterServer:getTweeterhashtag(Message),
			Tweets = lists:flatten(io_lib:format("~p", [Response])),
			TweetsBinary = list_to_binary(Tweets),
			{[{text,<<TweetsBinary/binary>>}], State};
		"SearchMention" ->
			Response = twitterServer:getmentionedUsers(),
			Tweets = lists:flatten(io_lib:format("~p", [Response])),
			TweetsBinary = list_to_binary(Tweets),
			{[{text,<<TweetsBinary/binary>>}], State}
	end;
websocket_handle(_Data, State) ->
	{[], State}.

websocket_info({timeout, _Ref, Msg}, State) ->
	erlang:start_timer(10000000000, self(), <<"Connected.">>),
	{[{text, Msg}], State};
websocket_info(_Info, State) ->
	{[], State}.
