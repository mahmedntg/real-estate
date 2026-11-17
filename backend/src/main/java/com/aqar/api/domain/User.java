package com.aqar.api.domain;

import java.time.Instant;
import java.util.UUID;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.CreationTimestamp;

/**
 * JPA entity mapped to the users table, holding the account name, email, phone, password hash,
 * role, verification state, pending phone change and creation timestamp.
 *
 * @author Mohamed Sayed
 */
@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "full_name", nullable = false, length = 120)
    private String fullName;

    @Column(nullable = false, unique = true, length = 160)
    private String email;

    @Column(length = 30)
    private String phone;

    @Column(length = 30)
    private String whatsapp;

    @Column(name = "facebook_url", length = 300)
    private String facebookUrl;

    @Column(name = "password_hash", nullable = false, length = 100)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Role role;

    @Column(name = "email_verified", nullable = false)
    private boolean emailVerified = true;

    @Column(name = "verification_code_hash", length = 100)
    private String verificationCodeHash;

    @Column(name = "verification_expires_at")
    private Instant verificationExpiresAt;

    @Column(name = "pending_phone", length = 30)
    private String pendingPhone;

    @Column(name = "pending_phone_code_hash", length = 100)
    private String pendingPhoneCodeHash;

    @Column(name = "pending_phone_expires_at")
    private Instant pendingPhoneExpiresAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public UUID getId() {
        return id;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(final String fullName) {
        this.fullName = fullName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(final String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(final String phone) {
        this.phone = phone;
    }

    public String getWhatsapp() {
        return whatsapp;
    }

    public void setWhatsapp(final String whatsapp) {
        this.whatsapp = whatsapp;
    }

    public String getFacebookUrl() {
        return facebookUrl;
    }

    public void setFacebookUrl(final String facebookUrl) {
        this.facebookUrl = facebookUrl;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(final String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public Role getRole() {
        return role;
    }

    public void setRole(final Role role) {
        this.role = role;
    }

    public boolean isEmailVerified() {
        return emailVerified;
    }

    public void setEmailVerified(final boolean emailVerified) {
        this.emailVerified = emailVerified;
    }

    public String getVerificationCodeHash() {
        return verificationCodeHash;
    }

    public void setVerificationCodeHash(final String verificationCodeHash) {
        this.verificationCodeHash = verificationCodeHash;
    }

    public Instant getVerificationExpiresAt() {
        return verificationExpiresAt;
    }

    public void setVerificationExpiresAt(final Instant verificationExpiresAt) {
        this.verificationExpiresAt = verificationExpiresAt;
    }

    public String getPendingPhone() {
        return pendingPhone;
    }

    public void setPendingPhone(final String pendingPhone) {
        this.pendingPhone = pendingPhone;
    }

    public String getPendingPhoneCodeHash() {
        return pendingPhoneCodeHash;
    }

    public void setPendingPhoneCodeHash(final String pendingPhoneCodeHash) {
        this.pendingPhoneCodeHash = pendingPhoneCodeHash;
    }

    public Instant getPendingPhoneExpiresAt() {
        return pendingPhoneExpiresAt;
    }

    public void setPendingPhoneExpiresAt(final Instant pendingPhoneExpiresAt) {
        this.pendingPhoneExpiresAt = pendingPhoneExpiresAt;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
