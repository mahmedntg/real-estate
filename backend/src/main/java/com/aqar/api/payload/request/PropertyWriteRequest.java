package com.aqar.api.payload.request;

import java.math.BigDecimal;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import com.aqar.api.domain.LandKind;
import com.aqar.api.domain.ListingType;
import com.aqar.api.domain.PropertyType;
import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.annotation.JsonNaming;

/**
 * Create and update payload for a listing, including the optional land details and boundary lines.
 *
 * @author Mohamed Sayed
 */
@Getter
@Setter
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class PropertyWriteRequest {

    @Size(max = 160)
    private String titleEn;

    @Size(max = 160)
    private String titleAr;

    @Size(max = 2000)
    private String descriptionEn;

    @Size(max = 2000)
    private String descriptionAr;

    @NotNull
    private PropertyType propertyType;

    @NotNull
    private ListingType listingType;

    @NotBlank
    @Size(max = 2)
    private String countryCode;

    @NotBlank
    @Size(max = 40)
    private String governorateCode;

    @Size(max = 60)
    private String areaCode;

    @NotNull
    @DecimalMin("0.001")
    @Digits(integer = 11, fraction = 3)
    private BigDecimal price;

    @DecimalMin("0.00")
    @Digits(integer = 8, fraction = 2)
    private BigDecimal areaSqm;

    @Min(0)
    @Max(50)
    private Integer bedrooms;

    @Min(0)
    @Max(50)
    private Integer bathrooms;

    private boolean furnished;

    @DecimalMin("-90.0")
    @DecimalMax("90.0")
    private Double latitude;

    @DecimalMin("-180.0")
    @DecimalMax("180.0")
    private Double longitude;

    private LandKind landKind;

    @DecimalMin("0.01")
    @Digits(integer = 8, fraction = 2)
    private BigDecimal areaQirats;

    @Min(0)
    @Max(23)
    private Integer areaSahm;

    @DecimalMin("0.01")
    @Digits(integer = 4, fraction = 2)
    private BigDecimal northSideM;

    @DecimalMin("0.01")
    @Digits(integer = 4, fraction = 2)
    private BigDecimal southSideM;

    @DecimalMin("0.01")
    @Digits(integer = 4, fraction = 2)
    private BigDecimal eastSideM;

    @DecimalMin("0.01")
    @Digits(integer = 4, fraction = 2)
    private BigDecimal westSideM;

    @DecimalMin("0.01")
    @Digits(integer = 3, fraction = 2)
    private BigDecimal streetWidthM;

    private Boolean buildingPermit;

    private Boolean negotiable;

    @Size(max = 200)
    private String boundaryNorth;

    @Size(max = 200)
    private String boundarySouth;

    @Size(max = 200)
    private String boundaryEast;

    @Size(max = 200)
    private String boundaryWest;
}
