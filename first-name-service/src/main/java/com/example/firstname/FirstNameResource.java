package com.example.firstname;

import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("/first-name")
@Produces(MediaType.APPLICATION_JSON)
public class FirstNameResource {

    private static final List<String> FIRST_NAMES = List.of(
            "Max", "Anna", "Lukas", "Sofia", "Paul", "Mia", "Jonas", "Lea", "Noah", "Emma");

    @GET
    @Path("/random")
    public FirstNameResponse randomFirstName() {
        int index = ThreadLocalRandom.current().nextInt(FIRST_NAMES.size());
        return new FirstNameResponse(FIRST_NAMES.get(index));
    }
}
