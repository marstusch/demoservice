package com.example.orchestrator.client;

import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

import com.example.orchestrator.model.FirstNameResponse;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;

@Path("/first-name")
@RegisterRestClient(configKey = "first-name-service")
public interface FirstNameClient {

    @GET
    @Path("/random")
    FirstNameResponse randomFirstName();
}
