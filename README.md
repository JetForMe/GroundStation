#  Ground Station

A Ground Station document specifies a configuration (ports to listen to, display configuration, etc.)

## Open Questions

Should a data stream port be tied to a specific document, or can any open document listen in
on any available data port? The former is simpler, the latter means you could configure different
views on the available data, but adds a lot of complexity in selecting what data a given view shows.
Probably easier to let the document own the port for now.

