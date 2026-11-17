package com.aqar.api.config;

import java.io.IOException;
import java.util.List;
import jakarta.servlet.http.HttpServletResponse;
import com.aqar.api.security.JwtService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

/**
 * Spring Security configuration for the stateless, JWT-protected REST API.
 *
 * <p>Registers the filter chain, the CORS source, the JWT role converter and the BCrypt password encoder used by
 * the authentication service.
 *
 * @author Mohamed Sayed
 */
@Configuration
public class SecurityConfig {

    /**
     * Defines the stateless security filter chain used by every request.
     *
     * <p>CSRF is disabled, sessions are never created, anonymous access is limited to reading listings and
     * locations plus the auth, media, error and API documentation endpoints, and every other request must carry a
     * valid bearer token. Missing or insufficient credentials are answered with Problem Details JSON bodies.
     *
     * @param http the security builder to configure
     * @param jwtService supplies the JWT decoder used to validate bearer tokens
     * @param corsConfigurationSource the CORS rules applied to incoming requests
     * @return the built security filter chain
     * @throws Exception if the filter chain cannot be built
     */
    @Bean
    SecurityFilterChain securityFilterChain(final HttpSecurity http, final JwtService jwtService,
                                            final CorsConfigurationSource corsConfigurationSource) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .cors(cors -> cors.configurationSource(corsConfigurationSource))
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.GET, "/api/v1/properties/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/v1/locations").permitAll()
                        .requestMatchers("/api/v1/auth/**", "/media/**", "/error", "/actuator/health",
                                "/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html").permitAll()
                        .anyRequest().authenticated())
                .oauth2ResourceServer(oauth -> oauth.jwt(jwt -> jwt
                        .decoder(jwtService.decoder())
                        .jwtAuthenticationConverter(jwtAuthenticationConverter())))
                .exceptionHandling(exceptions -> exceptions
                        .authenticationEntryPoint((request, response, ex) ->
                                writeProblem(response, 401, "Unauthorized", "Authentication is required"))
                        .accessDeniedHandler((request, response, ex) ->
                                writeProblem(response, 403, "Forbidden", "You do not have access to this resource")));
        return http.build();
    }

    /**
     * Creates a converter that turns the {@code role} claim of an access token into a single
     * {@code ROLE_}-prefixed authority.
     *
     * <p>Tokens without a role claim produce an empty authority list.
     *
     * @return the configured JWT authentication converter
     */
    private JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(jwt -> {
            String role = jwt.getClaimAsString("role");
            if (role == null || role.isBlank()) {
                return List.of();
            }
            return List.<GrantedAuthority>of(new SimpleGrantedAuthority("ROLE_" + role));
        });
        return converter;
    }

    /**
     * Writes a Problem Details JSON body carrying the given status, title and detail.
     *
     * @param response the servlet response to write to
     * @param status the HTTP status code to set on the response
     * @param title the problem title
     * @param detail the human readable problem detail
     * @throws IOException if the response writer cannot be obtained or written to
     */
    private void writeProblem(final HttpServletResponse response, final int status, final String title, final String detail)
            throws IOException {
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        response.getWriter().write(
                "{\"title\":\"" + title + "\",\"status\":" + status + ",\"detail\":\"" + detail + "\"}");
    }

    /**
     * Builds the CORS configuration source from the configured allowed origin patterns.
     *
     * <p>Falls back to localhost patterns when no origins are configured, allows the REST verbs plus OPTIONS,
     * accepts any request header and caches the preflight response for one hour.
     *
     * @param properties the bound application properties holding the allowed origin patterns
     * @return a CORS source that applies the configuration to every path
     */
    @Bean
    CorsConfigurationSource corsConfigurationSource(final AqarProperties properties) {
        List<String> origins = properties.cors() != null && properties.cors().allowedOrigins() != null
                ? properties.cors().allowedOrigins()
                : List.of("http://localhost:*", "http://127.0.0.1:*");

        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(origins);
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
