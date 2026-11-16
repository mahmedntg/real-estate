package com.aqar.api.web;

import jakarta.validation.Valid;
import com.aqar.api.payload.request.LoginRequest;
import com.aqar.api.payload.request.RegisterRequest;
import com.aqar.api.payload.request.ResendRequest;
import com.aqar.api.payload.request.VerifyRequest;
import com.aqar.api.payload.response.AuthResponse;
import com.aqar.api.payload.response.RegisterResponse;
import com.aqar.api.payload.response.UserResponse;
import com.aqar.api.security.CurrentUser;
import com.aqar.api.service.AuthService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Exposes the authentication endpoints for registration, email verification and login.
 *
 * @author Mohamed Sayed
 */
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;
    private final CurrentUser currentUser;

    /**
     * Creates the controller with its authentication collaborators.
     *
     * @param authService service performing registration and login
     * @param currentUser resolver for the authenticated caller
     */
    public AuthController(final AuthService authService, final CurrentUser currentUser) {
        this.authService = authService;
        this.currentUser = currentUser;
    }

    /**
     * Registers a new account and sends a verification code to the supplied email.
     *
     * @param request registration payload holding full name, email, phone and password
     * @return registered email, verification-pending flag and development code when exposed
     */
    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public RegisterResponse register(@Valid @RequestBody final RegisterRequest request) {
        return authService.register(request);
    }

    /**
     * Verifies the emailed code and returns an access token.
     *
     * @param request email address and verification code
     * @return issued token together with the verified user profile
     */
    @PostMapping("/verify")
    public AuthResponse verify(@Valid @RequestBody final VerifyRequest request) {
        return authService.verify(request);
    }

    /**
     * Issues a fresh verification code for an account that is not verified yet.
     *
     * @param request email address requesting a new code
     * @return registered email, verification-pending flag and development code when exposed
     */
    @PostMapping("/resend")
    public RegisterResponse resend(@Valid @RequestBody final ResendRequest request) {
        return authService.resend(request);
    }

    /**
     * Authenticates email and password for a verified account.
     *
     * @param request email address and password
     * @return issued token together with the authenticated user profile
     */
    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody final LoginRequest request) {
        return authService.login(request);
    }

    /**
     * Returns the profile of the authenticated caller.
     *
     * @return profile of the caller resolved from the access token
     */
    @GetMapping("/me")
    public UserResponse me() {
        return authService.me(currentUser.requireId());
    }
}
