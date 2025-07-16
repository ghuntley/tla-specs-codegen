---- MODULE channels_fix1 ----
EXTENDS Integers, TLC, Sequences

CONSTANTS NumRoutines, NumTokens

Routines == 1..NumRoutines

(* --algorithm channels_fix1

variables
  channels = [limitCh |-> 0, found |-> {}];
  buffered = [limitCh |-> NumTokens];
  initialized = [w \in Routines |-> FALSE];


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
    send_buffered("limitCh");
    call send_unbuffered("found");
  B:
    receive_channel("limitCh");
end process;

process main = 0
variables i = 1;
begin
  Main:
    while i <= NumRoutines do
      go(i);
      i := i + 1;
    end while;
  Get:
    while i > 1 do
      i := i - 1;
      receive_channel("found");
    end while;
end process;

end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "28b299ea" /\ chksum(tla) = "b3c0318f")
CONSTANT defaultInitValue
VARIABLES channels, buffered, initialized, pc, stack, chan, i

vars == << channels, buffered, initialized, pc, stack, chan, i >>

ProcSet == (Routines) \cup {0}

Init == (* Global variables *)
        /\ channels = [limitCh |-> 0, found |-> {}]
        /\ buffered = [limitCh |-> NumTokens]
        /\ initialized = [w \in Routines |-> FALSE]
        (* Procedure send_unbuffered *)
        /\ chan = [ self \in ProcSet |-> defaultInitValue]
        (* Process main *)
        /\ i = 1
        /\ stack = [self \in ProcSet |-> << >>]
        /\ pc = [self \in ProcSet |-> CASE self \in Routines -> "A"
                                        [] self = 0 -> "Main"]

DeclareSend(self) == /\ pc[self] = "DeclareSend"
                     /\ channels' = [channels EXCEPT ![chan[self]] = channels[chan[self]] \union {self}]
                     /\ pc' = [pc EXCEPT ![self] = "Send"]
                     /\ UNCHANGED << buffered, initialized, stack, chan, i >>

Send(self) == /\ pc[self] = "Send"
              /\ self \notin channels[chan[self]]
              /\ pc' = [pc EXCEPT ![self] = Head(stack[self]).pc]
              /\ chan' = [chan EXCEPT ![self] = Head(stack[self]).chan]
              /\ stack' = [stack EXCEPT ![self] = Tail(stack[self])]
              /\ UNCHANGED << channels, buffered, initialized, i >>

send_unbuffered(self) == DeclareSend(self) \/ Send(self)

A(self) == /\ pc[self] = "A"
           /\ initialized[self]
           /\ channels["limitCh"] < buffered["limitCh"]
           /\ channels' = [channels EXCEPT !["limitCh"] = channels["limitCh"] + 1]
           /\ /\ chan' = [chan EXCEPT ![self] = "found"]
              /\ stack' = [stack EXCEPT ![self] = << [ procedure |->  "send_unbuffered",
                                                       pc        |->  "B",
                                                       chan      |->  chan[self] ] >>
                                                   \o stack[self]]
           /\ pc' = [pc EXCEPT ![self] = "DeclareSend"]
           /\ UNCHANGED << buffered, initialized, i >>

B(self) == /\ pc[self] = "B"
           /\ IF "limitCh" \in DOMAIN buffered
                 THEN /\ channels["limitCh"] > 0
                      /\ channels' = [channels EXCEPT !["limitCh"] = channels["limitCh"] - 1]
                 ELSE /\ channels["limitCh"] /= {}
                      /\ \E w \in channels["limitCh"]:
                           channels' = [channels EXCEPT !["limitCh"] = channels["limitCh"] \ {w}]
           /\ pc' = [pc EXCEPT ![self] = "Done"]
           /\ UNCHANGED << buffered, initialized, stack, chan, i >>

goroutine(self) == A(self) \/ B(self)

Main == /\ pc[0] = "Main"
        /\ IF i <= NumRoutines
              THEN /\ initialized' = [initialized EXCEPT ![i] = TRUE]
                   /\ i' = i + 1
                   /\ pc' = [pc EXCEPT ![0] = "Main"]
              ELSE /\ pc' = [pc EXCEPT ![0] = "Get"]
                   /\ UNCHANGED << initialized, i >>
        /\ UNCHANGED << channels, buffered, stack, chan >>

Get == /\ pc[0] = "Get"
       /\ IF i > 1
             THEN /\ i' = i - 1
                  /\ IF "found" \in DOMAIN buffered
                        THEN /\ channels["found"] > 0
                             /\ channels' = [channels EXCEPT !["found"] = channels["found"] - 1]
                        ELSE /\ channels["found"] /= {}
                             /\ \E w \in channels["found"]:
                                  channels' = [channels EXCEPT !["found"] = channels["found"] \ {w}]
                  /\ pc' = [pc EXCEPT ![0] = "Get"]
             ELSE /\ pc' = [pc EXCEPT ![0] = "Done"]
                  /\ UNCHANGED << channels, i >>
       /\ UNCHANGED << buffered, initialized, stack, chan >>

main == Main \/ Get

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == main
           \/ (\E self \in ProcSet: send_unbuffered(self))
           \/ (\E self \in Routines: goroutine(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

\* This fix moves the token acquisition to the goroutines themselves
\* instead of the main process doing it before spawning goroutines

====
