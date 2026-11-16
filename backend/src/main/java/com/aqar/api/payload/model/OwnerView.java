package com.aqar.api.payload.model;

import java.util.UUID;
import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.annotation.JsonNaming;

/**
 * Owner identity exposed on a listing, limited to the identifier and display name.
 *
 * @author Mohamed Sayed
 */
@Getter
@Setter
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class OwnerView {

    private UUID id;

    private String fullName;
}
