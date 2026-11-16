package com.aqar.api.service;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import com.aqar.api.domain.Conversation;
import com.aqar.api.domain.Message;
import com.aqar.api.domain.Property;
import com.aqar.api.domain.User;
import com.aqar.api.payload.response.ConversationResponse;
import com.aqar.api.payload.response.MessageResponse;
import com.aqar.api.payload.response.PageResponse;
import com.aqar.api.exception.ApiException;
import com.aqar.api.repository.ConversationRepository;
import com.aqar.api.repository.MessageRepository;
import com.aqar.api.repository.PropertyRepository;
import com.aqar.api.repository.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Manages renter-to-owner conversations about listings and the messages inside them.
 *
 * <p>Every read and write first checks that the caller is either the renter or the owner of the
 * conversation, and conversations the caller cannot see are reported as not found.
 *
 * @author Mohamed Sayed
 */
@Service
public class ConversationService {

    private static final int MAX_PAGE_SIZE = 50;
    private static final int MAX_MESSAGE_PAGE_SIZE = 100;

    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;
    private final PropertyRepository propertyRepository;
    private final UserRepository userRepository;

    /**
     * Creates the service with its repositories.
     *
     * @param conversationRepository repository of conversations
     * @param messageRepository repository of conversation messages
     * @param propertyRepository repository used to resolve the discussed listing
     * @param userRepository repository used to resolve the participants
     */
    public ConversationService(final ConversationRepository conversationRepository,
                               final MessageRepository messageRepository,
                               final PropertyRepository propertyRepository,
                               final UserRepository userRepository) {
        this.conversationRepository = conversationRepository;
        this.messageRepository = messageRepository;
        this.propertyRepository = propertyRepository;
        this.userRepository = userRepository;
    }

    /**
     * Opens the renter conversation for a listing, reusing it when it already exists, and posts
     * the first message.
     *
     * @param propertyId listing the conversation is about
     * @param actorId user starting the conversation
     * @param message text of the opening message
     * @return view of the conversation as the renter sees it
     */
    @Transactional
    public ConversationResponse start(final UUID propertyId, final UUID actorId, final String message) {
        Property property = propertyRepository.findById(propertyId)
                .orElseThrow(() -> ApiException.notFound("Property not found"));
        if (property.getOwner().getId().equals(actorId)) {
            throw ApiException.badRequest("Invalid recipient",
                    "You cannot start a conversation on your own listing");
        }
        User actor = userRepository.findById(actorId)
                .orElseThrow(() -> ApiException.notFound("User not found"));

        Conversation conversation = conversationRepository.findByPropertyIdAndRenterId(propertyId, actorId)
                .orElseGet(() -> {
                    Conversation created = new Conversation();
                    created.setProperty(property);
                    created.setRenter(actor);
                    created.setOwner(property.getOwner());
                    created.setLastMessageAt(Instant.now());
                    return conversationRepository.save(created);
                });

        sendMessage(conversation, actor, message);
        return toView(conversation, actorId, 0L);
    }

    /**
     * Lists the conversations the user takes part in, newest activity first, with unread counts.
     *
     * @param userId identifier of the renter or owner
     * @param page zero-based page index
     * @param size requested page size, clamped to the conversation maximum
     * @return page of conversation views for the caller
     */
    @Transactional(readOnly = true)
    public PageResponse<ConversationResponse> list(final UUID userId, final int page, final int size) {
        Pageable pageable = PageRequest.of(Math.max(page, 0), clamp(size, MAX_PAGE_SIZE),
                Sort.by(Sort.Direction.DESC, "lastMessageAt"));
        Page<Conversation> result = conversationRepository.findByRenterIdOrOwnerId(userId, userId, pageable);

        List<UUID> ids = result.getContent().stream().map(Conversation::getId).toList();
        Map<UUID, Long> unread = unreadCounts(ids, userId);
        List<ConversationResponse> items = result.getContent().stream()
                .map(conversation -> toView(conversation, userId, unread.getOrDefault(conversation.getId(), 0L)))
                .toList();
        return PageResponse.of(result, items);
    }

    /**
     * Loads one conversation for a participant together with its unread count.
     *
     * @param conversationId identifier of the conversation
     * @param userId identifier of the requesting participant
     * @return view of the conversation as the caller sees it
     */
    @Transactional(readOnly = true)
    public ConversationResponse get(final UUID conversationId, final UUID userId) {
        Conversation conversation = requireParticipant(conversationId, userId);
        long unread = unreadCounts(List.of(conversationId), userId).getOrDefault(conversationId, 0L);
        return toView(conversation, userId, unread);
    }

    /**
     * Lists the newest messages of a conversation for one of its participants.
     *
     * @param conversationId identifier of the conversation
     * @param userId identifier of the requesting participant
     * @param page zero-based page index
     * @param size requested page size, clamped to the message maximum
     * @return page of message views marked with whether the caller sent them
     */
    @Transactional(readOnly = true)
    public PageResponse<MessageResponse> messages(final UUID conversationId, final UUID userId, final int page, final int size) {
        requireParticipant(conversationId, userId);
        Pageable pageable = PageRequest.of(Math.max(page, 0), clamp(size, MAX_MESSAGE_PAGE_SIZE),
                Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Message> result = messageRepository.findByConversationId(conversationId, pageable);
        List<MessageResponse> items = result.getContent().stream()
                .map(message -> toMessageView(message, userId))
                .toList();
        return PageResponse.of(result, items);
    }

    /**
     * Posts a message from a participant and refreshes the conversation activity time.
     *
     * @param conversationId identifier of the conversation
     * @param userId identifier of the sending participant
     * @param body text of the message
     * @return view of the stored message
     */
    @Transactional
    public MessageResponse send(final UUID conversationId, final UUID userId, final String body) {
        Conversation conversation = requireParticipant(conversationId, userId);
        User sender = userRepository.findById(userId)
                .orElseThrow(() -> ApiException.notFound("User not found"));
        Message message = sendMessage(conversation, sender, body);
        return toMessageView(message, userId);
    }

    /**
     * Marks every message the other participant sent as read for the caller.
     *
     * @param conversationId identifier of the conversation
     * @param userId identifier of the reading participant
     */
    @Transactional
    public void markRead(final UUID conversationId, final UUID userId) {
        requireParticipant(conversationId, userId);
        messageRepository.markRead(conversationId, userId);
    }

    /**
     * Stores a trimmed, unread message and stamps the conversation with the current time.
     *
     * @param conversation conversation that receives the message
     * @param sender participant sending the message
     * @param body text of the message, trimmed before storage
     * @return the stored message
     */
    private Message sendMessage(final Conversation conversation, final User sender, final String body) {
        Message message = new Message();
        message.setConversation(conversation);
        message.setSender(sender);
        message.setBody(body.trim());
        message.setReadFlag(false);
        message.setCreatedAt(Instant.now());
        messageRepository.save(message);

        conversation.setLastMessageAt(Instant.now());
        conversationRepository.save(conversation);
        return message;
    }

    /**
     * Loads a conversation and rejects callers who are neither its renter nor its owner.
     *
     * @param conversationId identifier of the conversation
     * @param userId identifier of the requesting user
     * @return the conversation when the caller is a participant
     */
    private Conversation requireParticipant(final UUID conversationId, final UUID userId) {
        Conversation conversation = conversationRepository.findById(conversationId)
                .orElseThrow(() -> ApiException.notFound("Conversation not found"));
        boolean participant = conversation.getRenter().getId().equals(userId)
                || conversation.getOwner().getId().equals(userId);
        if (!participant) {
            throw ApiException.notFound("Conversation not found");
        }
        return conversation;
    }

    /**
     * Counts the unread messages of several conversations for one participant.
     *
     * @param conversationIds conversations to count for
     * @param userId identifier of the reading participant
     * @return unread counts keyed by conversation identifier, empty when no ids are given
     */
    private Map<UUID, Long> unreadCounts(final List<UUID> conversationIds, final UUID userId) {
        if (conversationIds.isEmpty()) {
            return Map.of();
        }
        Map<UUID, Long> counts = new HashMap<>();
        for (Object[] row : messageRepository.countUnread(conversationIds, userId)) {
            counts.put((UUID) row[0], ((Number) row[1]).longValue());
        }
        return counts;
    }

    /**
     * Builds the conversation view from the caller's side, exposing the other party and cover image.
     *
     * @param conversation conversation to render
     * @param viewerId identifier of the user the view is built for
     * @param unread number of unread messages for that user
     * @return conversation view tailored to the viewer
     */
    private ConversationResponse toView(final Conversation conversation, final UUID viewerId, final long unread) {
        Message last = messageRepository.findTopByConversationIdOrderByCreatedAtDesc(conversation.getId())
                .orElse(null);
        boolean ownerView = conversation.getOwner().getId().equals(viewerId);
        User otherParty = ownerView ? conversation.getRenter() : conversation.getOwner();
        Property property = conversation.getProperty();
        String cover = property.getImages().isEmpty() ? null : property.getImages().get(0).getUrl();

        ConversationResponse response = new ConversationResponse();
        response.setId(conversation.getId());
        response.setPropertyId(property.getId());
        response.setPropertyTitleEn(property.getTitleEn());
        response.setPropertyTitleAr(property.getTitleAr());
        response.setCoverImage(cover);
        response.setOtherPartyId(otherParty.getId());
        response.setOtherPartyName(otherParty.getFullName());
        response.setOwnerView(ownerView);
        response.setLastMessage(last == null ? null : last.getBody());
        response.setLastMessageAt(conversation.getLastMessageAt());
        response.setUnreadCount(unread);
        return response;
    }

    /**
     * Builds a message view flagged as the caller's own when the sender matches.
     *
     * @param message message to render
     * @param viewerId identifier of the user the view is built for
     * @return message view tailored to the viewer
     */
    private MessageResponse toMessageView(final Message message, final UUID viewerId) {
        boolean mine = message.getSender().getId().equals(viewerId);
        MessageResponse response = new MessageResponse();
        response.setId(message.getId());
        response.setSenderId(message.getSender().getId());
        response.setSenderName(message.getSender().getFullName());
        response.setBody(message.getBody());
        response.setRead(message.isReadFlag());
        response.setMine(mine);
        response.setCreatedAt(message.getCreatedAt());
        return response;
    }

    /**
     * Clamps a requested page size, falling back to the default of twenty when it is not positive.
     *
     * @param size requested page size
     * @param max upper bound allowed for the page size
     * @return page size within the allowed range
     */
    private int clamp(final int size, final int max) {
        if (size < 1) {
            return Math.min(20, max);
        }
        return Math.min(size, max);
    }
}
