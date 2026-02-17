package com.example.orchestrator.client;

import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

import com.example.orchestrator.model.LastNameResponse;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;

@Path("/last-name")
@RegisterRestClient(configKey = "last-name-service")
public interface LastNameClient {

    @GET
    @Path("/random")
    LastNameResponse randomLastName();
}
