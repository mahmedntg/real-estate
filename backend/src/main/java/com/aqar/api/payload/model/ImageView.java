package com.aqar.api.payload.model;

import java.util.UUID;
import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.annotation.JsonNaming;

/**
 * Property image reference holding the stored image identifier and the URL that serves it.
 *
 * @author Mohamed Sayed
 */
@Getter
@Setter
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class ImageView {

    private UUID id;

    private String url;
}
