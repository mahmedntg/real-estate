package com.aqar.api.payload.model;

import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.annotation.JsonNaming;

/**
 * Seller contact details exposed on a listing so buyers can reach the owner directly.
 *
 * @author Mohamed Sayed
 */
@Getter
@Setter
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class ContactView {

    private String phone;

    private String whatsapp;

    private String facebookUrl;
}
