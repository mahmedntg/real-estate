package com.aqar.api.payload.response;

import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.annotation.JsonNaming;

/**
 * Inbox row describing a conversation: the property it concerns, the counterpart, the last message
 * and the caller's unread count.
 *
 * @author Mohamed Sayed
 */
@Getter
@Setter
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class ConversationResponse {

    private UUID id;

    private UUID propertyId;

    private String propertyTitleEn;

    private String propertyTitleAr;

    private String coverImage;

    private UUID otherPartyId;

    private String otherPartyName;

    private boolean ownerView;

    private String lastMessage;

    private Instant lastMessageAt;

    private long unreadCount;
}
