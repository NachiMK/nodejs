These are the functions invoked by the HTTP endpoints and should be very thin and generally call out to the controllers layer.
This allows the functions to be more testable and reusable.