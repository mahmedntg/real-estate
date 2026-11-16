package com.aqar.api.config;

import java.nio.file.Path;
import java.time.Duration;
import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Strongly typed binding for the {@code aqar.*} configuration namespace.
 *
 * <p>Aggregates the JWT, media storage, demo seed, CORS and mail settings consumed across the application.
 *
 * @author Mohamed Sayed
 */
@ConfigurationProperties(prefix = "aqar")
public record AqarProperties(Jwt jwt, Media media, Seed seed, Cors cors, Mail mail) {

    /**
     * Access-token settings holding the HMAC signing secret and the token time to live.
     *
     * @author Mohamed Sayed
     */
    public record Jwt(String secret, Duration ttl) {
    }

    /**
     * Local media storage settings holding the root directory for uploaded images and videos.
     *
     * @author Mohamed Sayed
     */
    public record Media(Path dir) {
    }

    /**
     * Demo data seeding settings: the master switch plus the admin and demo account credentials.
     *
     * @author Mohamed Sayed
     */
    public record Seed(boolean enabled, String adminEmail, String adminPassword, String demoPassword) {
    }

    /**
     * CORS settings listing the origin patterns allowed to call the API from a browser.
     *
     * @author Mohamed Sayed
     */
    public record Cors(List<String> allowedOrigins) {
    }

    /**
     * Outbound SMTP settings used to deliver registration verification codes.
     *
     * <p>The {@code exposeCode} flag decides whether the generated code is also returned to the client.
     *
     * @author Mohamed Sayed
     */
    public record Mail(boolean exposeCode, String host, int port, String username, String password, String from) {
    }
}
