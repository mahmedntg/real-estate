package com.aqar.api.service;

import java.util.Properties;
import com.aqar.api.config.AqarProperties;
import com.aqar.api.exception.ApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.JavaMailSenderImpl;
import org.springframework.stereotype.Component;

/**
 * Delivers account verification codes by email.
 *
 * <p>When an SMTP host is configured the code is sent over SMTP with STARTTLS and authentication
 * when a username is present; otherwise the code is only written to the server log.
 *
 * @author Mohamed Sayed
 */
@Component
public class VerificationMailer {

    private static final Logger LOGGER = LoggerFactory.getLogger(VerificationMailer.class);

    private final AqarProperties.Mail config;
    private final JavaMailSender sender;

    /**
     * Creates the mailer, building the SMTP sender only when a host is configured.
     *
     * @param properties application configuration holding the mail settings
     */
    public VerificationMailer(final AqarProperties properties) {
        this.config = properties.mail();
        this.sender = smtpConfigured() ? smtpSender() : null;
        if (sender == null) {
            LOGGER.warn("SMTP is not configured; verification codes are written to the server log only");
        }
    }

    /**
     * Sends the bilingual verification code, or logs it when SMTP is not configured.
     *
     * @param email recipient email address
     * @param code plain verification code
     * @throws ApiException when the mail server rejects the message
     */
    public void sendCode(final String email, final String code) {
        if (sender == null) {
            LOGGER.info("Verification code for {} is {} (valid 15 minutes)", email, code);
            return;
        }
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(senderAddress());
        message.setTo(email);
        message.setSubject("Aqar verification code: " + code);
        message.setText(("Your Aqar verification code is %s. It expires in 15 minutes.%n%n"
                + "رمز التحقق الخاص بك في عقار هو %s. ينتهي خلال 15 دقيقة.").formatted(code, code));
        try {
            sender.send(message);
        } catch (MailException e) {
            LOGGER.error("Could not send the verification code to {}", email, e);
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "Email delivery failed",
                    "We could not send the verification email. Try again in a moment.");
        }
    }

    /**
     * Reports whether a non-blank SMTP host is configured.
     *
     * @return true when a host is present
     */
    private boolean smtpConfigured() {
        return config.host() != null && !config.host().isBlank();
    }

    /**
     * Resolves the sender address, falling back to the SMTP username when no from address is set.
     *
     * @return address used as the mail sender
     */
    private String senderAddress() {
        return config.from() == null || config.from().isBlank() ? config.username() : config.from();
    }

    /**
     * Builds the SMTP mail sender with STARTTLS, optional authentication and ten-second timeouts.
     *
     * @return configured mail sender
     */
    private JavaMailSender smtpSender() {
        JavaMailSenderImpl impl = new JavaMailSenderImpl();
        impl.setHost(config.host());
        impl.setPort(config.port());
        impl.setUsername(config.username());
        impl.setPassword(config.password());
        boolean authenticated = config.username() != null && !config.username().isBlank();
        Properties props = impl.getJavaMailProperties();
        props.put("mail.transport.protocol", "smtp");
        props.put("mail.smtp.auth", Boolean.toString(authenticated));
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.starttls.required", "true");
        props.put("mail.smtp.connectiontimeout", "10000");
        props.put("mail.smtp.timeout", "10000");
        props.put("mail.smtp.writetimeout", "10000");
        return impl;
    }
}
