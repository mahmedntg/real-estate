package com.aqar.api.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Delivers verification codes over WhatsApp first and falls back to email.
 *
 * <p>When WhatsApp is configured the code is submitted to the Cloud API; a failed submission or a
 * missing WhatsApp configuration delegates to the SMTP mailer, which logs the code when SMTP is not
 * configured either.
 *
 * @author Mohamed Sayed
 */
@Component
public class VerificationSender {

    private static final Logger LOGGER = LoggerFactory.getLogger(VerificationSender.class);

    private final WhatsAppSender whatsapp;
    private final VerificationMailer mailer;

    /**
     * Creates the sender with its delivery channels.
     *
     * @param whatsapp WhatsApp Cloud API sender
     * @param mailer SMTP mailer used as the fallback channel
     */
    public VerificationSender(final WhatsAppSender whatsapp, final VerificationMailer mailer) {
        this.whatsapp = whatsapp;
        this.mailer = mailer;
    }

    /**
     * Sends the verification code to the mobile number, falling back to the account email.
     *
     * @param phone mobile number of the account or of the number being verified
     * @param email account email used by the fallback channel
     * @param code plain six digit verification code
     */
    public void sendCode(final String phone, final String email, final String code) {
        if (whatsapp.configured()) {
            try {
                whatsapp.sendCode(phone, code);
                return;
            } catch (RuntimeException e) {
                LOGGER.warn("WhatsApp delivery failed; falling back to email for {}", email, e);
            }
        }
        mailer.sendCode(email, code);
    }
}
