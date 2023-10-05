-module(bitcoinworker).
-author("Purva Puranik").
-import(string,[concat/2, equal/2, substr/3]).
-export([start/1]).

workRouterActor() ->
	receive		
		{NumberOfZeroes,routeWork} ->
			NumOfCores = erlang:system_info(logical_processors_online),
			NumOfComputations = NumberOfZeroes*100000,
			NumOfActors = NumOfCores*500,
			workRouterActorHelperFunc(NumOfActors, NumberOfZeroes, NumOfComputations)
	end.
	
bossActor(ServerIP) ->
    {serverbossActorPID, ServerIP} ! {self(), workerAvailable},
	receive		
		{NumberOfZeroes} ->	
			WorkRouterActorPID = spawn(fun() -> workRouterActor() end),
			WorkRouterActorPID ! {NumberOfZeroes, routeWork},
			bossActor(ServerIP);
				
		{Name, Hash, WorkActorPID} ->
			{serverbossActorPID, ServerIP} ! {Name, Hash, WorkActorPID},
			bossActor(ServerIP)
	end.

workActor() ->
	receive		
		{NumberOfZeroes, NumOfComputations} ->			
			workActorHelperFunc(NumOfComputations, NumberOfZeroes, self())
	end.
	
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
	Name = concat("b.kantariya;", randomString()),
	Hash = io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256, Name))]),
	
	ExpectedZeroes = substr("0000000000",1,NumberOfZeroes),
	ActualZeroes = substr(Hash,1,NumberOfZeroes),
	
	if
		ExpectedZeroes == ActualZeroes ->
			workerbossActorPID ! {Name, Hash, WorkActorPID};
        true ->
			continue
    end,
	workActorHelperFunc(NumOfComputations-1,NumberOfZeroes, WorkActorPID).
	
start(ServerIP) ->	
	register(workerbossActorPID, spawn(fun() -> bossActor(ServerIP) end )). 