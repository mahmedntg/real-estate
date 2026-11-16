package com.aqar.api;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.endsWith;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.startsWith;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import java.util.Base64;
import java.util.UUID;
import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@SpringBootTest(properties = {
        "aqar.seed.enabled=false",
        "aqar.media.dir=target/test-media",
        "aqar.mail.expose-code=true"
})
@AutoConfigureMockMvc
@Testcontainers
class AqarApiIntegrationTest {

    private static final byte[] ONE_PIXEL_PNG = Base64.getDecoder().decode(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=");

    @Container
    @ServiceConnection
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:18.7-alpine");

    @Autowired
    MockMvc mockMvc;

    @Test
    void authFlowRequiresEmailVerificationAndIssuesJwt() throws Exception {
        String email = uniqueEmail("auth");
        String registerBody = """
                {"full_name":"Auth User","email":"%s","password":"Password123!","phone":"+965 5555 0000"}
                """.formatted(email);

        String response = mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerBody))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.verification_required").value(true))
                .andExpect(jsonPath("$.dev_code").isNotEmpty())
                .andExpect(jsonPath("$.token").doesNotExist())
                .andReturn().getResponse().getContentAsString();
        String code = JsonPath.read(response, "$.dev_code");

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"Password123!"}
                                """.formatted(email)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.title").value("Email not verified"));

        mockMvc.perform(post("/api/v1/auth/verify")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","code":"%s"}
                                """.formatted(email, "000000".equals(code) ? "111111" : "000000")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Invalid code"));

        String verifyResponse = mockMvc.perform(post("/api/v1/auth/verify")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","code":"%s"}
                                """.formatted(email, code)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.user.email_verified").value(true))
                .andReturn().getResponse().getContentAsString();
        String token = JsonPath.read(verifyResponse, "$.token");

        mockMvc.perform(get("/api/v1/auth/me").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(email))
                .andExpect(jsonPath("$.role").value("USER"))
                .andExpect(jsonPath("$.email_verified").value(true));

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"Password123!"}
                                """.formatted(email)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty());

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"wrong-password"}
                                """.formatted(email)))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerBody))
                .andExpect(status().isConflict());

        mockMvc.perform(post("/api/v1/auth/resend")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s"}
                                """.formatted(email)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Already verified"));

        mockMvc.perform(get("/api/v1/auth/me"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void propertyLifecycleSearchFavoritesAndOwnership() throws Exception {
        String ownerToken = register("owner");
        String otherToken = register("other");
        String title = "Test Listing " + UUID.randomUUID();

        String createResponse = mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(propertyBody(title)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.title_en").value(title))
                .andExpect(jsonPath("$.mine").value(true))
                .andExpect(jsonPath("$.created_at").isNotEmpty())
                .andExpect(jsonPath("$.updated_at").isNotEmpty())
                .andReturn().getResponse().getContentAsString();
        String propertyId = JsonPath.read(createResponse, "$.id");

        mockMvc.perform(get("/api/v1/properties").param("q", title))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andExpect(jsonPath("$.items[0].id").value(propertyId))
                .andExpect(jsonPath("$.items[0].favorite").value(false));

        mockMvc.perform(get("/api/v1/properties")
                        .param("q", title)
                        .param("type", "VILLA"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(0)));

        mockMvc.perform(get("/api/v1/properties")
                        .param("q", title)
                        .param("minPrice", "17000")
                        .param("maxPrice", "19000")
                        .param("bedrooms", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)));

        mockMvc.perform(put("/api/v1/properties/{id}/favorite", propertyId)
                        .header("Authorization", bearer(otherToken)))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/v1/me/favorites").header("Authorization", bearer(otherToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andExpect(jsonPath("$.items[0].id").value(propertyId))
                .andExpect(jsonPath("$.items[0].favorite").value(true));

        mockMvc.perform(delete("/api/v1/properties/{id}/favorite", propertyId)
                        .header("Authorization", bearer(otherToken)))
                .andExpect(status().isNoContent());
        mockMvc.perform(get("/api/v1/me/favorites").header("Authorization", bearer(otherToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(0)));

        mockMvc.perform(put("/api/v1/properties/{id}", propertyId)
                        .header("Authorization", bearer(otherToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(propertyBody(title)))
                .andExpect(status().isForbidden());

        mockMvc.perform(put("/api/v1/properties/{id}", propertyId)
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(propertyBody(title + " updated")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title_en").value(title + " updated"))
                .andExpect(jsonPath("$.updated_at").isNotEmpty());

        mockMvc.perform(get("/api/v1/me/properties").header("Authorization", bearer(ownerToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].id").value(propertyId));

        mockMvc.perform(delete("/api/v1/properties/{id}", propertyId)
                        .header("Authorization", bearer(otherToken)))
                .andExpect(status().isForbidden());

        mockMvc.perform(delete("/api/v1/properties/{id}", propertyId)
                        .header("Authorization", bearer(ownerToken)))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/v1/properties/{id}", propertyId))
                .andExpect(status().isNotFound());

        mockMvc.perform(post("/api/v1/properties")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(propertyBody("Anonymous listing")))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void locationCatalogDrivesCountryScopedListings() throws Exception {
        mockMvc.perform(get("/api/v1/locations"))
                .andExpect(status().isOk())
                .andExpect(header().string("Cache-Control", containsString("max-age=3600")))
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].code").value("EG"))
                .andExpect(jsonPath("$[0].currency_code").value("EGP"))
                .andExpect(jsonPath("$[0].currency_symbol_en").value("EGP"))
                .andExpect(jsonPath("$[0].governorates", hasSize(27)))
                .andExpect(jsonPath("$[0].governorates[*].code", hasItem("CAIRO")))
                .andExpect(jsonPath("$[0].governorates[0].code").value("CAIRO"))
                .andExpect(jsonPath("$[0].governorates[0].areas", hasSize(8)))
                .andExpect(jsonPath("$[0].governorates[0].areas[3].code").value("MAADI"));

        String ownerToken = register("locations");
        String egTitle = "Egypt scope " + UUID.randomUUID();

        String egResponse = mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(propertyBody(egTitle, "EG", "CAIRO", "MAADI", "18000.000")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.country_code").value("EG"))
                .andExpect(jsonPath("$.governorate_code").value("CAIRO"))
                .andExpect(jsonPath("$.area_code").value("MAADI"))
                .andReturn().getResponse().getContentAsString();
        String egId = JsonPath.read(egResponse, "$.id");

        mockMvc.perform(get("/api/v1/properties").param("country", "EG").param("q", egTitle))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andExpect(jsonPath("$.items[0].id").value(egId));
        mockMvc.perform(get("/api/v1/properties").param("country", "KW").param("q", egTitle))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(0)));
        mockMvc.perform(get("/api/v1/properties")
                        .param("governorate", "CAIRO")
                        .param("area", "MAADI")
                        .param("q", egTitle))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)));

        mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(propertyBody("Inactive country " + UUID.randomUUID(), "KW", "HAWALLI",
                                "SALMIYA", "750.000")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Invalid location"));
        mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(propertyBody("Unknown governorate " + UUID.randomUUID(), "EG", "HAWALLI",
                                "SALMIYA", "750.000")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Invalid location"));
        mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(propertyBody("Mismatched area " + UUID.randomUUID(), "EG", "CAIRO",
                                "SMOUHA", "18000.000")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Invalid location"));
    }

    @Test
    void landListingsCarryEgyptMarketDetails() throws Exception {
        String ownerToken = register("land-owner");
        String agriTitle = "Farm plot " + UUID.randomUUID();
        String plotTitle = "Building plot " + UUID.randomUUID();

        String agriResponse = mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(landBody(agriTitle, "LAND", "AGRICULTURAL", "10.00", null)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.land_kind").value("AGRICULTURAL"))
                .andExpect(jsonPath("$.area_qirats").value(10.0))
                .andExpect(jsonPath("$.area_sqm").value(1750.3))
                .andExpect(jsonPath("$.frontage_m").value(60.0))
                .andExpect(jsonPath("$.depth_m").value(29.17))
                .andExpect(jsonPath("$.street_width_m").value(8.0))
                .andExpect(jsonPath("$.boundary_north").value("Nile irrigation canal"))
                .andExpect(jsonPath("$.boundary_south").value("Neighbouring farm plot"))
                .andExpect(jsonPath("$.boundary_east").value("8 m agricultural road"))
                .andExpect(jsonPath("$.boundary_west").value("Neighbouring farm plot"))
                .andExpect(jsonPath("$.negotiable").value(true))
                .andReturn().getResponse().getContentAsString();
        String agriId = JsonPath.read(agriResponse, "$.id");

        mockMvc.perform(get("/api/v1/properties").param("q", agriTitle))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].land_kind").value("AGRICULTURAL"))
                .andExpect(jsonPath("$.items[0].area_qirats").value(10.0))
                .andExpect(jsonPath("$.items[0].negotiable").value(true));

        mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(landBody(plotTitle, "LAND", "BUILDING", null, true)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.land_kind").value("BUILDING"))
                .andExpect(jsonPath("$.building_permit").value(true))
                .andExpect(jsonPath("$.area_sqm").value(500.0))
                .andExpect(jsonPath("$.boundary_north").value("Nile irrigation canal"))
                .andExpect(jsonPath("$.negotiable").value(true));

        mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(landBody("Agricultural without qirats " + UUID.randomUUID(),
                                "LAND", "AGRICULTURAL", null, null)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Invalid land details"));
        mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(landBody("Building without permit " + UUID.randomUUID(),
                                "LAND", "BUILDING", null, null)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Invalid land details"));
        mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(landBody("Land details on apartment " + UUID.randomUUID(),
                                "APARTMENT", "AGRICULTURAL", "10.00", null)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Invalid land details"));

        mockMvc.perform(delete("/api/v1/properties/{id}", agriId)
                        .header("Authorization", bearer(ownerToken)))
                .andExpect(status().isNoContent());
    }

    @Test
    void mediaUploadIsServedAndProtected() throws Exception {
        String ownerToken = register("media-owner");
        String otherToken = register("media-other");
        String propertyId = createProperty(ownerToken, "Media Listing " + UUID.randomUUID());

        MockMultipartFile image = new MockMultipartFile("files", "photo.png", "image/png", ONE_PIXEL_PNG);

        String uploadResponse = mockMvc.perform(multipart("/api/v1/properties/{id}/images", propertyId)
                        .file(image)
                        .header("Authorization", bearer(ownerToken)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$[0].url", startsWith("/media/")))
                .andReturn().getResponse().getContentAsString();
        String mediaUrl = JsonPath.read(uploadResponse, "$[0].url");

        mockMvc.perform(get(mediaUrl))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.IMAGE_PNG));

        mockMvc.perform(get("/api/v1/properties/{id}", propertyId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.images", hasSize(1)));

        MockMultipartFile video = new MockMultipartFile("file", "tour.mp4", "video/mp4",
                "fake-video-bytes".getBytes());
        String videoResponse = mockMvc.perform(multipart("/api/v1/properties/{id}/video", propertyId)
                        .file(video)
                        .header("Authorization", bearer(ownerToken)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.url", startsWith("/media/")))
                .andReturn().getResponse().getContentAsString();
        String videoUrl = JsonPath.read(videoResponse, "$.url");

        mockMvc.perform(get(videoUrl))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.parseMediaType("video/mp4")));
        mockMvc.perform(get("/api/v1/properties/{id}", propertyId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.video_url").value(videoUrl));

        mockMvc.perform(multipart("/api/v1/properties/{id}/video", propertyId)
                        .file(video)
                        .header("Authorization", bearer(otherToken)))
                .andExpect(status().isForbidden());

        MockMultipartFile notAVideo = new MockMultipartFile("file", "note.txt", "text/plain",
                "hello".getBytes());
        mockMvc.perform(multipart("/api/v1/properties/{id}/video", propertyId)
                        .file(notAVideo)
                        .header("Authorization", bearer(ownerToken)))
                .andExpect(status().isBadRequest());

        mockMvc.perform(delete("/api/v1/properties/{id}/video", propertyId)
                        .header("Authorization", bearer(ownerToken)))
                .andExpect(status().isNoContent());
        mockMvc.perform(get("/api/v1/properties/{id}", propertyId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.video_url").isEmpty());

        mockMvc.perform(multipart("/api/v1/properties/{id}/images", propertyId)
                        .file(image)
                        .header("Authorization", bearer(otherToken)))
                .andExpect(status().isForbidden());

        MockMultipartFile notAnImage = new MockMultipartFile("files", "note.txt", "text/plain",
                "hello".getBytes());
        mockMvc.perform(multipart("/api/v1/properties/{id}/images", propertyId)
                        .file(notAnImage)
                        .header("Authorization", bearer(ownerToken)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void mediaLifecycleRejectsInvalidUploadsAndDeletesFiles() throws Exception {
        String token = register("media-lifecycle");
        String propertyId = createProperty(token, "Media lifecycle " + UUID.randomUUID());

        MockMultipartFile jpeg = new MockMultipartFile("files", "photo.jpg", "image/jpeg", ONE_PIXEL_PNG);
        MockMultipartFile webp = new MockMultipartFile("files", "photo.webp", "image/webp", ONE_PIXEL_PNG);
        String uploadResponse = mockMvc.perform(multipart("/api/v1/properties/{id}/images", propertyId)
                        .file(jpeg)
                        .file(webp)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].url", endsWith(".jpg")))
                .andExpect(jsonPath("$[1].url", endsWith(".webp")))
                .andReturn().getResponse().getContentAsString();
        String jpegUrl = JsonPath.read(uploadResponse, "$[0].url");
        String webpUrl = JsonPath.read(uploadResponse, "$[1].url");
        String jpegId = JsonPath.read(uploadResponse, "$[0].id");

        mockMvc.perform(get(jpegUrl))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.IMAGE_JPEG));
        mockMvc.perform(get(webpUrl))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.parseMediaType("image/webp")));

        mockMvc.perform(delete("/api/v1/properties/{id}/images/{imageId}", propertyId, jpegId)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isNoContent());
        mockMvc.perform(get(jpegUrl)).andExpect(status().isNotFound());
        mockMvc.perform(get("/media/unmanaged-file.txt")).andExpect(status().isNotFound());

        mockMvc.perform(multipart("/api/v1/properties/{id}/images", propertyId)
                        .file(new MockMultipartFile("files", "empty.png", "image/png", new byte[0]))
                        .header("Authorization", bearer(token)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Empty file"));
        mockMvc.perform(multipart("/api/v1/properties/{id}/images", propertyId)
                        .file(new MockMultipartFile("files", "huge.png", "image/png", new byte[8 * 1024 * 1024 + 1]))
                        .header("Authorization", bearer(token)))
                .andExpect(status().isPayloadTooLarge())
                .andExpect(jsonPath("$.title").value("Image too large"));
        mockMvc.perform(multipart("/api/v1/properties/{id}/images", UUID.randomUUID())
                        .file(jpeg)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isNotFound());

        MockMultipartFile webm = new MockMultipartFile("file", "tour.webm", "video/webm", "fake-webm".getBytes());
        String webmUrl = JsonPath.read(mockMvc.perform(multipart("/api/v1/properties/{id}/video", propertyId)
                        .file(webm)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.url", endsWith(".webm")))
                .andReturn().getResponse().getContentAsString(), "$.url");
        mockMvc.perform(get(webmUrl))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.parseMediaType("video/webm")));

        MockMultipartFile mov = new MockMultipartFile("file", "tour.mov", "video/quicktime", "fake-mov".getBytes());
        String movUrl = JsonPath.read(mockMvc.perform(multipart("/api/v1/properties/{id}/video", propertyId)
                        .file(mov)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.url", endsWith(".mov")))
                .andReturn().getResponse().getContentAsString(), "$.url");
        mockMvc.perform(get(movUrl))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.parseMediaType("video/quicktime")));
        mockMvc.perform(get(webmUrl)).andExpect(status().isNotFound());

        mockMvc.perform(delete("/api/v1/properties/{id}", propertyId)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isNoContent());
        mockMvc.perform(get(webpUrl)).andExpect(status().isNotFound());
    }

    @Test
    void searchAppliesFiltersSortingAndViewerFlags() throws Exception {
        String ownerToken = register("search-owner");
        String otherToken = register("search-other");
        String marker = "River view " + UUID.randomUUID();
        String cheapId = createListing(ownerToken, marker + " cheap", "APARTMENT", "RENT", "MAADI",
                "9000.000", true);
        String expensiveId = createListing(ownerToken, marker + " expensive", "VILLA", "SALE", "MAADI",
                "9900000.000", false);

        mockMvc.perform(get("/api/v1/properties").param("q", marker))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(2)));

        mockMvc.perform(get("/api/v1/properties")
                        .param("q", marker)
                        .param("listingType", "SALE")
                        .param("furnished", "false"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andExpect(jsonPath("$.items[0].id").value(expensiveId));

        mockMvc.perform(get("/api/v1/properties")
                        .param("q", marker)
                        .param("country", "eg")
                        .param("governorate", "cairo")
                        .param("area", "maadi"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(2)));

        mockMvc.perform(get("/api/v1/properties").param("q", marker).param("sort", "price_asc"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].id").value(cheapId));
        mockMvc.perform(get("/api/v1/properties").param("q", marker).param("sort", "price_desc"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].id").value(expensiveId));
        mockMvc.perform(get("/api/v1/properties").param("q", marker).param("sort", "newest"))
                .andExpect(status().isOk());
        mockMvc.perform(get("/api/v1/properties").param("q", marker).param("size", "0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(2)));

        mockMvc.perform(put("/api/v1/properties/{id}/favorite", expensiveId)
                        .header("Authorization", bearer(otherToken)))
                .andExpect(status().isNoContent());
        mockMvc.perform(get("/api/v1/properties/{id}", expensiveId)
                        .header("Authorization", bearer(otherToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.favorite").value(true))
                .andExpect(jsonPath("$.mine").value(false));
        mockMvc.perform(get("/api/v1/properties/{id}", cheapId)
                        .header("Authorization", bearer(ownerToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mine").value(true));

        mockMvc.perform(put("/api/v1/properties/{id}", UUID.randomUUID())
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(propertyBody(marker + " unknown")))
                .andExpect(status().isNotFound());
        mockMvc.perform(delete("/api/v1/properties/{id}", UUID.randomUUID())
                        .header("Authorization", bearer(ownerToken)))
                .andExpect(status().isNotFound());

        mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title_en": "   ",
                                  "title_ar": "عنوان عربي",
                                  "description_en": "   ",
                                  "description_ar": "وصف عربي",
                                  "property_type": "APARTMENT",
                                  "listing_type": "RENT",
                                  "country_code": "EG",
                                  "governorate_code": "CAIRO",
                                  "price": 15000.000,
                                  "furnished": true
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.title_en").value(""))
                .andExpect(jsonPath("$.description_en").value(""))
                .andExpect(jsonPath("$.area").doesNotExist());

        mockMvc.perform(get("/api/v1/properties").param("minPrice", "not-a-number"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Invalid parameter"));
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{not-json"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Malformed request"));
        mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title_en": "Invalid payload",
                                  "description_en": "Missing location and an impossible price.",
                                  "property_type": "APARTMENT",
                                  "listing_type": "RENT",
                                  "country_code": "",
                                  "governorate_code": "CAIRO",
                                  "price": 0,
                                  "bedrooms": 99,
                                  "furnished": true
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Validation failed"))
                .andExpect(jsonPath("$.errors", hasSize(3)));
    }

    @Test
    void registrationToleratesMissingPhoneAndRejectsRepeatedVerification() throws Exception {
        String email = uniqueEmail("no-phone");
        String response = mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"full_name":"No Phone","email":"%s","password":"Password123!"}
                                """.formatted(email)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String code = JsonPath.read(response, "$.dev_code");

        mockMvc.perform(post("/api/v1/auth/verify")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","code":"%s"}
                                """.formatted(email, code)))
                .andExpect(status().isOk());
        mockMvc.perform(post("/api/v1/auth/verify")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","code":"%s"}
                                """.formatted(email, code)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Already verified"));

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"full_name":"Blank Phone","email":"%s","phone":"   ","password":"Password123!"}
                                """.formatted(uniqueEmail("blank-phone"))))
                .andExpect(status().isCreated());
    }

    @Test
    void messagingTracksUnreadCountsAndAccess() throws Exception {
        String ownerToken = register("chat-owner");
        String renterToken = register("chat-renter");
        String outsiderToken = register("chat-outsider");
        String propertyId = createProperty(ownerToken, "Chat Listing " + UUID.randomUUID());

        mockMvc.perform(post("/api/v1/properties/{id}/conversations", propertyId)
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"message":"Talking to myself"}
                                """))
                .andExpect(status().isBadRequest());

        String startResponse = mockMvc.perform(post("/api/v1/properties/{id}/conversations", propertyId)
                        .header("Authorization", bearer(renterToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"message":"Hi, is this still available?"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.unread_count").value(0))
                .andExpect(jsonPath("$.owner_view").value(false))
                .andReturn().getResponse().getContentAsString();
        String conversationId = JsonPath.read(startResponse, "$.id");

        mockMvc.perform(get("/api/v1/conversations").header("Authorization", bearer(ownerToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andExpect(jsonPath("$.items[0].id").value(conversationId))
                .andExpect(jsonPath("$.items[0].unread_count").value(1))
                .andExpect(jsonPath("$.items[0].owner_view").value(true));

        mockMvc.perform(post("/api/v1/conversations/{id}/messages", conversationId)
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"body":"Yes, Thursday after 5 PM works."}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.mine").value(true));

        mockMvc.perform(get("/api/v1/conversations").header("Authorization", bearer(renterToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].unread_count").value(1))
                .andExpect(jsonPath("$.items[0].owner_view").value(false));

        mockMvc.perform(get("/api/v1/conversations/{id}/messages", conversationId)
                        .header("Authorization", bearer(renterToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total_elements").value(2))
                .andExpect(jsonPath("$.items[*].body", hasItem("Yes, Thursday after 5 PM works.")))
                .andExpect(jsonPath("$.items[*].mine", hasItem(true)))
                .andExpect(jsonPath("$.items[*].mine", hasItem(false)));

        mockMvc.perform(post("/api/v1/conversations/{id}/read", conversationId)
                        .header("Authorization", bearer(renterToken)))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/v1/conversations").header("Authorization", bearer(renterToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].unread_count").value(0));

        mockMvc.perform(get("/api/v1/conversations/{id}", conversationId)
                        .header("Authorization", bearer(renterToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.owner_view").value(false))
                .andExpect(jsonPath("$.last_message").value("Yes, Thursday after 5 PM works."));
        mockMvc.perform(get("/api/v1/conversations").param("size", "0")
                        .header("Authorization", bearer(renterToken)))
                .andExpect(status().isOk());
        mockMvc.perform(post("/api/v1/properties/{id}/conversations", UUID.randomUUID())
                        .header("Authorization", bearer(renterToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"message":"Missing listing"}
                                """))
                .andExpect(status().isNotFound());
        mockMvc.perform(post("/api/v1/conversations/{id}/messages", UUID.randomUUID())
                        .header("Authorization", bearer(renterToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"body":"Missing conversation"}
                                """))
                .andExpect(status().isNotFound());

        mockMvc.perform(get("/api/v1/conversations/{id}", conversationId)
                        .header("Authorization", bearer(outsiderToken)))
                .andExpect(status().isNotFound());
    }

    @Test
    void listingsNeedOnlyOneLanguage() throws Exception {
        String ownerToken = register("language");
        String title = "Arabic only " + UUID.randomUUID();

        mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(oneLanguageBody(title, true, true)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.title_ar").value(title))
                .andExpect(jsonPath("$.title_en").value(""))
                .andExpect(jsonPath("$.description_en").value(""));

        mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(oneLanguageBody("No title " + UUID.randomUUID(), false, true)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Missing title"));

        mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(oneLanguageBody(title + " no description", true, false)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Missing description"));
    }

    private String oneLanguageBody(String title, boolean withTitle, boolean withDescription) {
        String titleField = withTitle ? "\"title_ar\": \"%s\",".formatted(title) : "";
        String descriptionField = withDescription
                ? "\"description_ar\": \"شقة عربية فقط.\","
                : "";
        return """
                {
                  %s
                  %s
                  "property_type": "APARTMENT",
                  "listing_type": "RENT",
                  "country_code": "EG",
                  "governorate_code": "CAIRO",
                  "area_code": "MAADI",
                  "price": 18000.000,
                  "furnished": false
                }
                """.formatted(titleField, descriptionField);
    }

    private String register(String prefix) throws Exception {
        String email = uniqueEmail(prefix);
        String body = """
                {"full_name":"%s","email":"%s","password":"Password123!","phone":"+965 5555 0000"}
                """.formatted(prefix, email);
        String response = mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.verification_required").value(true))
                .andReturn().getResponse().getContentAsString();
        String code = JsonPath.read(response, "$.dev_code");
        String verified = mockMvc.perform(post("/api/v1/auth/verify")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","code":"%s"}
                                """.formatted(email, code)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(verified, "$.token");
    }

    private String createProperty(String token, String title) throws Exception {
        String response = mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(propertyBody(title)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(response, "$.id");
    }

    private String createListing(String token, String title, String propertyType, String listingType,
                                 String areaCode, String price, boolean furnished) throws Exception {
        String response = mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title_en": "%s",
                                  "title_ar": "إعلان للاختبار",
                                  "description_en": "Listing created by the search integration test.",
                                  "description_ar": "إعلان للاختبار.",
                                  "property_type": "%s",
                                  "listing_type": "%s",
                                  "country_code": "EG",
                                  "governorate_code": "CAIRO",
                                  "area_code": "%s",
                                  "price": %s,
                                  "area_sqm": 120.00,
                                  "bedrooms": 2,
                                  "bathrooms": 2,
                                  "furnished": %s
                                }
                                """.formatted(title, propertyType, listingType, areaCode, price, furnished)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(response, "$.id");
    }

    private String propertyBody(String title) {
        return propertyBody(title, "EG", "CAIRO", "MAADI", "18000.000");
    }

    private String propertyBody(String title, String countryCode, String governorateCode, String areaCode,
                                String price) {
        return """
                {
                  "title_en": "%s",
                  "title_ar": "شقة بإطلالة على البحر في السالمية",
                  "description_en": "Bright apartment with a sea view and a wide balcony.",
                  "description_ar": "شقة مشرقة بإطلالة على البحر وشرفة واسعة.",
                  "property_type": "APARTMENT",
                  "listing_type": "RENT",
                  "country_code": "%s",
                  "governorate_code": "%s",
                  "area_code": "%s",
                  "price": %s,
                  "area_sqm": 140.00,
                  "bedrooms": 2,
                  "bathrooms": 2,
                  "furnished": true,
                  "latitude": 29.3339,
                  "longitude": 48.0758
                }
                """.formatted(title, countryCode, governorateCode, areaCode, price);
    }

    private String landBody(String title, String propertyType, String landKind,
                            String areaQirats, Boolean buildingPermit) {
        return """
                {
                  "title_en": "%s",
                  "title_ar": "أرض للبيع في الجيزة",
                  "description_en": "Test land listing in Giza.",
                  "description_ar": "أرض للبيع في الجيزة.",
                  "property_type": "%s",
                  "listing_type": "SALE",
                  "country_code": "EG",
                  "governorate_code": "GIZA",
                  "area_code": "OCTOBER_6",
                  "price": 3200000.000,
                  "area_sqm": 500.00,
                  "furnished": false,
                  "land_kind": "%s",
                  "area_qirats": %s,
                  "frontage_m": 60.00,
                  "depth_m": 29.17,
                  "street_width_m": 8.00,
                  "building_permit": %s,
                  "boundary_north": "Nile irrigation canal",
                  "boundary_south": "Neighbouring farm plot",
                  "boundary_east": "8 m agricultural road",
                  "boundary_west": "Neighbouring farm plot",
                  "negotiable": true
                }
                """.formatted(title, propertyType, landKind,
                areaQirats == null ? "null" : areaQirats,
                buildingPermit == null ? "null" : buildingPermit);
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    private String uniqueEmail(String prefix) {
        return prefix + "-" + UUID.randomUUID() + "@aqar.test";
    }
}
