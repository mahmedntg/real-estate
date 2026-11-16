package com.aqar.api.security;

import java.util.Optional;
import java.util.UUID;
import com.aqar.api.exception.ApiException;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;

/**
 * Resolves the authenticated caller from the JWT held in the Spring Security context.
 *
 * <p>Offers an optional and a mandatory accessor for the caller identifier plus the administrator role check used
 * to authorise privileged actions.
 *
 * @author Mohamed Sayed
 */
@Component
public class CurrentUser {

    /**
     * Reads the caller identifier from the subject of the current access token.
     *
     * <p>Anonymous requests, non JWT authentications and tokens with a blank subject yield an empty result.
     *
     * @return caller identifier, or empty when the request is not authenticated with a subject
     */
    public Optional<UUID> id() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication instanceof JwtAuthenticationToken token && authentication.isAuthenticated()) {
            String subject = token.getToken().getSubject();
            if (subject != null && !subject.isBlank()) {
                return Optional.of(UUID.fromString(subject));
            }
        }
        return Optional.empty();
    }

    /**
     * Returns the caller identifier or rejects the request with an unauthorized error.
     *
     * @return caller identifier of the authenticated request
     */
    public UUID requireId() {
        return id().orElseThrow(() ->
                new ApiException(HttpStatus.UNAUTHORIZED, "Unauthorized", "Sign in to continue"));
    }

    /**
     * Checks whether the current authentication carries the administrator authority.
     *
     * @return true when the caller holds the administrator role, false otherwise
     */
    public boolean isAdmin() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null) {
            return false;
        }
        return authentication.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .anyMatch("ROLE_ADMIN"::equals);
    }
}
