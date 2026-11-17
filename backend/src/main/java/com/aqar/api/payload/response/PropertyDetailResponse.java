package com.aqar.api.payload.response;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import com.aqar.api.domain.LandKind;
import com.aqar.api.domain.ListingType;
import com.aqar.api.domain.PropertyType;
import com.aqar.api.payload.model.ImageView;
import com.aqar.api.payload.model.OwnerView;
import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.annotation.JsonNaming;

/**
 * Full listing view with images, video, owner, coordinates, land details, boundary lines and the
 * caller-specific favorite and ownership flags.
 *
 * @author Mohamed Sayed
 */
@Getter
@Setter
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class PropertyDetailResponse {

    private UUID id;

    private String titleEn;

    private String titleAr;

    private String descriptionEn;

    private String descriptionAr;

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

    private Double latitude;

    private Double longitude;

    private List<ImageView> images;

    private String videoUrl;

    private OwnerView owner;

    private boolean favorite;

    private boolean mine;

    private Instant createdAt;

    private Instant updatedAt;

    private LandKind landKind;

    private BigDecimal areaQirats;

    private BigDecimal northSideM;

    private BigDecimal southSideM;

    private BigDecimal eastSideM;

    private BigDecimal westSideM;

    private BigDecimal streetWidthM;

    private Boolean buildingPermit;

    private String boundaryNorth;

    private String boundarySouth;

    private String boundaryEast;

    private String boundaryWest;

    private boolean negotiable;
}
