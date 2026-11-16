package com.aqar.api.payload.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.annotation.JsonNaming;

/**
 * Registration result telling the client whether email verification is pending.
 *
 * <p>The development code is only serialized when it is present.
 *
 * @author Mohamed Sayed
 */
@Getter
@Setter
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class RegisterResponse {

    private String email;

    private boolean verificationRequired;

    private String devCode;
}
