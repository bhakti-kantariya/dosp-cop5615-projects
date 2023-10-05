**Steps to run:**  

Establishing a connection between the server and remote worker:  
**Server-side**  
1. Run the following command on the server console:  
Move to server directory:  
_cd server_
2. Identify the server IP address and use it in the following command:  
_erl -name server@<serverIPaddress> -setcookie cookiename_  

**Remote Worker side**
1. Run the following command on the client console:  
Move to the working directory:  
_cd worker_  
2. Identify the remote worker IP address and use it in the following command:  
_erl -name worker@<workerIPaddress> -setcookie cookiename_
3. To check the connection, ping the server node by running the below command:  
_net_adm:ping(‘server@<serverIPaddress>')._

**Program execution:**  
1. Run the following command on the server console:  
To compile: _c(bitcoinserver)._  
To start the server: _bitcoinserver:start(N)_ (where N is the number of leading 0s)
2. Run the following command on the remote worker console:  
To compile: _c(bitcoinworker)._
To start worker participation in mining: _bitcoinworker:start(‘server@<serverIPaddress>')._

**Architecture and working of the distributed execution**  
<img width="946" alt="Screenshot 2023-10-05 at 7 52 06 PM" src="https://github.com/bhakti-kantariya/dosp-cop5615-projects/assets/36333782/9e92504b-5c9d-4eff-8167-349a73ef2acd">

1. The above diagram depicts the architecture of distributed bitcoin mining project. This is implemented using
Erlang and concepts of functional programming and actor-model to achieve the distribution of work.
2. The architecture consists of a single server and has the ability to get connected with multiple remote workers
to distribute the workload. The server can work independently on its own for mining the bitcoins and has the
ability to accommodate remote workers as and when they are available.
3. When the server is started, it intakes the leading number of zeroes, that a bitcoin should start with, and creates
a boss actor who is responsible for coordinating the actors within the server. The boss actor creates two actors
further.
_a. Work Router actor – _It is responsible for distributing the work among multiple work actors within the
server, such that the given problem is divided into multiple subproblems and each work actor is
working on that specific sub-problem independent of other work actors within the server. The router
actor which is spawned by the boss actor, determines the number of worker actors and the unit of
computation to be used, to distribute the work amongst the worker actors.
_b. Printer actor –_ It is responsible for printing the information about the bitcoins mined.
4. The work unit is dependent on the configuration of the machine (number of cores) and the number of leading
zeroes to be looked up for, in the bitcoins(hashes) generated.
5. Precisely, the number of actors created on each node is computed as
Number of Actors = Number of cores in a machine * 500.
6. Whereas, each sub-problem (finding the leading zeroes from the hashes that are being generated) which is
solved by the worker actor, is termed as the unit of computation, decided as below -
Unit of computation = Number of leading Zeroes to be looked up for * 100000.
7. The moment any actor is able to mine the bitcoin (ie. Find a hash that has a leading number of zeroes equal to
that is requested), it sends the message back to the boss actor and continues mining further if the unit of work
is not exhausted.
8. The boss actor is then responsible for redirecting the work back to the printer actor, who takes care of printing
the findings on the server.
9. When a remote worker is available, it requests the server to assign it to work. The server then passes on the
information of a leading number of zeroes, that a bitcoin should start with, to this remote worker.
10. The remote worker creates a boss actor of its own, who further takes care of spawning a work router actor
within the remote worker. This work router actor spawns individual worker actors, who then mine the bitcoins
independently.
11. Whenever the remote worker work actor is able to mine the bitcoin, it sends the message to its own worker
boss actor and continues mining further if the unit of work is not exhausted. The remote worker boss actor
then sends this update to the server boss actor, and the server boss actor takes care of forwarding the same to
its printer actor.

**Largest coin mined -**  
With one server and one remote worker, we were able to find one coin with 7 leading zeroes. A snapshot of the same
is below -
<img width="953" alt="Screenshot 2023-10-05 at 7 53 23 PM" src="https://github.com/bhakti-kantariya/dosp-cop5615-projects/assets/36333782/340dfc04-ee72-44f8-9320-cc513e5e5bce">

The result of running your program for input 4 -
<img width="934" alt="Screenshot 2023-10-05 at 7 53 26 PM" src="https://github.com/bhakti-kantariya/dosp-cop5615-projects/assets/36333782/82a01107-aafd-4263-afa7-796340d74b1f">

**Statistics obtained for computation and configuration of the machines –**  
Configuration of the machines used –  
**1. Server –**  
a. Processor - Intel(R) Core(TM) i5-10210U CPU @ 1.60GHz 2.11 GHz
b. Number of Cores: 4
c. Actors: 2000
d. Work size per actor (Given Number of Zeroes = 4) : 400000

**2. Worker –**  
a. Processor – Apple M1
b. Number of Cores: 8
c. Actors: 4000
d. Work size per actor (Given Number of Zeroes = 4): 400000
<img width="987" alt="Screenshot 2023-10-05 at 7 55 09 PM" src="https://github.com/bhakti-kantariya/dosp-cop5615-projects/assets/36333782/eca817ca-d202-4698-9807-508dfed1cd85">

3. CPU time – 13890, Real time=2216, Ratio (Real: CPU) : 6.2680. This ratio tells us how many cores were
effectively used in the computation.
4. According to our observations, the best work unit value that we found is the multiple of the number of cores
available on the machine. For example, we tried setting the number of actors to be created in multiples of 10,
50,100,500,600, time that’s of the number of cores. And we found that the best work unit was when the
number of workers was 500*Number of cores available on the machine.

**The largest number of working machines you were able to run your code with. –**  
We were able to run our code with two machines, one being a server and another being worker.
