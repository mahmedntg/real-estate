package com.aqar.api.payload.response;

import java.util.List;
import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.annotation.JsonNaming;

/**
 * Governorate view with its stable code, bilingual names and the areas it contains.
 *
 * @author Mohamed Sayed
 */
@Getter
@Setter
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class GovernorateResponse {

    private String code;

    private String nameEn;

    private String nameAr;

    private List<AreaResponse> areas;
}
