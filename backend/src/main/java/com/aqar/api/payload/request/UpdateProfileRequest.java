package com.aqar.api.payload.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.annotation.JsonNaming;

/**
 * Profile update payload carrying the display name and the seller contact details.
 *
 * <p>The mobile number is intentionally absent: it only changes through the verified phone workflow.
 *
 * @author Mohamed Sayed
 */
@Getter
@Setter
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class UpdateProfileRequest {

    @NotBlank
    @Size(max = 120)
    private String fullName;

    @Pattern(regexp = "^\\+?[0-9][0-9 \\-]{6,19}$")
    private String whatsapp;

    @Size(max = 300)
    @Pattern(regexp = "^https?://.+")
    private String facebookUrl;
}
