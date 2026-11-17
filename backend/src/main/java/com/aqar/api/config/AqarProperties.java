package com.aqar.api.config;

import java.nio.file.Path;
import java.time.Duration;
import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Strongly typed binding for the {@code aqar.*} configuration namespace.
 *
 * <p>Aggregates the JWT, media storage, S3 bucket, demo seed, CORS, mail and WhatsApp settings consumed
 * across the application.
 *
 * @author Mohamed Sayed
 */
@ConfigurationProperties(prefix = "aqar")
public record AqarProperties(Jwt jwt, Media media, S3 s3, Seed seed, Cors cors, Mail mail,
                             WhatsApp whatsapp) {

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
     * S3-compatible media storage settings.
     *
     * <p>Uploads move to the bucket when both the bucket name and the access key are set; otherwise media
     * stays in the local media directory. A blank endpoint targets AWS S3, while any other S3-compatible
     * service (Cloudflare R2, Backblaze B2, MinIO) needs its endpoint. The public URL is the base under
     * which objects are reachable to browsers, for example a CDN hostname or a public bucket URL.
     *
     * @author Mohamed Sayed
     */
    public record S3(String bucket, String region, String endpoint, String publicUrl, String accessKey,
                     String secretKey) {
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

    /**
     * WhatsApp Cloud API settings used to deliver verification codes to the mobile number.
     *
     * <p>Delivery is skipped and the mailer takes over when the token or phone number id is blank. The
     * template must be an approved Meta authentication template whose body takes the code as its only
     * parameter.
     *
     * @author Mohamed Sayed
     */
    public record WhatsApp(String token, String phoneNumberId, String template, String templateLanguage) {
    }
}
