package com.aqar.api.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Spring configuration that describes the Aqar API to swagger-ui and the OpenAPI document endpoint.
 *
 * @author Mohamed Sayed
 */
@Configuration
public class OpenApiConfig {

    /**
     * Builds the OpenAPI document exposed at {@code /v3/api-docs}.
     *
     * <p>Declares the API title, version and description, and registers a bearer JWT security scheme that is
     * applied to every operation.
     *
     * @return the configured OpenAPI document
     */
    @Bean
    OpenAPI aqarOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("Aqar API")
                        .version("0.1.0")
                        .description("Real-estate marketplace API for the Aqar Flutter app"))
                .components(new Components().addSecuritySchemes("bearerAuth",
                        new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")))
                .addSecurityItem(new SecurityRequirement().addList("bearerAuth"));
    }
}
