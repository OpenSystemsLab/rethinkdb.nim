import unittest, json
import ../rethinkdb

let r = newRethinkClient()
r.connect()
r.repl()



#discard r.table("posts").orderBy(index=r.desc("date")).run()
#discard r.table("posts").orderBy(r.desc("date")).run()
var us = &"user_id"
discard r.table("dispatch_history")
         .between(lowerKey=us,upperKey=us, leftBound="closed", rightBound="closed", index="compound_user_created")
         .orderBy(r.desc("compound_user_created"))
         .limit(int(last_x_chats)).run
