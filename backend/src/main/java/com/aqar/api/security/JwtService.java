package com.aqar.api.security;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import com.aqar.api.config.AqarProperties;
import com.aqar.api.domain.User;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.stereotype.Service;

/**
 * Issues and validates the HS256 access tokens used by the stateless security configuration.
 *
 * <p>Tokens are signed with the configured secret, carry the user identifier as subject with email, name and role
 * claims, and are validated against the {@code aqar-api} issuer.
 *
 * @author Mohamed Sayed
 */
@Service
public final class JwtService {

    private static final String ISSUER = "aqar-api";

    private final SecretKey key;
    private final Duration ttl;
    private final JwtDecoder decoder;

    /**
     * Builds the signing key, the token time to live and the validating decoder from the bound configuration.
     *
     * @param properties the bound application properties holding the JWT secret and time to live
     * @throws IllegalStateException when the configured secret is shorter than 32 bytes
     */
    public JwtService(final AqarProperties properties) {
        byte[] secret = properties.jwt().secret().getBytes(StandardCharsets.UTF_8);
        if (secret.length < 32) {
            throw new IllegalStateException("aqar.jwt.secret must be at least 32 bytes long");
        }
        this.key = new SecretKeySpec(secret, "HmacSHA256");
        this.ttl = properties.jwt().ttl();

        NimbusJwtDecoder nimbusDecoder = NimbusJwtDecoder.withSecretKey(key)
                .macAlgorithm(MacAlgorithm.HS256)
                .build();
        nimbusDecoder.setJwtValidator(JwtValidators.createDefaultWithIssuer(ISSUER));
        this.decoder = nimbusDecoder;
    }

    /**
     * Issues a signed access token for the given user.
     *
     * @param user the authenticated user whose identifier and profile claims are encoded in the token
     * @return the serialized signed JWT
     * @throws IllegalStateException when the token cannot be signed with the configured key
     */
    public String issue(final User user) {
        Instant now = Instant.now();
        JWTClaimsSet claims = new JWTClaimsSet.Builder()
                .issuer(ISSUER)
                .subject(user.getId().toString())
                .claim("email", user.getEmail())
                .claim("name", user.getFullName())
                .claim("role", user.getRole().name())
                .issueTime(Date.from(now))
                .expirationTime(Date.from(now.plus(ttl)))
                .build();

        SignedJWT jwt = new SignedJWT(new JWSHeader(JWSAlgorithm.HS256), claims);
        try {
            jwt.sign(new MACSigner(key));
        } catch (JOSEException e) {
            throw new IllegalStateException("Unable to sign access token", e);
        }
        return jwt.serialize();
    }

    public JwtDecoder decoder() {
        return decoder;
    }
}
