-module(bitcoinserver).
-author("Purva Puranik").
-import(string,[concat/2, equal/2,substr/3]).
-import(timer,[send_after/3]).
-export([start/1]).

workRouterActor() ->
	receive		
		{NumberOfZeroes,routeWork} ->
			NumOfCores = erlang:system_info(logical_processors_online),
			NumOfComputations = NumberOfZeroes*100000,
			NumOfActors = NumOfCores*500,
			workRouterActorHelperFunc(NumOfActors, NumberOfZeroes, NumOfComputations)
	end.
	
bossActor(NumberOfZeroes) ->
	receive		
		{NumberOfZeroes} ->			
			WorkRouterActorPID = spawn(fun() -> workRouterActor() end),
			WorkRouterActorPID ! {NumberOfZeroes, routeWork},
			bossActor(NumberOfZeroes);
		
		{WorkerCalling, workerAvailable} -> 
			WorkerCalling ! {NumberOfZeroes},
			bossActor(NumberOfZeroes);
			
		{Name, Hash, WorkActorPID} ->	
			ServerprinterActorPID = serverprinterActorPID,
			ServerprinterActorPID ! {Name, Hash, WorkActorPID},
			bossActor(NumberOfZeroes);	

		{calculate, Node} ->
			io:fwrite("Here"),
			ServerprinterActorPID = serverprinterActorPID,
			ServerprinterActorPID ! {calculate, Node},
			bossActor(NumberOfZeroes)
	end.

workActor() ->
	receive		
		{NumberOfZeroes, NumOfComputations} ->			
			workActorHelperFunc(NumOfComputations, NumberOfZeroes, self())
	end.
	
printerActor() ->
	receive
		{Name, Hash, WorkActorPID} ->
			io:format("~s\t\t~s\t~p~n",[Name, Hash, WorkActorPID])
	end,
	printerActor().
	
workRouterActorHelperFunc(0, NumberOfZeroes, NumOfComputations) ->
	ok;

workRouterActorHelperFunc(NumOfActors, NumberOfZeroes, NumOfComputations) ->
	WorkActorPID = spawn(fun() -> workActor() end),
	WorkActorPID ! {NumberOfZeroes, NumOfComputations},
	workRouterActorHelperFunc(NumOfActors-1,NumberOfZeroes,NumOfComputations).
	
randomString() ->
	lists:foldl(fun(_, Acc) -> [lists:nth(rand:uniform(36), "abcdefghijklmnopqrstuvwxyz1234567890")] ++ Acc
              end, [], lists:seq(1, 15)).

workActorHelperFunc(0, NumberOfZeroes, WorkActorPID) ->
	ok;

workActorHelperFunc(NumOfComputations, NumberOfZeroes, WorkActorPID) ->
	Name = concat("puranikpurva;", randomString()),
	Hash = io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256, Name))]),
	
	ExpectedZeroes = substr("0000000000",1,NumberOfZeroes),
	ActualZeroes = substr(Hash,1,NumberOfZeroes),
	
	if
		ExpectedZeroes == ActualZeroes ->	
			ServerbossActorPID = serverbossActorPID,
			ServerbossActorPID ! {Name, Hash, WorkActorPID};
        true ->
			continue
    end,
	workActorHelperFunc(NumOfComputations-1,NumberOfZeroes, WorkActorPID).

timerActor() ->
	receive
		{calculate, Node} ->
			io:format("~s\t~n",[Node]),
			{_, Time1} = statistics(runtime),
			U1 = Time1,
			{_, Time2} = statistics(wall_clock),
			U2 = Time2,
			Ratio = U1/U2,
			io:format("-------------------CPU time: ~p\t\t Real Time: ~p \t\t Ratio (Real:CPU): ~p-------------------\n",[U1, U2, Ratio])
	end,
	timerActor().
	
start(NumberOfZeroes) ->	
	register(serverprinterActorPID, spawn(fun() -> printerActor() end )),	
	register(serverbossActorPID, spawn(fun() -> bossActor(NumberOfZeroes) end )),	
	register(timerActorPID, spawn(fun() -> timerActor() end)),	
	serverbossActorPID !{NumberOfZeroes},
	send_after(5000, timerActorPID, {calculate, "Server"}).
	