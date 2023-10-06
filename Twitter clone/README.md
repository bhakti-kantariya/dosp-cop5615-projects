Youtube demo video link - https://www.youtube.com/watch?v=WBcs7IrAY0o

**Contributors:**  
**Bhakti Armish Kantariya 
Purva Sanjay Puranik**

**Functionalities of the server/engine implemented:**  
1. Signup
2. Login
3. Subscribe/Follow
4. Tweet
5. Hashtag
6. Mentions
7. Logout
   
**Implementation:**  
1. User Interface
We have created an index.html file that contains the implementation of the
necessary HTML, CSS, and Javascript snippets used to build the user interface to
mimic the Twitter functionality. The Javascript functions connect to Cowboy’s
Websocket handlers which are part of ws_h.erl
2. WebSocket Handler
We have used Cowboy 2.9.0 which is a web server supporting
implementation of Websocket in Erlang. Cowboy works with binary strings and
hence it works well with less delay and less memory usage. Moreover, associated
with WebSocket, the initialization and various handler functions are implemented
as a part of ws_h.erl. Each handler function redirects the function request to the
backend implementation on the twitterServer created in Project 4(a).
3. Server Side
The server-side implementation of the Twitter clone is done using the actor
model paradigm in Erlang. We have different actors for handling the functionality
for Sign up, Sign-in, Signing out, Tweeting, mentioning, Subscribing/Following,
etc. This has been implemented as a part of the 4 A project.

**Cowboy set up:**  
1. To setup the cowboy project, we created a directory called websocket. Major
components of the project are priv and src directories and the erlang.mk
file.  
2. erlang.mk is the makefile which is the build system of the project consisting
of the dependencies required for the cowboy project. To get the erlang.mk,
use wget with https://erlang.mk/erlang.mk to download the file and bootstrap
the application using make command. DEP_PLUGINS in the makefile
prompts the build system about the dependencies required for cowboy.  
3. Priv directory consists of the private file of the application which are html,
css and js files. In our project we have index.html which has internal
javascript and css code.  
4. Src directory consists of the server files and the handler files for handling
routing and all the function requests sent to the websocket from UI.

_Steps to run the program:_  
1. Change directory to project: cd websocket
2. Compile & run Comboy websocket project: make run
3. Execute the application: open htps://localhost:8080 in the browser
4. Connect to websocket server:

<img width="569" alt="Screenshot 2023-09-24 at 7 11 45 PM" src="https://github.com/bhakti-kantariya/dosp-cop5615-projects/assets/36333782/7abcd850-fbab-4faa-8cb4-de3cc3d681ad">  


**Console log of demo: - Sign up, sign in, follow, tweet, hashtag, mention**
<img width="984" alt="Screenshot 2023-09-24 at 7 14 35 PM" src="https://github.com/bhakti-kantariya/dosp-cop5615-projects/assets/36333782/6653ab49-6089-4d39-b7d6-c2676742f46b">


