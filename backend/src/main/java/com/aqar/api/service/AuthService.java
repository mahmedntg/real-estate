package com.aqar.api.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Locale;
import java.util.UUID;
import com.aqar.api.config.AqarProperties;
import com.aqar.api.domain.Role;
import com.aqar.api.domain.User;
import com.aqar.api.exception.ApiException;
import com.aqar.api.payload.request.LoginRequest;
import com.aqar.api.payload.request.RegisterRequest;
import com.aqar.api.payload.request.ResendRequest;
import com.aqar.api.payload.request.VerifyRequest;
import com.aqar.api.payload.response.AuthResponse;
import com.aqar.api.payload.response.RegisterResponse;
import com.aqar.api.payload.response.UserResponse;
import com.aqar.api.repository.UserRepository;
import com.aqar.api.security.JwtService;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Handles registration, email verification and credential login for local accounts.
 *
 * <p>New accounts are stored unverified and receive a short one-time code by email; a token is only
 * issued once that code has been verified.
 *
 * @author Mohamed Sayed
 */
@Service
public class AuthService {

    private static final SecureRandom CODE_RANDOM = new SecureRandom();
    private static final Duration CODE_TTL = Duration.ofMinutes(15);

    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final VerificationMailer mailer;
    private final AqarProperties config;

    /**
     * Creates the service with its repositories and collaborators.
     *
     * @param users repository used to read and store accounts
     * @param passwordEncoder encoder used to hash and check passwords
     * @param jwtService service that issues access tokens
     * @param mailer mailer used to deliver verification codes
     * @param config application configuration
     */
    public AuthService(final UserRepository users, final PasswordEncoder passwordEncoder, final JwtService jwtService,
                       final VerificationMailer mailer, final AqarProperties config) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.mailer = mailer;
        this.config = config;
    }

    /**
     * Creates an unverified account, mails a verification code and returns the pending result.
     *
     * @param request registration payload with full name, email, phone and password
     * @return registration result holding the email, a pending flag and the code when exposed
     * @throws ApiException when an account with the same email already exists
     */
    @Transactional
    public RegisterResponse register(final RegisterRequest request) {
        String email = normalizeEmail(request.getEmail());
        if (users.existsByEmailIgnoreCase(email)) {
            throw new ApiException(HttpStatus.CONFLICT, "Email already registered",
                    "An account with this email already exists");
        }

        User user = new User();
        user.setFullName(request.getFullName().trim());
        user.setEmail(email);
        user.setPhone(normalize(request.getPhone()));
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setRole(Role.USER);
        user.setEmailVerified(false);
        String code = issueVerificationCode(user);
        users.save(user);
        mailer.sendCode(email, code);
        return registrationResult(email, code);
    }

    /**
     * Checks the submitted code against the stored hash and expiry, then verifies the account.
     *
     * @param request verification payload with the email and the received code
     * @return access token and the freshly verified user view
     * @throws ApiException when the account is already verified, has no pending code, the code expired
     *                       or the submitted code does not match
     */
    @Transactional
    public AuthResponse verify(final VerifyRequest request) {
        String email = normalizeEmail(request.getEmail());
        User user = users.findByEmailIgnoreCase(email)
                .orElseThrow(() -> ApiException.notFound("User not found"));
        if (user.isEmailVerified()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Already verified",
                    "This email is already verified");
        }
        if (user.getVerificationCodeHash() == null || user.getVerificationExpiresAt() == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "No verification code",
                    "Request a new verification code");
        }
        if (user.getVerificationExpiresAt().isBefore(Instant.now())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Verification code expired",
                    "Request a new verification code");
        }
        if (!hashCode(email, request.getCode()).equals(user.getVerificationCodeHash())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid code",
                    "The verification code is incorrect");
        }

        user.setEmailVerified(true);
        user.setVerificationCodeHash(null);
        user.setVerificationExpiresAt(null);
        users.save(user);
        return authResponse(user);
    }

    /**
     * Replaces the stored verification code and mails a new one for an unverified account.
     *
     * @param request resend payload holding the account email
     * @return registration result holding the email, a pending flag and the code when exposed
     * @throws ApiException when the account is already verified
     */
    @Transactional
    public RegisterResponse resend(final ResendRequest request) {
        String email = normalizeEmail(request.getEmail());
        User user = users.findByEmailIgnoreCase(email)
                .orElseThrow(() -> ApiException.notFound("User not found"));
        if (user.isEmailVerified()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Already verified",
                    "This email is already verified");
        }
        String code = issueVerificationCode(user);
        users.save(user);
        mailer.sendCode(email, code);
        return registrationResult(email, code);
    }

    /**
     * Authenticates a verified account and issues an access token.
     *
     * <p>Unverified accounts are rejected even when the password matches.
     *
     * @param request login payload with the email and password
     * @return access token and the matching user view
     * @throws ApiException when the credentials are invalid or the email is not verified
     */
    @Transactional(readOnly = true)
    public AuthResponse login(final LoginRequest request) {
        User user = users.findByEmailIgnoreCase(request.getEmail().trim())
                .filter(candidate -> passwordEncoder.matches(request.getPassword(), candidate.getPasswordHash()))
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Invalid credentials",
                        "Email or password is incorrect"));
        if (!user.isEmailVerified()) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Email not verified",
                    "Verify your email before logging in");
        }

        return authResponse(user);
    }

    /**
     * Loads the profile of a single user.
     *
     * @param userId identifier of the user to load
     * @return view of the stored user
     */
    @Transactional(readOnly = true)
    public UserResponse me(final UUID userId) {
        User user = users.findById(userId)
                .orElseThrow(() -> ApiException.notFound("User not found"));
        return UserResponse.from(user);
    }

    /**
     * Builds the registration result returned to a pending account.
     *
     * @param email normalised email address of the pending account
     * @param code plain verification code that was mailed
     * @return registration result holding the email, a pending flag and the code when exposed
     */
    private RegisterResponse registrationResult(final String email, final String code) {
        RegisterResponse response = new RegisterResponse();
        response.setEmail(email);
        response.setVerificationRequired(true);
        response.setDevCode(devCode(code));
        return response;
    }

    /**
     * Builds the authentication result carrying a freshly issued token and the user profile.
     *
     * @param user authenticated account
     * @return authentication result with the signed token and the user profile
     */
    private AuthResponse authResponse(final User user) {
        AuthResponse response = new AuthResponse();
        response.setToken(jwtService.issue(user));
        response.setUser(UserResponse.from(user));
        return response;
    }

    /**
     * Generates a six-digit code and stores its hash and expiry on the pending account.
     *
     * @param user account that receives the verification code
     * @return the plain code that is mailed to the user
     */
    private String issueVerificationCode(final User user) {
        String code = String.format(Locale.ROOT, "%06d", CODE_RANDOM.nextInt(1_000_000));
        user.setVerificationCodeHash(hashCode(user.getEmail(), code));
        user.setVerificationExpiresAt(Instant.now().plus(CODE_TTL));
        return code;
    }

    /**
     * Exposes the plain code in the response only when the configuration allows it.
     *
     * @param code plain verification code
     * @return the code when exposure is enabled, otherwise null
     */
    private String devCode(final String code) {
        return config.mail().exposeCode() ? code : null;
    }

    /**
     * Hashes the email and code pair with SHA-256 and encodes it for storage.
     *
     * @param email email the code was issued for
     * @param code plain verification code
     * @return URL-safe Base64 hash without padding
     */
    private String hashCode(final String email, final String code) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest((email + ":" + code).getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 unavailable", e);
        }
    }

    /**
     * Trims and lowercases an email address.
     *
     * @param email raw email address
     * @return normalised email address
     */
    private String normalizeEmail(final String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    /**
     * Trims a value and maps blank strings to null.
     *
     * @param value raw value
     * @return trimmed value, or null when absent or blank
     */
    private String normalize(final String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
