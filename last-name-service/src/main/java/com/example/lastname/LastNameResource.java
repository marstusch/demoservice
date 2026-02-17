package com.example.lastname;

import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("/last-name")
@Produces(MediaType.APPLICATION_JSON)
public class LastNameResource {

    private static final List<String> LAST_NAMES = List.of(
            "Müller", "Schmidt", "Schneider", "Fischer", "Weber", "Meyer", "Wagner", "Becker", "Hoffmann", "Schulz");

    @GET
    @Path("/random")
    public LastNameResponse randomLastName() {
        int index = ThreadLocalRandom.current().nextInt(LAST_NAMES.size());
        return new LastNameResponse(LAST_NAMES.get(index));
    }
}
