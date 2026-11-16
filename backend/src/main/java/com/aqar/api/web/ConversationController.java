package com.aqar.api.web;

import java.util.UUID;
import jakarta.validation.Valid;
import com.aqar.api.payload.response.ConversationResponse;
import com.aqar.api.payload.response.MessageResponse;
import com.aqar.api.payload.request.SendMessageRequest;
import com.aqar.api.payload.request.StartConversationRequest;
import com.aqar.api.payload.response.PageResponse;
import com.aqar.api.security.CurrentUser;
import com.aqar.api.service.ConversationService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Exposes the messaging endpoints for conversations between renters and listing owners.
 *
 * @author Mohamed Sayed
 */
@RestController
@RequestMapping("/api/v1")
public class ConversationController {

    private final ConversationService conversationService;
    private final CurrentUser currentUser;

    /**
     * Creates the controller with its messaging collaborators.
     *
     * @param conversationService service managing conversations and messages
     * @param currentUser resolver for the authenticated caller
     */
    public ConversationController(final ConversationService conversationService, final CurrentUser currentUser) {
        this.conversationService = conversationService;
        this.currentUser = currentUser;
    }

    /**
     * Starts a conversation on a listing owned by another user, or reuses the existing one.
     *
     * @param propertyId identifier of the listing being discussed
     * @param request initial message body
     * @return the created or existing conversation
     */
    @PostMapping("/properties/{propertyId}/conversations")
    @ResponseStatus(HttpStatus.CREATED)
    public ConversationResponse start(@PathVariable final UUID propertyId,
                                  @Valid @RequestBody final StartConversationRequest request) {
        return conversationService.start(propertyId, currentUser.requireId(), request.getMessage());
    }

    /**
     * Lists the conversations the caller takes part in, most recently active first.
     *
     * @param page zero-based page index
     * @param size page size
     * @return paginated conversation summaries
     */
    @GetMapping("/conversations")
    public PageResponse<ConversationResponse> list(@RequestParam(defaultValue = "0") final int page,
                                               @RequestParam(defaultValue = "20") final int size) {
        return conversationService.list(currentUser.requireId(), page, size);
    }

    /**
     * Returns a single conversation the caller participates in.
     *
     * @param id conversation identifier
     * @return conversation summary with the caller's unread count
     */
    @GetMapping("/conversations/{id}")
    public ConversationResponse get(@PathVariable final UUID id) {
        return conversationService.get(id, currentUser.requireId());
    }

    /**
     * Lists the messages of a conversation the caller participates in, newest first.
     *
     * @param id conversation identifier
     * @param page zero-based page index
     * @param size page size
     * @return paginated messages
     */
    @GetMapping("/conversations/{id}/messages")
    public PageResponse<MessageResponse> messages(@PathVariable final UUID id,
                                              @RequestParam(defaultValue = "0") final int page,
                                              @RequestParam(defaultValue = "30") final int size) {
        return conversationService.messages(id, currentUser.requireId(), page, size);
    }

    /**
     * Posts a message from the caller into a conversation they participate in.
     *
     * @param id conversation identifier
     * @param request message body to send
     * @return the stored message
     */
    @PostMapping("/conversations/{id}/messages")
    @ResponseStatus(HttpStatus.CREATED)
    public MessageResponse send(@PathVariable final UUID id, @Valid @RequestBody final SendMessageRequest request) {
        return conversationService.send(id, currentUser.requireId(), request.getBody());
    }

    /**
     * Marks every message of a conversation as read for the caller.
     *
     * @param id conversation identifier
     */
    @PostMapping("/conversations/{id}/read")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void markRead(@PathVariable final UUID id) {
        conversationService.markRead(id, currentUser.requireId());
    }
}
