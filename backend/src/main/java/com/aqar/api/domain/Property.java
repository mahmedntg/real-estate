package com.aqar.api.domain;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

/**
 * JPA entity mapped to the properties table, holding the bilingual listing content, property and
 * listing types, location, price, land measurements and boundary lines, media, the owner and the
 * creation and update timestamps.
 *
 * @author Mohamed Sayed
 */
@Entity
@Table(name = "properties")
public class Property {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "owner_id", nullable = false)
    private User owner;

    @Column(name = "title_en", nullable = false, length = 160)
    private String titleEn;

    @Column(name = "title_ar", nullable = false, length = 160)
    private String titleAr;

    @Column(name = "description_en", nullable = false, length = 2000)
    private String descriptionEn;

    @Column(name = "description_ar", nullable = false, length = 2000)
    private String descriptionAr;

    @Enumerated(EnumType.STRING)
    @Column(name = "property_type", nullable = false, length = 20)
    private PropertyType propertyType;

    @Enumerated(EnumType.STRING)
    @Column(name = "listing_type", nullable = false, length = 20)
    private ListingType listingType;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "governorate_id", nullable = false)
    private Governorate governorate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "area_id")
    private Area area;

    @Column(nullable = false, precision = 14, scale = 3)
    private BigDecimal price;

    @Column(name = "area_sqm", precision = 10, scale = 2)
    private BigDecimal areaSqm;

    private Integer bedrooms;

    private Integer bathrooms;

    @Column(nullable = false)
    private boolean furnished;

    @Enumerated(EnumType.STRING)
    @Column(name = "land_kind", length = 20)
    private LandKind landKind;

    @Column(name = "area_qirats", precision = 10, scale = 2)
    private BigDecimal areaQirats;

    @Column(name = "north_side_m", precision = 6, scale = 2)
    private BigDecimal northSideM;

    @Column(name = "south_side_m", precision = 6, scale = 2)
    private BigDecimal southSideM;

    @Column(name = "east_side_m", precision = 6, scale = 2)
    private BigDecimal eastSideM;

    @Column(name = "west_side_m", precision = 6, scale = 2)
    private BigDecimal westSideM;

    @Column(name = "street_width_m", precision = 5, scale = 2)
    private BigDecimal streetWidthM;

    @Column(name = "building_permit")
    private Boolean buildingPermit;

    @Column(name = "boundary_north", length = 200)
    private String boundaryNorth;

    @Column(name = "boundary_south", length = 200)
    private String boundarySouth;

    @Column(name = "boundary_east", length = 200)
    private String boundaryEast;

    @Column(name = "boundary_west", length = 200)
    private String boundaryWest;

    @Column(nullable = false)
    private boolean negotiable;

    @Column(name = "video_url", length = 500)
    private String videoUrl;

    private Double latitude;

    private Double longitude;

    @OneToMany(mappedBy = "property", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("sortOrder ASC")
    private List<PropertyImage> images = new ArrayList<>();

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    private static final BigDecimal QIRAT_SQM = new BigDecimal("175.03");
    private static final BigDecimal TWO = BigDecimal.valueOf(2);

    public static BigDecimal qiratsToSqm(final BigDecimal qirats) {
        return qirats.multiply(QIRAT_SQM).setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Calculates the approximate net area from the four plot sides, averaging each opposite pair.
     *
     * <p>The north/south sides and the east/west sides are the two opposite pairs; each pair may
     * differ, so its mean is used before the two means are multiplied.
     *
     * @return net area in square metres, or null unless all four sides are present
     */
    public BigDecimal netAreaSqm() {
        if (northSideM == null || southSideM == null || eastSideM == null || westSideM == null) {
            return null;
        }
        BigDecimal northSouth = northSideM.add(southSideM).divide(TWO, 4, RoundingMode.HALF_UP);
        BigDecimal eastWest = eastSideM.add(westSideM).divide(TWO, 4, RoundingMode.HALF_UP);
        return northSouth.multiply(eastWest).setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Creates an image for this property, links it back to this listing and appends it to the image list.
     *
     * @param url the image URL
     * @param sortOrder the position of the image inside the listing gallery
     * @return the image that was created and attached to this property
     */
    public PropertyImage addImage(final String url, final int sortOrder) {
        PropertyImage image = new PropertyImage();
        image.setProperty(this);
        image.setUrl(url);
        image.setSortOrder(sortOrder);
        images.add(image);
        return image;
    }

    public void removeImage(final PropertyImage image) {
        images.remove(image);
        image.setProperty(null);
    }

    public UUID getId() {
        return id;
    }

    public User getOwner() {
        return owner;
    }

    public void setOwner(final User owner) {
        this.owner = owner;
    }

    public String getTitleEn() {
        return titleEn;
    }

    public void setTitleEn(final String titleEn) {
        this.titleEn = titleEn;
    }

    public String getTitleAr() {
        return titleAr;
    }

    public void setTitleAr(final String titleAr) {
        this.titleAr = titleAr;
    }

    public String getDescriptionEn() {
        return descriptionEn;
    }

    public void setDescriptionEn(final String descriptionEn) {
        this.descriptionEn = descriptionEn;
    }

    public String getDescriptionAr() {
        return descriptionAr;
    }

    public void setDescriptionAr(final String descriptionAr) {
        this.descriptionAr = descriptionAr;
    }

    public PropertyType getPropertyType() {
        return propertyType;
    }

    public void setPropertyType(final PropertyType propertyType) {
        this.propertyType = propertyType;
    }

    public ListingType getListingType() {
        return listingType;
    }

    public void setListingType(final ListingType listingType) {
        this.listingType = listingType;
    }

    public Governorate getGovernorate() {
        return governorate;
    }

    public void setGovernorate(final Governorate governorate) {
        this.governorate = governorate;
    }

    public Area getArea() {
        return area;
    }

    public void setArea(final Area area) {
        this.area = area;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(final BigDecimal price) {
        this.price = price;
    }

    public BigDecimal getAreaSqm() {
        return areaSqm;
    }

    public void setAreaSqm(final BigDecimal areaSqm) {
        this.areaSqm = areaSqm;
    }

    public Integer getBedrooms() {
        return bedrooms;
    }

    public void setBedrooms(final Integer bedrooms) {
        this.bedrooms = bedrooms;
    }

    public Integer getBathrooms() {
        return bathrooms;
    }

    public void setBathrooms(final Integer bathrooms) {
        this.bathrooms = bathrooms;
    }

    public boolean isFurnished() {
        return furnished;
    }

    public void setFurnished(final boolean furnished) {
        this.furnished = furnished;
    }

    public LandKind getLandKind() {
        return landKind;
    }

    public void setLandKind(final LandKind landKind) {
        this.landKind = landKind;
    }

    public BigDecimal getAreaQirats() {
        return areaQirats;
    }

    public void setAreaQirats(final BigDecimal areaQirats) {
        this.areaQirats = areaQirats;
    }

    public BigDecimal getNorthSideM() {
        return northSideM;
    }

    public void setNorthSideM(final BigDecimal northSideM) {
        this.northSideM = northSideM;
    }

    public BigDecimal getSouthSideM() {
        return southSideM;
    }

    public void setSouthSideM(final BigDecimal southSideM) {
        this.southSideM = southSideM;
    }

    public BigDecimal getEastSideM() {
        return eastSideM;
    }

    public void setEastSideM(final BigDecimal eastSideM) {
        this.eastSideM = eastSideM;
    }

    public BigDecimal getWestSideM() {
        return westSideM;
    }

    public void setWestSideM(final BigDecimal westSideM) {
        this.westSideM = westSideM;
    }

    public BigDecimal getStreetWidthM() {
        return streetWidthM;
    }

    public void setStreetWidthM(final BigDecimal streetWidthM) {
        this.streetWidthM = streetWidthM;
    }

    public Boolean getBuildingPermit() {
        return buildingPermit;
    }

    public void setBuildingPermit(final Boolean buildingPermit) {
        this.buildingPermit = buildingPermit;
    }

    public String getBoundaryNorth() {
        return boundaryNorth;
    }

    public void setBoundaryNorth(final String boundaryNorth) {
        this.boundaryNorth = boundaryNorth;
    }

    public String getBoundarySouth() {
        return boundarySouth;
    }

    public void setBoundarySouth(final String boundarySouth) {
        this.boundarySouth = boundarySouth;
    }

    public String getBoundaryEast() {
        return boundaryEast;
    }

    public void setBoundaryEast(final String boundaryEast) {
        this.boundaryEast = boundaryEast;
    }

    public String getBoundaryWest() {
        return boundaryWest;
    }

    public void setBoundaryWest(final String boundaryWest) {
        this.boundaryWest = boundaryWest;
    }

    public boolean isNegotiable() {
        return negotiable;
    }

    public void setNegotiable(final boolean negotiable) {
        this.negotiable = negotiable;
    }

    public String getVideoUrl() {
        return videoUrl;
    }

    public void setVideoUrl(final String videoUrl) {
        this.videoUrl = videoUrl;
    }

    public Double getLatitude() {
        return latitude;
    }

    public void setLatitude(final Double latitude) {
        this.latitude = latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public void setLongitude(final Double longitude) {
        this.longitude = longitude;
    }

    public List<PropertyImage> getImages() {
        return images;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
