package com.aqar.api.service;

import java.util.List;
import java.util.Map;
import com.aqar.api.config.AqarProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/**
 * Delivers verification codes to a mobile number through the WhatsApp Cloud API.
 *
 * <p>Delivery uses an approved Meta authentication template whose body takes the six digit code as its
 * only parameter. When the token or the phone number id is missing the sender reports itself as not
 * configured and the caller falls back to email.
 *
 * @author Mohamed Sayed
 */
@Component
public class WhatsAppSender {

    private static final Logger LOGGER = LoggerFactory.getLogger(WhatsAppSender.class);
    private static final String MESSAGES_URL = "https://graph.facebook.com/v23.0/%s/messages";

    private final AqarProperties.WhatsApp config;
    private final RestClient client;

    /**
     * Creates the sender from the WhatsApp configuration.
     *
     * @param properties application configuration holding the WhatsApp settings
     */
    public WhatsAppSender(final AqarProperties properties) {
        this.config = properties.whatsapp();
        this.client = RestClient.create();
        if (!configured()) {
            LOGGER.warn("WhatsApp is not configured; verification codes fall back to email or the server log");
        }
    }

    /**
     * Reports whether a token and phone number id are configured.
     *
     * @return true when codes can be submitted to the Cloud API
     */
    public boolean configured() {
        return notBlank(config.token()) && notBlank(config.phoneNumberId());
    }

    /**
     * Sends the verification template carrying the code to the given number.
     *
     * @param phone recipient number in international format, separators allowed
     * @param code plain six digit verification code
     * @throws IllegalStateException when WhatsApp is not configured
     * @throws org.springframework.web.client.RestClientException when the Cloud API rejects the request
     */
    public void sendCode(final String phone, final String code) {
        if (!configured()) {
            throw new IllegalStateException("WhatsApp is not configured");
        }
        Map<String, Object> template = Map.of(
                "name", config.template(),
                "language", Map.of("code", config.templateLanguage()),
                "components", List.of(Map.of(
                        "type", "body",
                        "parameters", List.of(Map.of("type", "text", "text", code)))));
        Map<String, Object> body = Map.of(
                "messaging_product", "whatsapp",
                "to", digits(phone),
                "type", "template",
                "template", template);
        client.post()
                .uri(MESSAGES_URL.formatted(config.phoneNumberId()))
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + config.token())
                .contentType(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .toBodilessEntity();
    }

    /**
     * Strips separators so the number matches the Cloud API format.
     *
     * @param phone number in international format
     * @return digits only
     */
    private static String digits(final String phone) {
        return phone.replaceAll("[^0-9]", "");
    }

    /**
     * Checks a configuration value for a non-blank string.
     *
     * @param value configuration value
     * @return true when the value holds visible characters
     */
    private static boolean notBlank(final String value) {
        return value != null && !value.isBlank();
    }
}
