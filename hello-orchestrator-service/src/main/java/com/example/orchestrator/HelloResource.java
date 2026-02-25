package com.example.orchestrator;

import com.example.orchestrator.client.FirstNameClient;
import com.example.orchestrator.client.LastNameClient;
import com.example.orchestrator.model.FirstNameResponse;
import com.example.orchestrator.model.HelloResponse;
import com.example.orchestrator.model.LastNameResponse;
import de.mtgz.logging.Logger;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.rest.client.inject.RestClient;

@Path("/hello")
@Produces(MediaType.APPLICATION_JSON)
public class HelloResource {

    @Inject
    @RestClient
    FirstNameClient firstNameClient;

    @Inject
    @RestClient
    LastNameClient lastNameClient;

    @Inject
    Logger logger;

    @GET
    public HelloResponse hello() {
        FirstNameResponse firstName = firstNameClient.randomFirstName();
        LastNameResponse lastName = lastNameClient.randomLastName();
        logger.info("firstName: " + firstName);
        logger.info("lastName: " + lastName);

        String message = "Hallo " + firstName.firstName() + " " + lastName.lastName() + "!";
        return new HelloResponse(message, firstName.firstName(), lastName.lastName());
    }
}
