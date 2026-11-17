package com.aqar.api.service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import com.aqar.api.config.AqarProperties;
import com.aqar.api.domain.Conversation;
import com.aqar.api.domain.Governorate;
import com.aqar.api.domain.LandKind;
import com.aqar.api.domain.ListingType;
import com.aqar.api.domain.Message;
import com.aqar.api.domain.Property;
import com.aqar.api.domain.PropertyType;
import com.aqar.api.domain.Role;
import com.aqar.api.domain.User;
import com.aqar.api.repository.ConversationRepository;
import com.aqar.api.repository.MessageRepository;
import com.aqar.api.repository.PropertyRepository;
import com.aqar.api.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Seeds demo accounts, listings, land plots and a sample conversation on startup.
 *
 * <p>Each record is skipped when a listing with the same English title already exists, and the
 * sample conversation is only created while the conversation table is still empty.
 *
 * @author Mohamed Sayed
 */
@Component
@ConditionalOnProperty(name = "aqar.seed.enabled", havingValue = "true", matchIfMissing = true)
public class DataSeeder implements ApplicationRunner {

    private static final Logger LOGGER = LoggerFactory.getLogger(DataSeeder.class);

    private static final List<SeedListing> DEMO_LISTINGS = List.of(
            new SeedListing(
                    "Chic apartment in New Cairo",
                    "شقة أنيقة في القاهرة الجديدة",
                    "Furnished two-bedroom apartment in a gated compound in the Fifth Settlement, "
                            + "with a shared pool, gym and 24-hour security.",
                    "شقة مفروشة بغرفتي نوم داخل كومبوند مغلق في التجمع الخامس، "
                            + "مع مسبح مشترك وصالة رياضية وأمن على مدار الساعة.",
                    PropertyType.APARTMENT, ListingType.RENT, "18000.000", "145.00", 2, 2, true,
                    "EG", "CAIRO", "NEW_CAIRO", 30.0035, 31.4913),
            new SeedListing(
                    "Standalone villa in Sheikh Zayed",
                    "فيلا مستقلة في الشيخ زايد",
                    "Independent villa with a private garden, roof terrace and a driver's room. "
                            + "Quiet residential street close to international schools and malls.",
                    "فيلا مستقلة بحديقة خاصة وسطح وغرفة سائق. "
                            + "شارع سكني هادئ قريب من المدارس الدولية والمولات.",
                    PropertyType.VILLA, ListingType.SALE, "8500000.000", "320.00", 4, 4, false,
                    "EG", "GIZA", "SHEIKH_ZAYED", 30.0131, 30.9436),
            new SeedListing(
                    "Nile-side apartment in Maadi",
                    "شقة على النيل في المعادي",
                    "Classic three-bedroom apartment minutes from the Corniche, with high ceilings, "
                            + "a wide balcony and a renovated kitchen.",
                    "شقة كلاسيكية بثلاث غرف نوم على بعد دقائق من الكورنيش، "
                            + "بأسقف مرتفعة وشرفة واسعة ومطبخ مجدد.",
                    PropertyType.APARTMENT, ListingType.RENT, "12000.000", "115.00", 2, 1, false,
                    "EG", "CAIRO", "MAADI", 29.9603, 31.2569),
            new SeedListing(
                    "Office in Smouha",
                    "مكتب في سموحة",
                    "Fitted office in a business tower in Smouha with a meeting room, reception "
                            + "and two underground parking spaces.",
                    "مكتب مجهز في برج إداري في سموحة مع غرفة اجتماعات واستقبال "
                            + "وموقفين سيارات في الجراج.",
                    PropertyType.OFFICE, ListingType.RENT, "25000.000", "180.00", null, 2, false,
                    "EG", "ALEXANDRIA", "SMOUHA", 31.2118, 29.9553),
            new SeedListing(
                    "Lagoon chalet in El Gouna",
                    "شاليه على البحيرة في الجونة",
                    "Two-bedroom chalet overlooking the lagoon with a private garden and beach access. "
                            + "Sold furnished with a management contract option.",
                    "شاليه بغرفتي نوم يطل على البحيرة مع حديقة خاصة ووصول إلى الشاطئ. "
                            + "يُباع مفروشاً مع إمكانية عقد إدارة.",
                    PropertyType.VILLA, ListingType.SALE, "4200000.000", "120.00", 2, 2, true,
                    "EG", "RED_SEA", "EL_GOUNA", 27.3957, 33.6779),
            new SeedListing(
                    "Pool villa in Sharm El-Sheikh",
                    "فيلا بمسبح في شرم الشيخ",
                    "Four-bedroom villa with a private pool, landscaped garden and sea views. "
                            + "Five minutes from the marina and the airport.",
                    "فيلا بأربع غرف نوم مع مسبح خاص وحديقة منسقة وإطلالة على البحر. "
                            + "على بعد خمس دقائق من المارينا والمطار.",
                    PropertyType.VILLA, ListingType.SALE, "7800000.000", "280.00", 4, 3, true,
                    "EG", "SOUTH_SINAI", "SHARM_EL_SHEIKH", 27.9158, 34.3299),
            new SeedListing(
                    "Family apartment in Nasr City",
                    "شقة عائلية في مدينة نصر",
                    "Three-bedroom apartment near Abbas El-Akkad with a large living room, "
                            + "two bathrooms and a private parking spot.",
                    "شقة بثلاث غرف نوم قرب عباس العقاد بصالة كبيرة "
                            + "وحمامين وموقف سيارة خاص.",
                    PropertyType.APARTMENT, ListingType.SALE, "3200000.000", "130.00", 3, 2, false,
                    "EG", "CAIRO", "NASR_CITY", 30.0511, 31.3656),
            new SeedListing(
                    "Apartment in 6th of October",
                    "شقة في 6 أكتوبر",
                    "Modern two-bedroom apartment in a new building in the First District, "
                            + "close to Mall of Egypt and the Ring Road.",
                    "شقة حديثة بغرفتي نوم في مبنى جديد بالحي الأول، "
                            + "قريبة من مول مصر والطريق الدائري.",
                    PropertyType.APARTMENT, ListingType.RENT, "9500.000", "105.00", 2, 2, false,
                    "EG", "GIZA", "OCTOBER_6", 29.9285, 30.9188),
            new SeedListing(
                    "Retail shop in Downtown Cairo",
                    "محل تجاري في وسط البلد",
                    "Street-level shop on a busy Downtown pedestrian street near Talaat Harb. "
                            + "Suitable for retail or a cafe, with a small storage area.",
                    "محل على مستوى الشارع في شارع تجاري حيوي بوسط البلد قرب طلعت حرب. "
                            + "مناسب للبيع بالتجزئة أو مقهى، مع مساحة تخزين صغيرة.",
                    PropertyType.SHOP, ListingType.RENT, "30000.000", "60.00", null, 1, false,
                    "EG", "CAIRO", "DOWNTOWN", 30.0444, 31.2357));

    private static final List<SeedLand> DEMO_LAND = List.of(
            new SeedLand(
                    "Ten-qirat farm plot in Giza",
                    "أرض زراعية 10 قيراط في الجيزة",
                    "Level agricultural land with a Nile-water irrigation line, 10 qirats "
                            + "(about 1,750 m²), a 60 m frontage and 8 m street access. "
                            + "Suitable for seasonal crops or a smallholding.",
                    "أرض زراعية مستوية بها خط ري من مياه النيل، مساحتها 10 قيراط "
                            + "(نحو 1,750 م²) بواجهة 60 م وطريق بعرض 8 م. مناسبة للمحاصيل الموسمية أو الحيازة الصغيرة.",
                    LandKind.AGRICULTURAL, "1250000.000", "10.00",
                    "60.00", "60.00", "29.17", "29.17", "8.00", null, true,
                    "Nile irrigation canal", "Neighbouring farm plot",
                    "8 m agricultural road", "Neighbouring farm plot",
                    "EG", "GIZA", null, 29.9935, 31.1570),
            new SeedLand(
                    "Building plot in 6th of October",
                    "قطعة أرض للبناء في 6 أكتوبر",
                    "Serviced building plot with a valid permit, a 20 m frontage on a 12 m street "
                            + "and 25 m depth. Ready for a villa or a small apartment building.",
                    "قطعة أرض مرفقة برخصة بناء سارية، بواجهة 20 م على شارع بعرض 12 م وعمق 25 م. "
                            + "جاهزة لبناء فيلا أو مبنى سكني صغير.",
                    LandKind.BUILDING, "3200000.000", null,
                    "20.00", "20.00", "25.00", "25.00", "12.00", true, true,
                    "12 m street", "Neighbouring plot",
                    "Neighbouring plot", "10 m street",
                    "EG", "GIZA", "OCTOBER_6", 29.9285, 30.9188));

    private final UserRepository users;
    private final PropertyRepository properties;
    private final ConversationRepository conversations;
    private final MessageRepository messages;
    private final PasswordEncoder passwordEncoder;
    private final AqarProperties config;
    private final LocationService locations;

    /**
     * Creates the seeder with its repositories and collaborators.
     *
     * @param users repository of accounts
     * @param properties repository of listings
     * @param conversations repository of conversations
     * @param messages repository of messages
     * @param passwordEncoder encoder used for the demo account passwords
     * @param config application configuration providing the demo credentials
     * @param locations service used to resolve governorates and areas
     */
    public DataSeeder(final UserRepository users, final PropertyRepository properties,
                      final ConversationRepository conversations, final MessageRepository messages,
                      final PasswordEncoder passwordEncoder, final AqarProperties config,
                      final LocationService locations) {
        this.users = users;
        this.properties = properties;
        this.conversations = conversations;
        this.messages = messages;
        this.passwordEncoder = passwordEncoder;
        this.config = config;
        this.locations = locations;
    }

    /**
     * Ensures the demo accounts exist, then seeds the listings and a sample conversation.
     *
     * @param args application arguments supplied by Spring Boot, unused here
     */
    @Override
    @Transactional
    public void run(final ApplicationArguments args) {
        User owner = ensureUser("Fahad Al-Sabah", "owner@aqar.app", config.seed().demoPassword(),
                "+965 5555 0101", Role.USER);
        final User renter = ensureUser("Sara Al-Ajmi", "renter@aqar.app", config.seed().demoPassword(),
                "+965 5555 0202", Role.USER);
        ensureUser("Aqar Admin", config.seed().adminEmail(), config.seed().adminPassword(),
                "+965 5555 0000", Role.ADMIN);

        seedProperties(owner);
        seedLand(owner);
        if (conversations.count() == 0) {
            seedConversation(owner, renter);
        }
        LOGGER.info("Aqar demo data ready. Demo accounts: owner@aqar.app, renter@aqar.app, {}",
                config.seed().adminEmail());
    }

    /**
     * Returns the account with the given email, creating it when it does not exist yet.
     *
     * @param fullName display name of the account
     * @param email email address of the account
     * @param password plain password encoded before storage
     * @param phone phone number of the account
     * @param role role granted to a newly created account
     * @return the existing or newly created account
     */
    private User ensureUser(final String fullName, final String email, final String password, final String phone,
                            final Role role) {
        return users.findByEmailIgnoreCase(email).orElseGet(() -> {
            User user = new User();
            user.setFullName(fullName);
            user.setEmail(email.toLowerCase());
            user.setPhone(phone);
            user.setPasswordHash(passwordEncoder.encode(password));
            user.setRole(role);
            return users.save(user);
        });
    }

    /**
     * Persists the demo apartments, villas, offices and shops with two placeholder images each.
     *
     * @param owner account that owns every seeded listing
     */
    private void seedProperties(final User owner) {
        int index = 1;
        for (SeedListing listing : DEMO_LISTINGS) {
            if (properties.existsByTitleEn(listing.titleEn())) {
                index++;
                continue;
            }
            Governorate governorate = locations.requireGovernorate(listing.countryCode(),
                    listing.governorateCode());
            Property property = new Property();
            property.setOwner(owner);
            property.setTitleEn(listing.titleEn());
            property.setTitleAr(listing.titleAr());
            property.setDescriptionEn(listing.descriptionEn());
            property.setDescriptionAr(listing.descriptionAr());
            property.setPropertyType(listing.propertyType());
            property.setListingType(listing.listingType());
            property.setPrice(new BigDecimal(listing.price()));
            property.setAreaSqm(new BigDecimal(listing.areaSqm()));
            property.setBedrooms(listing.bedrooms());
            property.setBathrooms(listing.bathrooms());
            property.setFurnished(listing.furnished());
            property.setGovernorate(governorate);
            property.setArea(locations.requireArea(governorate, listing.areaCode()));
            property.setLatitude(listing.latitude());
            property.setLongitude(listing.longitude());
            property.addImage("https://picsum.photos/seed/aqar-" + index + "-a/1200/800", 0);
            property.addImage("https://picsum.photos/seed/aqar-" + index + "-b/1200/800", 1);
            properties.save(property);
            index++;
        }
    }

    /**
     * Persists the demo land plots together with their four sides, net area and boundary descriptions.
     *
     * @param owner account that owns every seeded plot
     */
    private void seedLand(final User owner) {
        for (SeedLand listing : DEMO_LAND) {
            if (properties.existsByTitleEn(listing.titleEn())) {
                continue;
            }
            Governorate governorate = locations.requireGovernorate(listing.countryCode(),
                    listing.governorateCode());
            Property property = new Property();
            property.setOwner(owner);
            property.setTitleEn(listing.titleEn());
            property.setTitleAr(listing.titleAr());
            property.setDescriptionEn(listing.descriptionEn());
            property.setDescriptionAr(listing.descriptionAr());
            property.setPropertyType(PropertyType.LAND);
            property.setListingType(ListingType.SALE);
            property.setPrice(new BigDecimal(listing.price()));
            property.setLandKind(listing.landKind());
            property.setAreaQirats(
                    listing.areaQirats() == null ? null : new BigDecimal(listing.areaQirats()));
            property.setNorthSideM(new BigDecimal(listing.northSideM()));
            property.setSouthSideM(new BigDecimal(listing.southSideM()));
            property.setEastSideM(new BigDecimal(listing.eastSideM()));
            property.setWestSideM(new BigDecimal(listing.westSideM()));
            property.setAreaSqm(property.netAreaSqm());
            property.setStreetWidthM(new BigDecimal(listing.streetWidthM()));
            property.setBuildingPermit(listing.buildingPermit());
            property.setBoundaryNorth(listing.boundaryNorth());
            property.setBoundarySouth(listing.boundarySouth());
            property.setBoundaryEast(listing.boundaryEast());
            property.setBoundaryWest(listing.boundaryWest());
            property.setNegotiable(listing.negotiable());
            property.setGovernorate(governorate);
            property.setArea(
                    listing.areaCode() == null ? null : locations.requireArea(governorate, listing.areaCode()));
            property.setLatitude(listing.latitude());
            property.setLongitude(listing.longitude());
            String slug = listing.landKind() == LandKind.AGRICULTURAL ? "agri" : "build";
            property.addImage("https://picsum.photos/seed/aqar-land-" + slug + "-a/1200/800", 0);
            property.addImage("https://picsum.photos/seed/aqar-land-" + slug + "-b/1200/800", 1);
            properties.save(property);
        }
    }

    /**
     * Creates a sample conversation between the demo renter and owner on the owner's first listing.
     *
     * @param owner account acting as the listing owner
     * @param renter account acting as the interested renter
     */
    private void seedConversation(final User owner, final User renter) {
        List<Property> owned = properties
                .findByOwnerIdAndGovernorateCountryActiveTrue(owner.getId(), PageRequest.of(0, 1))
                .getContent();
        if (owned.isEmpty()) {
            return;
        }
        Property property = owned.get(0);

        Conversation conversation = new Conversation();
        conversation.setProperty(property);
        conversation.setRenter(renter);
        conversation.setOwner(owner);
        conversation.setLastMessageAt(Instant.now());
        conversations.save(conversation);

        Instant now = Instant.now();
        message(conversation, renter,
                "Hi Fahad, is this apartment still available? I'd like to view it this week.", true,
                now.minus(2, ChronoUnit.HOURS));
        message(conversation, owner,
                "Hi Sara, yes it is. Thursday after 5 PM works for a viewing.", false,
                now.minus(90, ChronoUnit.MINUTES));
        Message latest = message(conversation, renter,
                "Perfect, I'll confirm tomorrow morning. Thank you!", false,
                now.minus(30, ChronoUnit.MINUTES));

        conversation.setLastMessageAt(latest.getCreatedAt());
        conversations.save(conversation);
    }

    /**
     * Stores a single demo message with an explicit read flag and timestamp.
     *
     * @param conversation conversation that receives the message
     * @param sender account sending the message
     * @param body text of the message
     * @param read whether the message starts as read
     * @param createdAt timestamp assigned to the message
     * @return the stored message
     */
    private Message message(final Conversation conversation, final User sender, final String body,
                            final boolean read, final Instant createdAt) {
        Message message = new Message();
        message.setConversation(conversation);
        message.setSender(sender);
        message.setBody(body);
        message.setReadFlag(read);
        message.setCreatedAt(createdAt);
        return messages.save(message);
    }

    /**
     * Demo listing template with bilingual text, classification and location fields.
     *
     * <p>Values are converted to entities by {@code seedProperties}.
     *
     * @author Mohamed Sayed
     */
    private record SeedListing(
            String titleEn,
            String titleAr,
            String descriptionEn,
            String descriptionAr,
            PropertyType propertyType,
            ListingType listingType,
            String price,
            String areaSqm,
            Integer bedrooms,
            Integer bathrooms,
            boolean furnished,
            String countryCode,
            String governorateCode,
            String areaCode,
            double latitude,
            double longitude) {
    }

    /**
     * Demo land template with bilingual text, the four measured sides, the street width and the
     * four boundary descriptions.
     *
     * <p>Values are converted to entities by {@code seedLand}.
     *
     * @author Mohamed Sayed
     */
    private record SeedLand(
            String titleEn,
            String titleAr,
            String descriptionEn,
            String descriptionAr,
            LandKind landKind,
            String price,
            String areaQirats,
            String northSideM,
            String southSideM,
            String eastSideM,
            String westSideM,
            String streetWidthM,
            Boolean buildingPermit,
            boolean negotiable,
            String boundaryNorth,
            String boundarySouth,
            String boundaryEast,
            String boundaryWest,
            String countryCode,
            String governorateCode,
            String areaCode,
            double latitude,
            double longitude) {
    }
}
