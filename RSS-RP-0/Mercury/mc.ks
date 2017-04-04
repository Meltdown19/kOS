set ship:control:pilotmainthrottle to 0.
{
  function mission_runner {
    parameter sequence, events is lex().
    local runmode is 0. local done is 0.
    local mission is lex(
      "add_event", add_event@,
      "remove_event", remove_event@,
      "next", next@,
      "switch_to", switch_to@,
      "runmode", report_runmode@,
      "terminate", terminate@
    ).
    if core:volume:exists("mission.runmode") {
      local last_mode is core:volume:open("mission.runmode"):readall():string.
      local n is indexof(sequence, last_mode).
      if n <> -1 update_runmode(n / 2).
    }
    until done {
      sequence[runmode * 2 + 1](mission).
      for event in events:values event(mission).
      wait 0.01.
    }
    if core:volume:exists("mission.runmode")
      core:volume:delete("mission.runmode").
    function update_runmode {
      parameter n.
      if not core:volume:exists("mission.runmode")
        core:volume:create("mission.runmode").
      local file is core:volume:open("mission.runmode").
      file:clear().
      file:write(sequence[2 * n]).
      set runmode to n.
    }
    function indexof {
      parameter _list, item. local i is 0.
      for el in _list {
        if el = item return i.
        set i to i + 1.
      }
      return -1.
    }
    function add_event {
      parameter name, delegate.
      set events[name] to delegate.
    }
    function remove_event {
      parameter name.
      events:remove(name).
    }
    function next {
      update_runmode(runmode + 1).
    }
    function switch_to {
      parameter name.
      update_runmode(indexof(sequence, name) / 2).
    }
    function report_runmode {
      return sequence[runmode * 2].
    }
    function terminate {
      set done to 1.
    }
  }
  global run_mission is mission_runner@.
}
