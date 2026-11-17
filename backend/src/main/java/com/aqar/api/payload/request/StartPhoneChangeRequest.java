package com.aqar.api.payload.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.annotation.JsonNaming;

/**
 * Payload requesting a verification code for a new mobile number.
 *
 * @author Mohamed Sayed
 */
@Getter
@Setter
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class StartPhoneChangeRequest {

    @NotBlank
    @Pattern(regexp = "^\\+?[0-9][0-9 \\-]{6,19}$")
    private String phone;
}
