---- MODULE channels_fix3 ----
EXTENDS Integers, TLC, Sequences

CONSTANTS NumRoutines, NumTokens

Routines == 1..NumRoutines

(* --algorithm channels_fix3

variables
  channels = [limitCh |-> 0, found |-> {}];
  buffered = [limitCh |-> NumTokens];
  initialized = [w \in Routines |-> FALSE];
  for_loop_done = FALSE;


macro send_buffered(chan) begin
  await channels[chan] < buffered[chan];
  channels[chan] := channels[chan] + 1;
end macro;

macro receive_channel(chan) begin
  if chan \in DOMAIN buffered then
    await channels[chan] > 0;
    channels[chan] := channels[chan] - 1;
  else
    await channels[chan] /= {};
    with w \in channels[chan] do
      channels[chan] := channels[chan] \ {w}
    end with;
  end if;
end macro;

macro go(routine) begin
  initialized[routine] := TRUE;
end macro

procedure send_unbuffered(chan) begin
  DeclareSend:
    channels[chan] := channels[chan] \union {self};
  Send:
    await self \notin channels[chan];
    return;
end procedure

process goroutine \in Routines
begin
  A:
    await initialized[self];
    call send_unbuffered("found");
  B:
    receive_channel("limitCh");
end process;

process for_loop = -1
variables i = 1;
begin
  ForLoop:
    while i <= NumRoutines do
      send_buffered("limitCh");
      go(i);
      i := i + 1;
    end while;
  ForLoopDone:
    for_loop_done := TRUE;
end process;

process main = 0
variables i = NumRoutines;
begin
  Main:
    await for_loop_done;
  Get:
    while i > 0 do
      receive_channel("found");
      i := i - 1;
    end while;
end process;

end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "48c38fe5" /\ chksum(tla) = "645770f7")
\* Process variable i of process for_loop at line 56 col 11 changed to i_
CONSTANT defaultInitValue
VARIABLES channels, buffered, initialized, for_loop_done, pc, stack, chan, i_, 
          i

vars == << channels, buffered, initialized, for_loop_done, pc, stack, chan, 
           i_, i >>

ProcSet == (Routines) \cup {-1} \cup {0}

Init == (* Global variables *)
        /\ channels = [limitCh |-> 0, found |-> {}]
        /\ buffered = [limitCh |-> NumTokens]
        /\ initialized = [w \in Routines |-> FALSE]
        /\ for_loop_done = FALSE
        (* Procedure send_unbuffered *)
        /\ chan = [ self \in ProcSet |-> defaultInitValue]
        (* Process for_loop *)
        /\ i_ = 1
        (* Process main *)
        /\ i = NumRoutines
        /\ stack = [self \in ProcSet |-> << >>]
        /\ pc = [self \in ProcSet |-> CASE self \in Routines -> "A"
                                        [] self = -1 -> "ForLoop"
                                        [] self = 0 -> "Main"]

DeclareSend(self) == /\ pc[self] = "DeclareSend"
                     /\ channels' = [channels EXCEPT ![chan[self]] = channels[chan[self]] \union {self}]
                     /\ pc' = [pc EXCEPT ![self] = "Send"]
                     /\ UNCHANGED << buffered, initialized, for_loop_done, 
                                     stack, chan, i_, i >>

Send(self) == /\ pc[self] = "Send"
              /\ self \notin channels[chan[self]]
              /\ pc' = [pc EXCEPT ![self] = Head(stack[self]).pc]
              /\ chan' = [chan EXCEPT ![self] = Head(stack[self]).chan]
              /\ stack' = [stack EXCEPT ![self] = Tail(stack[self])]
              /\ UNCHANGED << channels, buffered, initialized, for_loop_done, 
                              i_, i >>

send_unbuffered(self) == DeclareSend(self) \/ Send(self)

A(self) == /\ pc[self] = "A"
           /\ initialized[self]
           /\ /\ chan' = [chan EXCEPT ![self] = "found"]
              /\ stack' = [stack EXCEPT ![self] = << [ procedure |->  "send_unbuffered",
                                                       pc        |->  "B",
                                                       chan      |->  chan[self] ] >>
                                                   \o stack[self]]
           /\ pc' = [pc EXCEPT ![self] = "DeclareSend"]
           /\ UNCHANGED << channels, buffered, initialized, for_loop_done, i_, 
                           i >>

B(self) == /\ pc[self] = "B"
           /\ IF "limitCh" \in DOMAIN buffered
                 THEN /\ channels["limitCh"] > 0
                      /\ channels' = [channels EXCEPT !["limitCh"] = channels["limitCh"] - 1]
                 ELSE /\ channels["limitCh"] /= {}
                      /\ \E w \in channels["limitCh"]:
                           channels' = [channels EXCEPT !["limitCh"] = channels["limitCh"] \ {w}]
           /\ pc' = [pc EXCEPT ![self] = "Done"]
           /\ UNCHANGED << buffered, initialized, for_loop_done, stack, chan, 
                           i_, i >>

goroutine(self) == A(self) \/ B(self)

ForLoop == /\ pc[-1] = "ForLoop"
           /\ IF i_ <= NumRoutines
                 THEN /\ channels["limitCh"] < buffered["limitCh"]
                      /\ channels' = [channels EXCEPT !["limitCh"] = channels["limitCh"] + 1]
                      /\ initialized' = [initialized EXCEPT ![i_] = TRUE]
                      /\ i_' = i_ + 1
                      /\ pc' = [pc EXCEPT ![-1] = "ForLoop"]
                 ELSE /\ pc' = [pc EXCEPT ![-1] = "ForLoopDone"]
                      /\ UNCHANGED << channels, initialized, i_ >>
           /\ UNCHANGED << buffered, for_loop_done, stack, chan, i >>

ForLoopDone == /\ pc[-1] = "ForLoopDone"
               /\ for_loop_done' = TRUE
               /\ pc' = [pc EXCEPT ![-1] = "Done"]
               /\ UNCHANGED << channels, buffered, initialized, stack, chan, 
                               i_, i >>

for_loop == ForLoop \/ ForLoopDone

Main == /\ pc[0] = "Main"
        /\ for_loop_done
        /\ pc' = [pc EXCEPT ![0] = "Get"]
        /\ UNCHANGED << channels, buffered, initialized, for_loop_done, stack, 
                        chan, i_, i >>

Get == /\ pc[0] = "Get"
       /\ IF i > 0
             THEN /\ IF "found" \in DOMAIN buffered
                        THEN /\ channels["found"] > 0
                             /\ channels' = [channels EXCEPT !["found"] = channels["found"] - 1]
                        ELSE /\ channels["found"] /= {}
                             /\ \E w \in channels["found"]:
                                  channels' = [channels EXCEPT !["found"] = channels["found"] \ {w}]
                  /\ i' = i - 1
                  /\ pc' = [pc EXCEPT ![0] = "Get"]
             ELSE /\ pc' = [pc EXCEPT ![0] = "Done"]
                  /\ UNCHANGED << channels, i >>
       /\ UNCHANGED << buffered, initialized, for_loop_done, stack, chan, i_ >>

main == Main \/ Get

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == for_loop \/ main
           \/ (\E self \in ProcSet: send_unbuffered(self))
           \/ (\E self \in Routines: goroutine(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

\* This fix separates the for loop into its own goroutine
\* allowing the main process to immediately start reading from found channel

====
