package com.aqar.api.payload.response;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import com.aqar.api.domain.LandKind;
import com.aqar.api.domain.ListingType;
import com.aqar.api.domain.PropertyType;
import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.annotation.JsonNaming;

/**
 * Compact listing view used for cards and search results.
 *
 * <p>Carries the cover image and the caller-specific favorite flag instead of the full listing detail.
 *
 * @author Mohamed Sayed
 */
@Getter
@Setter
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class PropertySummaryResponse {

    private UUID id;

    private String titleEn;

    private String titleAr;

    private PropertyType propertyType;

    private ListingType listingType;

    private String countryCode;

    private String governorateCode;

    private String areaCode;

    private BigDecimal price;

    private BigDecimal areaSqm;

    private Integer bedrooms;

    private Integer bathrooms;

    private boolean furnished;

    private String coverImage;

    private boolean favorite;

    private Instant createdAt;

    private LandKind landKind;

    private BigDecimal areaQirats;

    private Integer areaSahm;

    private boolean negotiable;
}
