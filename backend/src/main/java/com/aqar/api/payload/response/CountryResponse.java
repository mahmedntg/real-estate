package com.aqar.api.payload.response;

import java.util.List;
import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.annotation.JsonNaming;

/**
 * Country view with its bilingual names, currency details, marketing taglines and governorate tree.
 *
 * @author Mohamed Sayed
 */
@Getter
@Setter
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class CountryResponse {

    private String code;

    private String nameEn;

    private String nameAr;

    private String currencyCode;

    private String currencySymbolEn;

    private String currencySymbolAr;

    private String taglineEn;

    private String taglineAr;

    private List<GovernorateResponse> governorates;
}
