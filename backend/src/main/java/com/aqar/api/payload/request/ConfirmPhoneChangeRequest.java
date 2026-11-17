package com.aqar.api.payload.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.annotation.JsonNaming;

/**
 * Payload confirming a mobile number change with the code sent to the new number.
 *
 * @author Mohamed Sayed
 */
@Getter
@Setter
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class ConfirmPhoneChangeRequest {

    @NotBlank
    @Pattern(regexp = "^\\+?[0-9][0-9 \\-]{6,19}$")
    private String phone;

    @NotBlank
    @Size(min = 6, max = 6)
    private String code;
}
