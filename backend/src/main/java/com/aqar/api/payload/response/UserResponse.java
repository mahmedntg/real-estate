package com.aqar.api.payload.response;

import java.util.UUID;
import com.aqar.api.domain.Role;
import com.aqar.api.domain.User;
import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.annotation.JsonNaming;

/**
 * Public projection of a user account, without credential or verification secrets.
 *
 * @author Mohamed Sayed
 */
@Getter
@Setter
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class UserResponse {

    private UUID id;

    private String fullName;

    private String email;

    private String phone;

    private String whatsapp;

    private String facebookUrl;

    private Role role;

    private boolean emailVerified;

    /**
     * Maps a persisted user entity onto this response.
     *
     * @param user the user entity to project
     * @return the matching user response
     */
    public static UserResponse from(final User user) {
        UserResponse response = new UserResponse();
        response.setId(user.getId());
        response.setFullName(user.getFullName());
        response.setEmail(user.getEmail());
        response.setPhone(user.getPhone());
        response.setWhatsapp(user.getWhatsapp());
        response.setFacebookUrl(user.getFacebookUrl());
        response.setRole(user.getRole());
        response.setEmailVerified(user.isEmailVerified());
        return response;
    }
}
