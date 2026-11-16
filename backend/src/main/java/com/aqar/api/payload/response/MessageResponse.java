package com.aqar.api.payload.response;

import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.annotation.JsonNaming;

/**
 * Single message view, flagged with its read state and whether the caller is the sender.
 *
 * @author Mohamed Sayed
 */
@Getter
@Setter
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class MessageResponse {

    private UUID id;

    private UUID senderId;

    private String senderName;

    private String body;

    private boolean read;

    private boolean mine;

    private Instant createdAt;
}
