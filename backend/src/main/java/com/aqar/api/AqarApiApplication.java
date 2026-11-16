package com.aqar.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

/**
 * Application entry point that bootstraps the Aqar real-estate REST API with component scanning
 * and typed configuration property binding enabled.
 *
 * @author Mohamed Sayed
 */
@SpringBootApplication
@ConfigurationPropertiesScan
public class AqarApiApplication {

    public static void main(final String[] args) {
        SpringApplication.run(AqarApiApplication.class, args);
    }
}
